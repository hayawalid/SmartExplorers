from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from ..database import get_db
from ..models.itinerary import Itinerary, ItineraryActivity, ItineraryStatus
from ..schemas.itinerary import (
    ItineraryGenerationRequest,
    ItineraryResponse,
    ItineraryApprovalRequest,
    SafetyValidationResponse,
    ActivityResponse,
    SafetyLevel
)
from ..services.itinerary_generator import ItineraryGenerator

router = APIRouter(prefix="/api/itineraries", tags=["itineraries"])


# Dependency to get current user (simplified for testing)
async def get_current_user():
    """Mock user authentication - replace with actual auth"""
    return {"id": 1, "email": "test@example.com"}


@router.post("/generate", response_model=ItineraryResponse, status_code=status.HTTP_201_CREATED)
async def generate_itinerary(
    request: ItineraryGenerationRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Generate a new AI-powered itinerary
    
    - **trip_type**: Type of trip (cultural, adventure, relaxation, etc.)
    - **start_date**: Trip start date
    - **end_date**: Trip end date
    - **destinations**: List of cities to visit
    - **budget**: Optional budget constraints
    - **accessibility_requirements**: Special accessibility needs
    """
    
    generator = ItineraryGenerator()
    
    try:
        # Generate itinerary using AI
        itinerary_data = await generator.generate_itinerary(request, current_user["id"])
        
        # Calculate total days
        total_days = (request.end_date - request.start_date).days + 1
        
        # Create database record
        db_itinerary = Itinerary(
            user_id=current_user["id"],
            title=itinerary_data["title"],
            description=itinerary_data.get("description"),
            trip_type=request.trip_type,
            start_date=request.start_date,
            end_date=request.end_date,
            total_days=total_days,
            start_location=request.start_location,
            destinations=request.destinations,
            budget_min=request.budget_min,
            budget_max=request.budget_max,
            accessibility_requirements=request.accessibility_requirements.dict() if request.accessibility_requirements else None,
            dietary_restrictions=request.dietary_restrictions,
            interests=request.interests,
            status=ItineraryStatus.PENDING_APPROVAL,
            safety_level=SafetyLevel(itinerary_data["safety_level"]),
            safety_score=itinerary_data["safety_score"],
            safety_notes=itinerary_data["safety_notes"],
            ai_recommendations=itinerary_data.get("ai_recommendations"),
            daily_plans=itinerary_data.get("daily_plans")
        )
        
        db.add(db_itinerary)
        db.flush()
        
        # Create activity records
        for day_plan in itinerary_data.get("daily_plans", []):
            for activity in day_plan.get("activities", []):
                db_activity = ItineraryActivity(
                    itinerary_id=db_itinerary.id,
                    day_number=activity["day_number"],
                    order_in_day=activity["order_in_day"],
                    title=activity["title"],
                    description=activity.get("description"),
                    location_name=activity["location_name"],
                    latitude=activity.get("latitude"),
                    longitude=activity.get("longitude"),
                    start_time=activity.get("start_time"),
                    end_time=activity.get("end_time"),
                    duration_minutes=activity.get("duration_minutes"),
                    estimated_cost_min=activity.get("estimated_cost_min"),
                    estimated_cost_max=activity.get("estimated_cost_max"),
                    accessibility_friendly=activity.get("accessibility_friendly", True),
                    wheelchair_accessible=activity.get("wheelchair_accessible", False),
                    safety_level=SafetyLevel(activity.get("safety_level", "medium")),
                    safety_warnings=activity.get("safety_warnings", []),
                    recommended_for_solo=activity.get("recommended_for_solo", True),
                    recommended_for_women=activity.get("recommended_for_women", True),
                    category=activity.get("category"),
                    tags=activity.get("tags", []),
                    booking_required=activity.get("booking_required", False),
                    booking_url=activity.get("booking_url")
                )
                db.add(db_activity)
        
        db.commit()
        db.refresh(db_itinerary)
        
        return db_itinerary
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate itinerary: {str(e)}"
        )


@router.get("/{itinerary_id}", response_model=ItineraryResponse)
async def get_itinerary(
    itinerary_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Get a specific itinerary by ID"""
    
    itinerary = db.query(Itinerary).filter(
        Itinerary.id == itinerary_id,
        Itinerary.user_id == current_user["id"]
    ).first()
    
    if not itinerary:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Itinerary not found"
        )
    
    return itinerary


