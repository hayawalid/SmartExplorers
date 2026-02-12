from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from fastapi import Request as FastAPIRequest
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import json

from database import get_db
from ..models.verification import (
    IdentityVerification, 
    VerificationAuditLog,
    VerificationMethod,
    VerificationStatus
)
from ..schemas.verification import (
    VerificationSubmitRequest,
    VerificationResponse,
    VerificationDetailResponse,
    VerificationApprovalRequest,
    VerificationStatsResponse,
    ImageValidationResponse,
    FaceVerificationResult,
    OCRResult
)
from ..services.encryption import encryption_service
from ..services.ocr import ocr_service
from ..services.face_verification import face_verification_service

router = APIRouter(prefix="/api/verification", tags=["verification"])


# Mock auth - replace with real authentication
async def get_current_user():
    """Mock user authentication"""
    return {"id": 1, "email": "test@example.com", "role": "user"}


async def get_current_admin():
    """Mock admin authentication"""
    return {"id": 100, "email": "admin@example.com", "role": "admin"}


def log_audit(
    db: Session,
    verification_id: int,
    user_id: int,
    action: str,
    actor_id: Optional[int] = None,
    actor_role: Optional[str] = None,
    details: Optional[dict] = None,
    request: Optional[FastAPIRequest] = None
):
    """Create audit log entry"""
    log = VerificationAuditLog(
        verification_id=verification_id,
        user_id=user_id,
        action=action,
        actor_id=actor_id,
        actor_role=actor_role,
        details=json.dumps(details) if details else None,
        ip_address=request.client.host if request else None,
        user_agent=request.headers.get("user-agent") if request else None
    )
    db.add(log)
    db.commit()


