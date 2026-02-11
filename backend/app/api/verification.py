"""
Identity Verification API Endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import Optional

from ..database import get_db
from ..models.verification import IdentityVerification, VerificationStatus
from ..schemas.verification import (
    VerificationResponse,
    VerificationDetailResponse,
    VerificationApprovalRequest,
    VerificationStatsResponse
)
from ..services.verification_service import verification_service

router = APIRouter(prefix="/api/verification", tags=["verification"])


async def get_current_user():
    """Mock user authentication"""
    return {"id": 1, "email": "test@example.com", "role": "user"}


async def get_current_admin():
    """Mock admin authentication"""
    return {"id": 100, "email": "admin@smartexplorers.com", "role": "admin"}


@router.post("/submit", response_model=VerificationResponse, status_code=status.HTTP_201_CREATED)
async def submit_verification(
    verification_method: str = Form(...),
    document_number: str = Form(...),
    full_name: str = Form(...),
    date_of_birth: str = Form(...),
    nationality: Optional[str] = Form(None),
    document_image: UploadFile = File(...),
    selfie_image: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Submit identity verification with document and selfie"""
    try:
        doc_image_bytes = await document_image.read()
        selfie_bytes = await selfie_image.read()
        
        if len(doc_image_bytes) > 10 * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="Document image too large (max 10MB)"
            )
        
        if len(selfie_bytes) > 10 * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="Selfie too large (max 10MB)"
            )
        
        verification_data = {
            "verification_method": verification_method,
            "document_number": document_number,
            "full_name": full_name,
            "date_of_birth": date_of_birth,
            "nationality": nationality
        }
        
        verification, face_result = await verification_service.submit_verification(
            db=db,
            user_id=current_user["id"],
            verification_data=verification_data,
            document_image=doc_image_bytes,
            selfie_image=selfie_bytes
        )
        
        return verification
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Verification failed: {str(e)}"
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
            detail="No verification found"
        )
    
    return verification


@router.get("/admin/{verification_id}", response_model=VerificationDetailResponse)
async def get_verification_detail(
    verification_id: int,
    db: Session = Depends(get_db),
    current_admin: dict = Depends(get_current_admin)
):
    """Get decrypted verification details (admin only)"""
    try:
        decrypted_data = verification_service.get_verification_decrypted(
            db=db,
            verification_id=verification_id,
            requester_id=current_admin["id"],
            requester_role=current_admin["role"]
        )
        
        if not decrypted_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Verification not found"
            )
        
        return decrypted_data
        
    except PermissionError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )


@router.post("/admin/{verification_id}/approve", response_model=VerificationResponse)
async def approve_verification(
    verification_id: int,
    approval: VerificationApprovalRequest,
    db: Session = Depends(get_db),
    current_admin: dict = Depends(get_current_admin)
):
    """Approve or reject verification (admin only)"""
    try:
        if approval.approved:
            verification = verification_service.approve_verification(
                db=db,
                verification_id=verification_id,
                admin_id=current_admin["id"],
                notes=approval.notes
            )
        else:
            if not approval.notes:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Rejection reason required"
                )
            verification = verification_service.reject_verification(
                db=db,
                verification_id=verification_id,
                admin_id=current_admin["id"],
                reason=approval.notes
            )
        
        return verification
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/admin/pending", response_model=list[VerificationResponse])
async def list_pending_verifications(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_admin: dict = Depends(get_current_admin)
):
    """List pending verifications (admin only)"""
    verifications = db.query(IdentityVerification).filter(
        IdentityVerification.status.in_([
            VerificationStatus.PENDING,
            VerificationStatus.FLAGGED
        ])
    ).offset(skip).limit(limit).all()
    
    return verifications


@router.get("/admin/stats", response_model=VerificationStatsResponse)
async def get_verification_stats(
    db: Session = Depends(get_db),
    current_admin: dict = Depends(get_current_admin)
):
    """Get verification statistics (admin only)"""
    stats = verification_service.get_verification_stats(db)
    return stats