@router.get("/", response_model=List[ItineraryResponse])
async def list_itineraries(
    skip: int = 0,
    limit: int = 10,
    status_filter: ItineraryStatus = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """List all itineraries for current user"""
    
    query = db.query(Itinerary).filter(Itinerary.user_id == current_user["id"])
    
    if status_filter:
        query = query.filter(Itinerary.status == status_filter)
    
    itineraries = query.offset(skip).limit(limit).all()
    return itineraries


@router.post("/{itinerary_id}/approve", response_model=ItineraryResponse)
async def approve_itinerary(
    itinerary_id: int,
    approval: ItineraryApprovalRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Approve or reject a generated itinerary
    
    User must review and approve AI-generated itineraries before activation
    """
    
    itinerary = db.query(Itinerary).filter(
        Itinerary.id == itinerary_id,
        Itinerary.user_id == current_user["id"]
    ).first()
    
    if not itinerary:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Itinerary not found"
        )
    
    if itinerary.status != ItineraryStatus.PENDING_APPROVAL:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Itinerary is not pending approval"
        )
    
    if approval.approved:
        itinerary.status = ItineraryStatus.APPROVED
        itinerary.approved_at = datetime.utcnow()
    else:
        itinerary.status = ItineraryStatus.REJECTED
    
    db.commit()
    db.refresh(itinerary)
    
    return itinerary


@router.post("/{itinerary_id}/validate-safety", response_model=SafetyValidationResponse)
async def validate_itinerary_safety(
    itinerary_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Re-validate safety of an itinerary (useful after modifications)
    """
    
    itinerary = db.query(Itinerary).filter(
        Itinerary.id == itinerary_id,
        Itinerary.user_id == current_user["id"]
    ).first()
    
    if not itinerary:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Itinerary not found"
        )
    
    # Perform safety validation
    warnings = []
    recommendations = []
    
    # Check safety score
    if itinerary.safety_score and itinerary.safety_score < 0.5:
        warnings.append("This itinerary includes some higher-risk locations")
        recommendations.append("Consider traveling with a group or hiring a guide")
    
    # Check for late-night activities
    activities = db.query(ItineraryActivity).filter(
        ItineraryActivity.itinerary_id == itinerary_id
    ).all()
    
    for activity in activities:
        if activity.start_time:
            hour = int(activity.start_time.split(":")[0])
            if hour >= 22 or hour <= 5:
                warnings.append(
                    f"Late night activity: {activity.title} at {activity.start_time}"
                )
                recommendations.append("Arrange safe transportation in advance")
    
    is_safe = len(warnings) == 0 or (itinerary.safety_score and itinerary.safety_score >= 0.6)
    
    return SafetyValidationResponse(
        is_safe=is_safe,
        safety_level=itinerary.safety_level or SafetyLevel.MEDIUM,
        safety_score=itinerary.safety_score or 0.5,
        warnings=warnings,
        recommendations=recommendations
    )


@router.get("/{itinerary_id}/activities", response_model=List[ActivityResponse])
async def get_itinerary_activities(
    itinerary_id: int,
    day: int = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Get all activities for an itinerary, optionally filtered by day"""
    
    # Verify ownership
    itinerary = db.query(Itinerary).filter(
        Itinerary.id == itinerary_id,
        Itinerary.user_id == current_user["id"]
    ).first()
    
    if not itinerary:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Itinerary not found"
        )
    
    query = db.query(ItineraryActivity).filter(
        ItineraryActivity.itinerary_id == itinerary_id
    )
    
    if day is not None:
        query = query.filter(ItineraryActivity.day_number == day)
    
    activities = query.order_by(
        ItineraryActivity.day_number,
        ItineraryActivity.order_in_day
    ).all()
    
    return activities


@router.delete("/{itinerary_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_itinerary(
    itinerary_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Delete an itinerary"""
    
    itinerary = db.query(Itinerary).filter(
        Itinerary.id == itinerary_id,
        Itinerary.user_id == current_user["id"]
    ).first()
    
    if not itinerary:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Itinerary not found"
        )
    
    db.delete(itinerary)
    db.commit()
    
    return None