@router.post("/submit", response_model=VerificationResponse, status_code=status.HTTP_201_CREATED)
async def submit_verification(
    verification_method: str = Form(...),
    document_image: UploadFile = File(...),
    selfie_image: UploadFile = File(...),
    document_number: Optional[str] = Form(None),
    full_name: Optional[str] = Form(None),
    date_of_birth: Optional[str] = Form(None),
    nationality: Optional[str] = Form("Egyptian"),
    request: FastAPIRequest = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Submit identity verification with ID document and selfie
    
    - **verification_method**: national_id, passport, or drivers_license
    - **document_image**: Photo of ID document
    - **selfie_image**: Selfie photo for face matching
    - **document_number**: Optional - will be extracted via OCR if not provided
    - **full_name**: Optional - will be extracted via OCR if not provided
    - **date_of_birth**: Optional (YYYY-MM-DD) - will be extracted via OCR if not provided
    """
    
    # Check if user already has a verification
    existing = db.query(IdentityVerification).filter(
        IdentityVerification.user_id == current_user["id"]
    ).first()
    
    if existing and existing.status not in [VerificationStatus.REJECTED, VerificationStatus.EXPIRED]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"You already have a {existing.status.value} verification. Cannot submit a new one."
        )
    
    try:
        # Read image bytes
        document_image_bytes = await document_image.read()
        selfie_image_bytes = await selfie_image.read()
        
        # Step 1: Validate image quality
        doc_validation = face_verification_service.validate_image_quality(document_image_bytes)
        if not doc_validation["valid"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Document image invalid: {doc_validation['reason']}"
            )
        
        selfie_validation = face_verification_service.validate_image_quality(selfie_image_bytes)
        if not selfie_validation["valid"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Selfie image invalid: {selfie_validation['reason']}"
            )
        
        # Step 2: Detect faces
        doc_face = face_verification_service.detect_face(document_image_bytes)
        if not doc_face["face_detected"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No face detected in document image. Please ensure the photo is clear."
            )
        
        selfie_face = face_verification_service.detect_face(selfie_image_bytes)
        if not selfie_face["face_detected"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No face detected in selfie. Please retake the photo."
            )
        
        # Step 3: Verify faces match
        face_match = face_verification_service.verify_faces(
            document_image_bytes,
            selfie_image_bytes
        )
        
        # Step 4: Extract data via OCR (if not provided)
        ocr_data = None
        if not all([document_number, full_name, date_of_birth]):
            ocr_data = ocr_service.extract_id_data(
                document_image_bytes,
                verification_method
            )
        
        # Use provided data or OCR-extracted data
        final_doc_number = document_number or (ocr_data.get("document_number") if ocr_data else None)
        final_name = full_name or (ocr_data.get("full_name") if ocr_data else None)
        final_dob = date_of_birth or (ocr_data.get("date_of_birth") if ocr_data else None)
        final_gender = ocr_data.get("gender") if ocr_data else None
        
        if not final_doc_number:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Could not extract document number. Please provide it manually."
            )
        
        if not final_name:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Could not extract name. Please provide it manually."
            )
        
        # Step 5: Encrypt sensitive data
        encrypted_data = encryption_service.encrypt_dict({
            "document_number": final_doc_number,
            "full_name": final_name,
            "date_of_birth": final_dob or "",
            "nationality": nationality,
            "gender": final_gender or "",
            "document_image_path": f"verifications/{current_user['id']}/document_{datetime.utcnow().timestamp()}.jpg",
            "selfie_image_path": f"verifications/{current_user['id']}/selfie_{datetime.utcnow().timestamp()}.jpg"
        })
        
        # Step 6: Determine fraud status
        is_fraudulent = False
        fraud_reason = None
        fraud_confidence = None
        
        if not face_match["passes_threshold"]:
            is_fraudulent = True
            fraud_reason = f"Face match confidence ({face_match['confidence']:.2%}) below threshold"
            fraud_confidence = 1.0 - face_match["confidence"]
        
        # Determine initial status
        if is_fraudulent:
            initial_status = VerificationStatus.FLAGGED
        else:
            initial_status = VerificationStatus.PENDING
        
        # Step 7: Create verification record
        verification = IdentityVerification(
            user_id=current_user["id"],
            verification_method=VerificationMethod(verification_method),
            status=initial_status,
            encrypted_document_number=encrypted_data["encrypted_document_number"],
            encrypted_full_name=encrypted_data["encrypted_full_name"],
            encrypted_date_of_birth=encrypted_data["encrypted_date_of_birth"],
            encrypted_nationality=encrypted_data["encrypted_nationality"],
            encrypted_gender=encrypted_data["encrypted_gender"],
            encrypted_document_image_path=encrypted_data["encrypted_document_image_path"],
            encrypted_selfie_image_path=encrypted_data["encrypted_selfie_image_path"],
            ocr_confidence=ocr_data.get("confidence") if ocr_data else None,
            face_match_confidence=face_match["confidence"],
            face_match_passed=face_match["passes_threshold"],
            face_match_distance=face_match.get("distance"),
            face_match_model=face_match.get("model"),
            is_fraudulent=is_fraudulent,
            fraud_reason=fraud_reason,
            fraud_confidence=fraud_confidence,
            submission_ip=request.client.host if request else None,
            submission_user_agent=request.headers.get("user-agent") if request else None
        )
        
        db.add(verification)
        db.commit()
        db.refresh(verification)
        
        # Create audit log
        log_audit(
            db=db,
            verification_id=verification.id,
            user_id=current_user["id"],
            action="submitted",
            actor_role="user",
            details={
                "verification_method": verification_method,
                "face_match_confidence": face_match["confidence"],
                "is_fraudulent": is_fraudulent
            },
            request=request
        )
        
        # Prepare response
        return VerificationResponse(
            id=verification.id,
            user_id=verification.user_id,
            verification_method=verification.verification_method,
            status=verification.status,
            face_match_passed=verification.face_match_passed,
            face_match_confidence=verification.face_match_confidence,
            ocr_confidence=verification.ocr_confidence,
            is_fraudulent=verification.is_fraudulent,
            fraud_reason=verification.fraud_reason,
            submitted_at=verification.submitted_at,
            verified_at=verification.verified_at,
            expires_at=verification.expires_at,
            message="Verification submitted successfully. Pending admin review." if not is_fraudulent
                    else "Verification flagged for manual review due to low face match confidence."
        )
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process verification: {str(e)}"
        )


@router.get("/status", response_model=VerificationResponse)
async def get_verification_status(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Get current user's verification status"""
    
    verification = db.query(IdentityVerification).filter(
        IdentityVerification.user_id == current_user["id"]
    ).first()
    
    if not verification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No verification found. Please submit your identity verification."
        )
    
    # Check if expired
    if verification.is_expired() and verification.status == VerificationStatus.APPROVED:
        verification.status = VerificationStatus.EXPIRED
        db.commit()
    
    return VerificationResponse(
        id=verification.id,
        user_id=verification.user_id,
        verification_method=verification.verification_method,
        status=verification.status,
        face_match_passed=verification.face_match_passed,
        face_match_confidence=verification.face_match_confidence,
        ocr_confidence=verification.ocr_confidence,
        is_fraudulent=verification.is_fraudulent,
        fraud_reason=verification.fraud_reason,
        submitted_at=verification.submitted_at,
        verified_at=verification.verified_at,
        expires_at=verification.expires_at,
        message=f"Verification status: {verification.status.value}"
    )


