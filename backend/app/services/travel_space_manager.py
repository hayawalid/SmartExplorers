from typing import Dict, Any, Optional, List
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import and_

from ..models.travel_space import (
    TravelSpace, TravelSpaceMembership, MembershipVote,
    TravelSpaceStatus, MembershipStatus, VoteType
)


class TravelSpaceManager:
    """Manages travel space creation, membership, and democratic voting"""
    
    def calculate_compatibility_score(
        self, 
        applicant_data: Dict[str, Any],
        space: TravelSpace
    ) -> float:
        """
        Calculate compatibility score between applicant and travel space
        Returns score between 0.0 and 1.0
        """
        score = 0.0
        checks = 0
        
        # Age compatibility
        if space.min_age or space.max_age:
            applicant_age = applicant_data.get("age", 25)
            if space.min_age and applicant_age >= space.min_age:
                score += 0.2
            if space.max_age and applicant_age <= space.max_age:
                score += 0.2
            checks += 2
        
        # Language compatibility
        if space.languages:
            applicant_languages = set(applicant_data.get("languages", ["English"]))
            space_languages = set(space.languages)
            if applicant_languages & space_languages:  # Any overlap
                overlap_ratio = len(applicant_languages & space_languages) / len(space_languages)
                score += 0.3 * overlap_ratio
            checks += 1
        
        # Interest alignment
        if space.interests:
            applicant_interests = set(applicant_data.get("interests", []))
            space_interests = set(space.interests)
            if applicant_interests & space_interests:
                overlap_ratio = len(applicant_interests & space_interests) / len(space_interests)
                score += 0.3 * overlap_ratio
            checks += 1
        
        # Gender compatibility (for women-only spaces)
        if space.women_only:
            if applicant_data.get("gender") == "female":
                score += 0.2
            else:
                return 0.0  # Automatic rejection
            checks += 1
        
        # Normalize score
        if checks > 0:
            return min(score / checks * 10, 1.0)  # Scale to 0-1
        return 0.5  # Neutral if no criteria
    
    def can_user_vote(
        self,
        db: Session,
        space_id: int,
        voter_id: int,
        membership_id: int
    ) -> tuple[bool, Optional[str]]:
        """Check if user can vote on a membership application"""
        
        # Check if voter is an active member
        voter_membership = db.query(TravelSpaceMembership).filter(
            and_(
                TravelSpaceMembership.space_id == space_id,
                TravelSpaceMembership.user_id == voter_id,
                TravelSpaceMembership.status.in_([MembershipStatus.ACTIVE, MembershipStatus.APPROVED])
            )
        ).first()
        
        if not voter_membership:
            return False, "You must be an active member to vote"
        
        # Check if already voted
        existing_vote = db.query(MembershipVote).filter(
            and_(
                MembershipVote.membership_id == membership_id,
                MembershipVote.voter_id == voter_id
            )
        ).first()
        
        if existing_vote:
            return False, "You have already voted on this application"
        
        # Check if trying to vote on own application
        application = db.query(TravelSpaceMembership).filter(
            TravelSpaceMembership.id == membership_id
        ).first()
        
        if application and application.user_id == voter_id:
            return False, "You cannot vote on your own application"
        
        return True, None
    
    def process_vote(
        self,
        db: Session,
        space: TravelSpace,
        membership: TravelSpaceMembership,
        vote: VoteType
    ) -> Dict[str, Any]:
        """Process a vote and check if decision threshold is met"""
        
        # Update vote counts
        if vote == VoteType.APPROVE:
            membership.votes_for += 1
        elif vote == VoteType.REJECT:
            membership.votes_against += 1
        
        # Get current active member count (excluding this applicant)
        active_members = db.query(TravelSpaceMembership).filter(
            and_(
                TravelSpaceMembership.space_id == space.id,
                TravelSpaceMembership.status.in_([MembershipStatus.ACTIVE, MembershipStatus.APPROVED]),
                TravelSpaceMembership.id != membership.id
            )
        ).count()
        
        # Calculate votes needed
        votes_needed = max(1, int(active_members * space.voting_threshold))
        membership.votes_needed = votes_needed
        
        total_votes = membership.votes_for + membership.votes_against
        
        result = {
            "decision_made": False,
            "approved": False,
            "rejected": False,
            "votes_for": membership.votes_for,
            "votes_against": membership.votes_against,
            "votes_needed": votes_needed,
            "total_votes": total_votes
        }
        
        # Check if approval threshold met
        if membership.votes_for >= votes_needed:
            membership.status = MembershipStatus.APPROVED
            membership.decided_at = datetime.utcnow()
            membership.joined_at = datetime.utcnow()
            space.current_members += 1
            
            result["decision_made"] = True
            result["approved"] = True
            
            # Check if space should be activated
            if space.current_members >= space.min_members and space.status == TravelSpaceStatus.FORMING:
                space.status = TravelSpaceStatus.ACTIVE
                space.activated_at = datetime.utcnow()
        
        # Check if rejection is certain (even if all remaining vote yes, can't reach threshold)
        elif membership.votes_against >= votes_needed:
            membership.status = MembershipStatus.REJECTED
            membership.decided_at = datetime.utcnow()
            
            result["decision_made"] = True
            result["rejected"] = True
        
        return result
    
    def check_space_capacity(self, space: TravelSpace) -> tuple[bool, Optional[str]]:
        """Check if space has room for new members"""
        if space.current_members >= space.max_members:
            return False, "Travel space is at maximum capacity"
        
        if space.status != TravelSpaceStatus.FORMING:
            return False, f"Travel space is {space.status.value} and not accepting applications"
        
        return True, None
    
    def get_pending_applications(
        self,
        db: Session,
        space_id: int
    ) -> List[TravelSpaceMembership]:
        """Get all pending applications for a space"""
        return db.query(TravelSpaceMembership).filter(
            and_(
                TravelSpaceMembership.space_id == space_id,
                TravelSpaceMembership.status == MembershipStatus.PENDING
            )
        ).all()
    
    def get_active_members(
        self,
        db: Session,
        space_id: int
    ) -> List[TravelSpaceMembership]:
        """Get all active members of a space"""
        return db.query(TravelSpaceMembership).filter(
            and_(
                TravelSpaceMembership.space_id == space_id,
                TravelSpaceMembership.status.in_([MembershipStatus.ACTIVE, MembershipStatus.APPROVED])
            )
        ).all()
    
    def can_user_apply(
        self,
        db: Session,
        space_id: int,
        user_id: int,
        user_data: Dict[str, Any]
    ) -> tuple[bool, Optional[str]]:
        """Check if user meets requirements to apply"""
        
        space = db.query(TravelSpace).filter(TravelSpace.id == space_id).first()
        if not space:
            return False, "Travel space not found"
        
        # Check if already a member or has pending application
        existing = db.query(TravelSpaceMembership).filter(
            and_(
                TravelSpaceMembership.space_id == space_id,
                TravelSpaceMembership.user_id == user_id,
                TravelSpaceMembership.status.in_([
                    MembershipStatus.PENDING,
                    MembershipStatus.APPROVED,
                    MembershipStatus.ACTIVE
                ])
            )
        ).first()
        
        if existing:
            return False, "You already have an active application or membership"
        
        # Check capacity
        has_capacity, error = self.check_space_capacity(space)
        if not has_capacity:
            return False, error
        
        # Check age requirements
        user_age = user_data.get("age")
        if user_age:
            if space.min_age and user_age < space.min_age:
                return False, f"Minimum age is {space.min_age}"
            if space.max_age and user_age > space.max_age:
                return False, f"Maximum age is {space.max_age}"
        
        # Check gender for women-only spaces
        if space.women_only and user_data.get("gender") != "female":
            return False, "This is a women-only travel space"
        
        # Check verification requirement
        if space.require_verification and not user_data.get("is_verified", False):
            return False, "Identity verification required for this space"
        
        return True, None
    
    def leave_space(
        self,
        db: Session,
        space_id: int,
        user_id: int
    ) -> tuple[bool, Optional[str]]:
        """Allow a member to leave a travel space"""
        
        membership = db.query(TravelSpaceMembership).filter(
            and_(
                TravelSpaceMembership.space_id == space_id,
                TravelSpaceMembership.user_id == user_id,
                TravelSpaceMembership.status.in_([MembershipStatus.ACTIVE, MembershipStatus.APPROVED])
            )
        ).first()
        
        if not membership:
            return False, "You are not a member of this space"
        
        if membership.is_creator:
            return False, "Creator cannot leave. Transfer ownership or cancel the space."
        
        membership.status = MembershipStatus.LEFT
        
        space = db.query(TravelSpace).filter(TravelSpace.id == space_id).first()
        if space:
            space.current_members -= 1
            
            # Deactivate if below minimum
            if space.current_members < space.min_members:
                space.status = TravelSpaceStatus.FORMING
        
        return True, None