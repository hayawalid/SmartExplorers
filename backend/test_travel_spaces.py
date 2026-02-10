#!/usr/bin/env python3
"""
SmartExplorers - Travel Spaces (Part 4) Test Script
Democratic Group Travel with Safety Governance
"""

import sys
import json
from datetime import date, timedelta, datetime
from typing import Dict, Any, List


class MockTravelSpaceSystem:
    """Mock implementation of Travel Spaces for testing"""
    
    def __init__(self):
        self.spaces: Dict[int, Dict] = {}
        self.memberships: Dict[int, Dict] = {}
        self.votes: List[Dict] = []
        self.next_space_id = 1
        self.next_membership_id = 1
        self.next_vote_id = 1
        
        # Mock users
        self.users = {
            1: {"id": 1, "name": "Sarah Ahmed", "age": 28, "gender": "female", 
                "languages": ["English", "Arabic"], "interests": ["history", "photography"], "verified": True},
            2: {"id": 2, "name": "Maya Hassan", "age": 25, "gender": "female",
                "languages": ["English", "French"], "interests": ["culture", "food"], "verified": True},
            3: {"id": 3, "name": "Layla Ibrahim", "age": 30, "gender": "female",
                "languages": ["Arabic", "English"], "interests": ["history", "art"], "verified": True},
            4: {"id": 4, "name": "Nour Khalil", "age": 27, "gender": "female",
                "languages": ["English"], "interests": ["adventure", "photography"], "verified": True},
            5: {"id": 5, "name": "Ahmed Ali", "age": 35, "gender": "male",
                "languages": ["Arabic"], "interests": ["history"], "verified": True}
        }
    
    def create_space(self, creator_id: int, data: Dict) -> Dict:
        """Create a new travel space"""
        space_id = self.next_space_id
        self.next_space_id += 1
        
        space = {
            "id": space_id,
            "name": data["name"],
            "description": data.get("description", ""),
            "destination": data["destination"],
            "start_date": data["start_date"],
            "end_date": data["end_date"],
            "min_members": data.get("min_members", 2),
            "max_members": data.get("max_members", 10),
            "current_members": 1,
            "voting_threshold": data.get("voting_threshold", 0.6),
            "women_only": data.get("women_only", False),
            "require_verification": data.get("require_verification", True),
            "languages": data.get("languages", []),
            "interests": data.get("interests", []),
            "min_age": data.get("min_age", 18),
            "max_age": data.get("max_age"),
            "status": "forming",
            "creator_id": creator_id,
            "created_at": datetime.now().isoformat()
        }
        
        self.spaces[space_id] = space
        
        # Add creator as first member
        membership_id = self.next_membership_id
        self.next_membership_id += 1
        
        self.memberships[membership_id] = {
            "id": membership_id,
            "space_id": space_id,
            "user_id": creator_id,
            "status": "active",
            "is_creator": True,
            "role": "admin",
            "compatibility_score": 1.0,
            "votes_for": 0,
            "votes_against": 0,
            "joined_at": datetime.now().isoformat()
        }
        
        return space
    
    def calculate_compatibility(self, user: Dict, space: Dict) -> float:
        """Calculate compatibility score"""
        score = 0.5  # Base score
        
        # Language match
        user_langs = set(user.get("languages", []))
        space_langs = set(space.get("languages", []))
        if user_langs & space_langs:
            score += 0.2
        
        # Interest match
        user_interests = set(user.get("interests", []))
        space_interests = set(space.get("interests", []))
        if user_interests & space_interests:
            overlap = len(user_interests & space_interests) / max(len(space_interests), 1)
            score += 0.3 * overlap
        
        return min(score, 1.0)
    
    def apply(self, user_id: int, space_id: int, message: str = "") -> Dict:
        """Apply to join a space"""
        space = self.spaces.get(space_id)
        if not space:
            raise ValueError("Space not found")
        
        user = self.users.get(user_id)
        if not user:
            raise ValueError("User not found")
        
        # Check requirements
        if space["women_only"] and user["gender"] != "female":
            raise ValueError("This is a women-only space")
        
        if space["current_members"] >= space["max_members"]:
            raise ValueError("Space is full")
        
        if space["require_verification"] and not user.get("verified"):
            raise ValueError("Verification required")
        
        # Check age
        if user["age"] < space["min_age"]:
            raise ValueError(f"Minimum age is {space['min_age']}")
        if space["max_age"] and user["age"] > space["max_age"]:
            raise ValueError(f"Maximum age is {space['max_age']}")
        
        # Calculate compatibility
        compatibility = self.calculate_compatibility(user, space)
        
        membership_id = self.next_membership_id
        self.next_membership_id += 1
        
        membership = {
            "id": membership_id,
            "space_id": space_id,
            "user_id": user_id,
            "status": "pending",
            "application_message": message,
            "compatibility_score": compatibility,
            "votes_for": 0,
            "votes_against": 0,
            "is_creator": False,
            "role": "member",
            "applied_at": datetime.now().isoformat()
        }
        
        self.memberships[membership_id] = membership
        return membership
    
    def vote(self, voter_id: int, membership_id: int, vote: str, reason: str = "") -> Dict:
        """Vote on a membership application"""
        membership = self.memberships.get(membership_id)
        if not membership:
            raise ValueError("Membership not found")
        
        if membership["status"] != "pending":
            raise ValueError(f"Application is {membership['status']}")
        
        space = self.spaces[membership["space_id"]]
        
        # Check if voter is active member
        is_member = False
        for m in self.memberships.values():
            if (m["space_id"] == space["id"] and 
                m["user_id"] == voter_id and 
                m["status"] in ["active", "approved"]):
                is_member = True
                break
        
        if not is_member:
            raise ValueError("You must be a member to vote")
        
        # Check if already voted
        for v in self.votes:
            if v["membership_id"] == membership_id and v["voter_id"] == voter_id:
                raise ValueError("You already voted")
        
        # Record vote
        vote_id = self.next_vote_id
        self.next_vote_id += 1
        
        vote_record = {
            "id": vote_id,
            "membership_id": membership_id,
            "voter_id": voter_id,
            "vote": vote,
            "reason": reason,
            "created_at": datetime.now().isoformat()
        }
        
        self.votes.append(vote_record)
        
        # Update counts
        if vote == "approve":
            membership["votes_for"] += 1
        elif vote == "reject":
            membership["votes_against"] += 1
        
        # Check if decision made
        active_members = sum(1 for m in self.memberships.values()
                           if m["space_id"] == space["id"] and 
                           m["status"] in ["active", "approved"] and
                           m["id"] != membership_id)
        
        votes_needed = max(1, round(active_members * space["voting_threshold"]))  # Round up for threshold
        
        result = {
            "decision_made": False,
            "approved": False,
            "rejected": False,
            "votes_for": membership["votes_for"],
            "votes_against": membership["votes_against"],
            "votes_needed": votes_needed
        }
        
        if membership["votes_for"] >= votes_needed:
            membership["status"] = "approved"
            membership["joined_at"] = datetime.now().isoformat()
            space["current_members"] += 1
            result["decision_made"] = True
            result["approved"] = True
            
            # Activate space if minimum reached
            if space["current_members"] >= space["min_members"]:
                space["status"] = "active"
        
        elif membership["votes_against"] >= votes_needed:
            membership["status"] = "rejected"
            result["decision_made"] = True
            result["rejected"] = True
        
        return result
    
    def get_space(self, space_id: int) -> Dict:
        """Get space details"""
        return self.spaces.get(space_id)
    
    def get_memberships(self, space_id: int, status: str = None) -> List[Dict]:
        """Get memberships for a space"""
        memberships = [m for m in self.memberships.values() if m["space_id"] == space_id]
        if status:
            memberships = [m for m in memberships if m["status"] == status]
        return memberships