@router.get("/admin/pending", response_model=List[VerificationResponse])
async def list_pending_verifications(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_admin: dict = Depends(get_current_admin)
):
    """List all pending verifications (admin only)"""
    
    verifications = db.query(IdentityVerification).filter(
        IdentityVerification.status.in_([VerificationStatus.PENDING, VerificationStatus.FLAGGED])
    ).offset(skip).limit(limit).all()
    
    return [
        VerificationResponse(
            id=v.id,
            user_id=v.user_id,
            verification_method=v.verification_method,
            status=v.status,
            face_match_passed=v.face_match_passed,
            face_match_confidence=v.face_match_confidence,
            ocr_confidence=v.ocr_confidence,
            is_fraudulent=v.is_fraudulent,
            fraud_reason=v.fraud_reason,
            submitted_at=v.submitted_at,
            verified_at=v.verified_at,
            expires_at=v.expires_at
        )
        for v in verifications
    ]


@router.get("/admin/{verification_id}", response_model=VerificationDetailResponse)
async def get_verification_details(
    verification_id: int,
    request: FastAPIRequest,
    db: Session = Depends(get_db),
    current_admin: dict = Depends(get_current_admin)
):
    """Get decrypted verification details (admin only)"""
    
    verification = db.query(IdentityVerification).filter(
        IdentityVerification.id == verification_id
    ).first()
    
    if not verification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Verification not found"
        )
    
    # Decrypt sensitive data
    decrypted = encryption_service.decrypt_dict(
        {
            "encrypted_document_number": verification.encrypted_document_number,
            "encrypted_full_name": verification.encrypted_full_name,
            "encrypted_date_of_birth": verification.encrypted_date_of_birth,
            "encrypted_nationality": verification.encrypted_nationality,
            "encrypted_gender": verification.encrypted_gender
        },
        ["document_number", "full_name", "date_of_birth", "nationality", "gender"]
    )
    
    # Log access
    log_audit(
        db=db,
        verification_id=verification.id,
        user_id=verification.user_id,
        action="accessed",
        actor_id=current_admin["id"],
        actor_role="admin",
        details={"fields_accessed": ["document_number", "full_name", "date_of_birth"]},
        request=request
    )
    
    return VerificationDetailResponse(
        id=verification.id,
        user_id=verification.user_id,
        verification_method=verification.verification_method,
        status=verification.status,
        face_match_passed=verification.face_match_passed,
        face_match_confidence=verification.face_match_confidence,
        ocr_confidence=verification.ocr_confidence,
        is_fraudulent=verification.is_fraudulent,
        fraud_reason=verification.fraud_reason,
        submitted_at=verification.submitted_at,
        verified_at=verification.verified_at,
        expires_at=verification.expires_at,
        document_number=decrypted.get("document_number"),
        full_name=decrypted.get("full_name"),
        date_of_birth=decrypted.get("date_of_birth"),
        nationality=decrypted.get("nationality"),
        gender=decrypted.get("gender"),
        admin_notes=verification.admin_notes,
        rejection_reason=verification.rejection_reason,
        verified_by_admin_id=verification.verified_by_admin_id
    )


