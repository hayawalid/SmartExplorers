from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from typing import List, Optional
from datetime import datetime

from ..database import get_db
from ..models.travel_space import (
    TravelSpace, TravelSpaceMembership, MembershipVote,
    TravelSpaceStatus, MembershipStatus, VoteType
)
from ..schemas.travel_space import (
    TravelSpaceCreate,
    TravelSpaceResponse,
    TravelSpaceListItem,
    MembershipApplication,
    MembershipResponse,
    MembershipVoteRequest,
    VotingStatus
)
from ..services.travel_space_manager import TravelSpaceManager

router = APIRouter(prefix="/api/travel-spaces", tags=["travel-spaces"])


# Mock user authentication
async def get_current_user():
    """Mock user - replace with actual auth"""
    return {
        "id": 1,
        "email": "test@example.com",
        "age": 28,
        "gender": "female",
        "languages": ["English", "Arabic"],
        "interests": ["history", "photography"],
        "is_verified": True
    }


@router.post("/", response_model=TravelSpaceResponse, status_code=status.HTTP_201_CREATED)
async def create_travel_space(
    space_data: TravelSpaceCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Create a new travel space (group trip)
    
    Creator is automatically the first member with admin privileges
    """
    
    # Create space
    db_space = TravelSpace(
        name=space_data.name,
        description=space_data.description,
        destination=space_data.destination,
        start_date=space_data.start_date,
        end_date=space_data.end_date,
        itinerary_id=space_data.itinerary_id,
        min_members=space_data.min_members,
        max_members=space_data.max_members,
        current_members=1,  # Creator counts
        voting_threshold=space_data.voting_threshold,
        require_verification=space_data.require_verification,
        women_only=space_data.women_only,
        min_age=space_data.min_age,
        max_age=space_data.max_age,
        languages=space_data.languages,
        interests=space_data.interests,
        is_public=space_data.is_public,
        status=TravelSpaceStatus.FORMING,
        creator_id=current_user["id"]
    )
    
    db.add(db_space)
    db.flush()
    
    # Add creator as first member
    creator_membership = TravelSpaceMembership(
        space_id=db_space.id,
        user_id=current_user["id"],
        status=MembershipStatus.ACTIVE,
        is_creator=True,
        role="admin",
        application_message="Creator",
        compatibility_score=1.0,
        joined_at=datetime.utcnow()
    )
    
    db.add(creator_membership)
    db.commit()
    db.refresh(db_space)
    
    return db_space


@router.get("/", response_model=List[TravelSpaceListItem])
async def list_travel_spaces(
    status_filter: Optional[TravelSpaceStatus] = None,
    destination: Optional[str] = None,
    women_only: Optional[bool] = None,
    has_availability: bool = True,
    skip: int = 0,
    limit: int = Query(20, le=100),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    List available travel spaces
    
    Filters:
    - status: forming, active, completed, cancelled
    - destination: filter by destination city
    - women_only: filter women-only spaces
    - has_availability: only show spaces with open spots
    """
    
    query = db.query(TravelSpace).filter(TravelSpace.is_public == True)
    
    if status_filter:
        query = query.filter(TravelSpace.status == status_filter)
    
    if destination:
        query = query.filter(TravelSpace.destination.ilike(f"%{destination}%"))
    
    if women_only is not None:
        query = query.filter(TravelSpace.women_only == women_only)
    
    if has_availability:
        query = query.filter(TravelSpace.current_members < TravelSpace.max_members)
    
    spaces = query.offset(skip).limit(limit).all()
    return spaces


@router.get("/{space_id}", response_model=TravelSpaceResponse)
async def get_travel_space(
    space_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Get detailed information about a travel space"""
    
    space = db.query(TravelSpace).filter(TravelSpace.id == space_id).first()
    
    if not space:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Travel space not found"
        )
    
    # Check if private and user is not a member
    if not space.is_public:
        is_member = db.query(TravelSpaceMembership).filter(
            and_(
                TravelSpaceMembership.space_id == space_id,
                TravelSpaceMembership.user_id == current_user["id"],
                TravelSpaceMembership.status.in_([MembershipStatus.ACTIVE, MembershipStatus.APPROVED])
            )
        ).first()
        
        if not is_member:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="This is a private travel space"
            )
    
    return space


@router.post("/{space_id}/apply", response_model=MembershipResponse, status_code=status.HTTP_201_CREATED)
async def apply_to_travel_space(
    space_id: int,
    application: MembershipApplication,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Apply to join a travel space
    
    Application will be subject to democratic voting by existing members
    """
    
    manager = TravelSpaceManager()
    
    # Check if user can apply
    can_apply, error = manager.can_user_apply(db, space_id, current_user["id"], current_user)
    if not can_apply:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error
        )
    
    space = db.query(TravelSpace).filter(TravelSpace.id == space_id).first()
    
    # Calculate compatibility score
    compatibility_score = manager.calculate_compatibility_score(current_user, space)
    
    # Create application
    membership = TravelSpaceMembership(
        space_id=space_id,
        user_id=current_user["id"],
        application_message=application.application_message,
        compatibility_score=compatibility_score,
        status=MembershipStatus.PENDING
    )
    
    db.add(membership)
    db.commit()
    db.refresh(membership)
    
    return membership


@router.post("/{space_id}/memberships/{membership_id}/vote", response_model=VotingStatus)
async def vote_on_membership(
    space_id: int,
    membership_id: int,
    vote_request: MembershipVoteRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Vote on a pending membership application
    
    Only active members can vote
    Democratic threshold (default 60%) must be met for approval
    """
    
    manager = TravelSpaceManager()
    
    # Verify space exists
    space = db.query(TravelSpace).filter(TravelSpace.id == space_id).first()
    if not space:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Travel space not found"
        )
    
    # Verify membership exists and is pending
    membership = db.query(TravelSpaceMembership).filter(
        and_(
            TravelSpaceMembership.id == membership_id,
            TravelSpaceMembership.space_id == space_id
        )
    ).first()
    
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Membership application not found"
        )
    
    if membership.status != MembershipStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Application is already {membership.status.value}"
        )
    
    # Check if user can vote
    can_vote, error = manager.can_user_vote(db, space_id, current_user["id"], membership_id)
    if not can_vote:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=error
        )
    
    # Record vote
    vote = MembershipVote(
        space_id=space_id,
        membership_id=membership_id,
        voter_id=current_user["id"],
        vote=vote_request.vote,
        reason=vote_request.reason
    )
    
    db.add(vote)
    
    # Process vote and check for decision
    result = manager.process_vote(db, space, membership, vote_request.vote)
    
    db.commit()
    
    return VotingStatus(
        membership_id=membership_id,
        applicant_id=membership.user_id,
        total_votes=result["total_votes"],
        votes_for=result["votes_for"],
        votes_against=result["votes_against"],
        votes_needed=result["votes_needed"],
        threshold_met=result["decision_made"],
        is_approved=result["approved"],
        is_rejected=result["rejected"]
    )


@router.get("/{space_id}/memberships", response_model=List[MembershipResponse])
async def get_memberships(
    space_id: int,
    status_filter: Optional[MembershipStatus] = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Get all memberships for a travel space
    
    Requires user to be a member to view
    """
    
    # Verify user is a member
    is_member = db.query(TravelSpaceMembership).filter(
        and_(
            TravelSpaceMembership.space_id == space_id,
            TravelSpaceMembership.user_id == current_user["id"],
            TravelSpaceMembership.status.in_([MembershipStatus.ACTIVE, MembershipStatus.APPROVED])
        )
    ).first()
    
    if not is_member:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must be a member to view memberships"
        )
    
    query = db.query(TravelSpaceMembership).filter(
        TravelSpaceMembership.space_id == space_id
    )
    
    if status_filter:
        query = query.filter(TravelSpaceMembership.status == status_filter)
    
    memberships = query.all()
    return memberships


@router.post("/{space_id}/leave", status_code=status.HTTP_204_NO_CONTENT)
async def leave_travel_space(
    space_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Leave a travel space
    
    Creator cannot leave - must transfer ownership or cancel space
    """
    
    manager = TravelSpaceManager()
    
    success, error = manager.leave_space(db, space_id, current_user["id"])
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error
        )
    
    db.commit()
    return None


@router.get("/{space_id}/pending-applications", response_model=List[MembershipResponse])
async def get_pending_applications(
    space_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Get all pending membership applications
    
    Only active members can view pending applications to vote on them
    """
    
    manager = TravelSpaceManager()
    
    # Verify user is an active member
    is_member = db.query(TravelSpaceMembership).filter(
        and_(
            TravelSpaceMembership.space_id == space_id,
            TravelSpaceMembership.user_id == current_user["id"],
            TravelSpaceMembership.status.in_([MembershipStatus.ACTIVE, MembershipStatus.APPROVED])
        )
    ).first()
    
    if not is_member:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must be a member to view pending applications"
        )
    
    applications = manager.get_pending_applications(db, space_id)
    return applications


@router.delete("/{space_id}", status_code=status.HTTP_204_NO_CONTENT)
async def cancel_travel_space(
    space_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Cancel a travel space
    
    Only the creator can cancel
    """
    
    space = db.query(TravelSpace).filter(TravelSpace.id == space_id).first()
    
    if not space:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Travel space not found"
        )
    
    if space.creator_id != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the creator can cancel the travel space"
        )
    
    space.status = TravelSpaceStatus.CANCELLED
    db.commit()
    
    return None