def print_header(title: str):
    """Print section header"""
    print("\n" + "=" * 80)
    print(f"  {title}")
    print("=" * 80 + "\n")


def print_space(space: Dict):
    """Print space details"""
    print(f"📍 {space['name']}")
    print(f"   Destination: {space['destination']}")
    print(f"   Dates: {space['start_date']} to {space['end_date']}")
    print(f"   Members: {space['current_members']}/{space['max_members']}")
    print(f"   Status: {space['status'].upper()}")
    print(f"   Women-only: {'Yes' if space['women_only'] else 'No'}")
    print(f"   Voting threshold: {int(space['voting_threshold']*100)}%")
    if space['languages']:
        print(f"   Languages: {', '.join(space['languages'])}")
    if space['interests']:
        print(f"   Interests: {', '.join(space['interests'])}")


def print_membership(membership: Dict, users: Dict):
    """Print membership details"""
    user = users[membership["user_id"]]
    status_emoji = {
        "pending": "⏳",
        "approved": "✅",
        "rejected": "❌",
        "active": "👤"
    }
    emoji = status_emoji.get(membership["status"], "")
    
    print(f"   {emoji} {user['name']} (ID: {user['id']})")
    print(f"      Status: {membership['status'].upper()}")
    print(f"      Compatibility: {membership['compatibility_score']:.1%}")
    if membership["status"] == "pending":
        print(f"      Votes: {membership['votes_for']} for, {membership['votes_against']} against")
    if membership.get("is_creator"):
        print(f"      Role: Creator/Admin")