@router.post("/admin/{verification_id}/approve", response_model=VerificationResponse)
async def approve_verification(
    verification_id: int,
    approval: VerificationApprovalRequest,
    request: FastAPIRequest,
    db: Session = Depends(get_db),
    current_admin: dict = Depends(get_current_admin)
):
    """Approve or reject verification (admin only)"""
    
    verification = db.query(IdentityVerification).filter(
        IdentityVerification.id == verification_id
    ).first()
    
    if not verification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Verification not found"
        )
    
    if verification.status not in [VerificationStatus.PENDING, VerificationStatus.FLAGGED]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot modify verification with status {verification.status.value}"
        )
    
    # Update status
    if approval.approved:
        verification.status = VerificationStatus.APPROVED
        verification.verified_at = datetime.utcnow()
    else:
        verification.status = VerificationStatus.REJECTED
        verification.rejection_reason = approval.rejection_reason
    
    verification.admin_notes = approval.notes
    verification.verified_by_admin_id = current_admin["id"]
    
    db.commit()
    db.refresh(verification)
    
    # Log action
    log_audit(
        db=db,
        verification_id=verification.id,
        user_id=verification.user_id,
        action="approved" if approval.approved else "rejected",
        actor_id=current_admin["id"],
        actor_role="admin",
        details={"notes": approval.notes, "rejection_reason": approval.rejection_reason},
        request=request
    )
    
    return VerificationResponse(
        id=verification.id,
        user_id=verification.user_id,
        verification_method=verification.verification_method,
        status=verification.status,
        face_match_passed=verification.face_match_passed,
        face_match_confidence=verification.face_match_confidence,
        ocr_confidence=verification.ocr_confidence,
        is_fraudulent=verification.is_fraudulent,
        fraud_reason=verification.fraud_reason,
        submitted_at=verification.submitted_at,
        verified_at=verification.verified_at,
        expires_at=verification.expires_at,
        message=f"Verification {'approved' if approval.approved else 'rejected'} successfully"
    )


@router.get("/admin/stats", response_model=VerificationStatsResponse)
async def get_verification_stats(
    db: Session = Depends(get_db),
    current_admin: dict = Depends(get_current_admin)
):
    """Get verification statistics (admin only)"""
    
    total = db.query(IdentityVerification).count()
    pending = db.query(IdentityVerification).filter(
        IdentityVerification.status == VerificationStatus.PENDING
    ).count()
    approved = db.query(IdentityVerification).filter(
        IdentityVerification.status == VerificationStatus.APPROVED
    ).count()
    rejected = db.query(IdentityVerification).filter(
        IdentityVerification.status == VerificationStatus.REJECTED
    ).count()
    flagged = db.query(IdentityVerification).filter(
        IdentityVerification.status == VerificationStatus.FLAGGED
    ).count()
    expired = db.query(IdentityVerification).filter(
        IdentityVerification.status == VerificationStatus.EXPIRED
    ).count()
    
    fraudulent = db.query(IdentityVerification).filter(
        IdentityVerification.is_fraudulent == True
    ).count()
    
    fraud_rate = (fraudulent / total * 100) if total > 0 else 0
    
    return VerificationStatsResponse(
        total_submissions=total,
        pending_count=pending,
        approved_count=approved,
        rejected_count=rejected,
        flagged_count=flagged,
        expired_count=expired,
        fraud_detection_rate=round(fraud_rate, 2)
    )


@router.delete("/{verification_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_verification(
    verification_id: int,
    request: FastAPIRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Delete verification (GDPR right to deletion - only for rejected verifications)"""
    
    verification = db.query(IdentityVerification).filter(
        IdentityVerification.id == verification_id,
        IdentityVerification.user_id == current_user["id"]
    ).first()
    
    if not verification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Verification not found"
        )
    
    if verification.status != VerificationStatus.REJECTED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only rejected verifications can be deleted"
        )
    
    # Log deletion before deleting
    log_audit(
        db=db,
        verification_id=verification.id,
        user_id=verification.user_id,
        action="deleted",
        actor_id=current_user["id"],
        actor_role="user",
        details={"gdpr_deletion": True},
        request=request
    )
    
    # TODO: Delete associated images from S3
    
    db.delete(verification)
    db.commit()
    
    return None