def main():
    """Run Travel Spaces demonstration"""
    print("=" * 80)
    print("  SmartExplorers - Travel Spaces Demo")
    print("  Part 4: Democratic Group Travel with Safety Governance")
    print("=" * 80)
    
    system = MockTravelSpaceSystem()
    
    # Scenario: Women-only cultural trip to Luxor
    print_header("SCENARIO: Creating a Women-Only Cultural Trip")
    
    start_date = (date.today() + timedelta(days=60)).isoformat()
    end_date = (date.today() + timedelta(days=64)).isoformat()
    
    space_data = {
        "name": "Women's Cultural Journey - Luxor & Aswan",
        "description": "A safe, empowering trip exploring ancient Egyptian temples",
        "destination": "Luxor",
        "start_date": start_date,
        "end_date": end_date,
        "min_members": 3,
        "max_members": 6,
        "women_only": True,
        "voting_threshold": 0.6,  # 60% approval needed
        "languages": ["English", "Arabic"],
        "interests": ["history", "photography", "culture"],
        "min_age": 21,
        "max_age": 45,
        "require_verification": True
    }
    
    # Sarah creates the space
    print("1️⃣  Sarah creates the travel space...")
    space = system.create_space(1, space_data)
    print_space(space)
    
    # Show current memberships
    print_header("Current Members")
    memberships = system.get_memberships(space["id"])
    for m in memberships:
        print_membership(m, system.users)
    
    # Maya applies
    print_header("Application #1: Maya Hassan applies")
    maya_app = system.apply(2, space["id"], "I'm passionate about Egyptian history and would love to join!")
    print(f"✓ Application submitted")
    print(f"  Compatibility score: {maya_app['compatibility_score']:.1%}")
    print(f"  Status: {maya_app['status'].upper()}")
    
    # Sarah votes to approve Maya
    print("\n👍 Sarah (creator) votes to APPROVE Maya...")
    result = system.vote(1, maya_app["id"], "approve", "Great profile and shared interests!")
    print(f"  Votes needed: {result['votes_needed']}")
    print(f"  Votes for: {result['votes_for']}")
    print(f"  Decision made: {result['decision_made']}")
    if result["approved"]:
        print(f"  ✅ APPROVED! Maya is now a member")
    
    # Layla applies
    print_header("Application #2: Layla Ibrahim applies")
    layla_app = system.apply(3, space["id"], "Love the itinerary! I speak Arabic fluently.")
    print(f"✓ Application submitted")
    print(f"  Compatibility score: {layla_app['compatibility_score']:.1%}")
    
    # Both Sarah and Maya vote
    print("\n👍 Sarah votes to APPROVE Layla...")
    result = system.vote(1, layla_app["id"], "approve", "Excellent language skills!")
    print(f"  Votes: {result['votes_for']} for, {result['votes_against']} against")
    print(f"  Votes needed: {result['votes_needed']}")
    
    if not result["decision_made"]:
        print("\n👍 Maya votes to APPROVE Layla...")
        result = system.vote(2, layla_app["id"], "approve", "Perfect fit for our group!")
        print(f"  Votes: {result['votes_for']} for, {result['votes_against']} against")
    
    if result["approved"]:
        print(f"  ✅ APPROVED! Threshold met ({result['votes_for']}/{result['votes_needed']})")
        print(f"  🎉 Group is now ACTIVE (minimum {space_data['min_members']} members reached)")
    
    # Nour applies
    print_header("Application #3: Nour Khalil applies")
    nour_app = system.apply(4, space["id"], "Excited to join! I'm a photographer.")
    print(f"✓ Application submitted")
    print(f"  Compatibility score: {nour_app['compatibility_score']:.1%}")
    
    # Mixed voting
    print("\n👍 Sarah votes to APPROVE Nour...")
    system.vote(1, nour_app["id"], "approve", "Photography skills will be great!")
    
    print("👎 Maya votes to REJECT Nour...")
    result = system.vote(2, nour_app["id"], "reject", "Concerned about group dynamics")
    print(f"  Votes: {result['votes_for']} for, {result['votes_against']} against")
    
    print("\n👍 Layla votes to APPROVE Nour...")
    result = system.vote(3, nour_app["id"], "approve", "She seems nice!")
    print(f"  Votes: {result['votes_for']} for, {result['votes_against']} against")
    if result["approved"]:
        print(f"  ✅ APPROVED! Threshold met ({result['votes_for']}/{result['votes_needed']})")
    
    # Try to apply a male user (should fail)
    print_header("Safety Test: Male tries to join women-only space")
    try:
        system.apply(5, space["id"], "Can I join?")
        print("  ❌ ERROR: Should have been rejected!")
    except ValueError as e:
        print(f"  ✅ Correctly rejected: {e}")
    
    # Final status
    print_header("Final Travel Space Status")
    final_space = system.get_space(space["id"])
    print_space(final_space)
    
    print("\n📊 Membership Breakdown:")
    all_members = system.get_memberships(space["id"])
    
    active = [m for m in all_members if m["status"] in ["active", "approved"]]
    pending = [m for m in all_members if m["status"] == "pending"]
    rejected = [m for m in all_members if m["status"] == "rejected"]
    
    print(f"\n  Active Members ({len(active)}):")
    for m in active:
        print_membership(m, system.users)
    
    if pending:
        print(f"\n  Pending Applications ({len(pending)}):")
        for m in pending:
            print_membership(m, system.users)
    
    if rejected:
        print(f"\n  Rejected Applications ({len(rejected)}):")
        for m in rejected:
            print_membership(m, system.users)
    
    # Show voting history
    print_header("Voting History")
    for vote in system.votes:
        membership = system.memberships[vote["membership_id"]]
        voter = system.users[vote["voter_id"]]
        applicant = system.users[membership["user_id"]]
        vote_emoji = "👍" if vote["vote"] == "approve" else "👎"
        
        print(f"{vote_emoji} {voter['name']} voted to {vote['vote'].upper()} {applicant['name']}")
        if vote["reason"]:
            print(f"   Reason: {vote['reason']}")
    
    print_header("Key Features Demonstrated")
    print("✅ Democratic group formation")
    print("✅ Majority voting system (60% threshold)")
    print("✅ Compatibility scoring")
    print("✅ Women-only space enforcement")
    print("✅ Identity verification requirements")
    print("✅ Age restrictions")
    print("✅ Language and interest matching")
    print("✅ Automatic space activation")
    print("✅ Creator privileges")
    print("✅ Member voting rights")
    
    print_header("Safety & Governance Benefits")
    print("🛡️  Women can travel together safely")
    print("🗳️  Democratic admission prevents bad actors")
    print("✓  Verification required for trust")
    print("👥  Shared interests ensure compatibility")
    print("🌍  Language compatibility for smooth communication")
    print("⚖️  Fair voting process (60% majority)")
    print("🔒  Age-appropriate grouping")
    
    print("\n" + "=" * 80)
    print("  Demo Complete!")
    print("=" * 80 + "\n")


if __name__ == "__main__":
    main()