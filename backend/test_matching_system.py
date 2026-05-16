"""
Test the Smart Matching Engine with REAL database users
Specifically tests accessibility matching for wheelchair users
Shows detailed match logs like before
"""

import sys
from datetime import datetime
from app.services.smart_matching_engine import SmartMatchingEngine, MatchResult
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()
load_dotenv(os.path.join(os.path.dirname(__file__), 'backend', '.env'))


def print_separator(title=""):
    """Print a visual separator"""
    print("\n" + "="*80)
    if title:
        print(f"  {title}")
        print("="*80)
    print()


def print_match_result(match: MatchResult, user_data: dict, index: int):
    """Pretty print a match result in the exact format from before"""
    print(f"{index}.   Match: {user_data.get('full_name', 'Unknown')} ({user_data.get('email', 'N/A')})")
    print(f"  Score: {match.match_score:.3f} | Cluster: {match.cluster_id}")
    print(f"  Safety: {match.safety_score:.2f} | Budget Compat: {match.budget_compatibility:.2f}")
    print(f"  Demographics Bonus: {match.demographics_bonus:.2f}")
    print(f"  Common Interests: {', '.join(match.common_interests[:5]) if match.common_interests else 'None'}")
    print(f"  Common Languages: {', '.join(match.common_languages)}")
    if match.common_dates:
        print(f"  Common Dates: {', '.join(match.common_dates)}")
    print(f"  Reasons: {'; '.join(match.match_reasons)}")
    print()


def test_wheelchair_accessibility_matching():
    """Test accessibility matching for wheelchair users with REAL database users"""
    
    print_separator("ACCESSIBILITY MATCHING TEST - WHEELCHAIR USERS")
    
    # Initialize matching engine
    print("Initializing Smart Matching Engine...")
    engine = SmartMatchingEngine()
    
    try:
        # ===== FETCH REAL USERS FROM DATABASE =====
        print("\n📡 Fetching REAL users from MongoDB...")
        all_users = engine.fetch_all_users()
        
        # Filter only verified users with profiles
        verified_users = [u for u in all_users if engine._is_verified(u)]
        travelers = [u for u in verified_users if u.get("account_type") == "traveler"]
        providers = [u for u in verified_users if u.get("account_type") == "service_provider"]
        
        print(f"\n📊 DATABASE STATISTICS:")
        print(f"  - Total users in DB: {len(all_users)}")
        print(f"  - Verified users with profiles: {len(verified_users)}")
        print(f"  - Travelers: {len(travelers)}")
        print(f"  - Service Providers: {len(providers)}")
        
        # ===== FIND WHEELCHAIR USERS =====
        wheelchair_users = []
        for t in travelers:
            profile = t.get('profile', {})
            if profile.get('wheelchair_access', False) or profile.get('mobility_support', False):
                wheelchair_users.append(t)
        
        if not wheelchair_users:
            print("\n❌ No wheelchair users found in database!")
            print("   Please add wheelchair users to test this feature.")
            return
        
        # ===== TEST: Match wheelchair user with compatible travelers =====
        target_user = wheelchair_users[0]  # David O'Connor
        print_separator(f"TEST: Wheelchair User Seeking Accessible Matches")
        
        print(f"🎯 Target User: {target_user.get('full_name', target_user.get('username'))}")
        print(f"  Email: {target_user.get('email')}")
        print(f"  Accessibility: ", end="")
        access_features = []
        if target_user.get('profile', {}).get('wheelchair_access'):
            access_features.append("Wheelchair Access")
        if target_user.get('profile', {}).get('mobility_support'):
            access_features.append("Mobility Support")
        print(f"{' + '.join(access_features)}")
        print(f"  Interests: {', '.join(target_user.get('profile', {}).get('travel_interests', [])[:5])}")
        print(f"  Languages: {', '.join(target_user.get('profile', {}).get('languages_spoken', []))}")
        print(f"  Budget: ${target_user.get('profile', {}).get('typical_budget_min', 0)}-${target_user.get('profile', {}).get('typical_budget_max', 0)}")
        
        # Train clusters on verified users
        print(f"\n📊 Training K-means clustering on {len(verified_users)} verified users...")
        engine.train_clusters(verified_users, n_clusters=min(5, len(verified_users)))
        print(f"✓ Trained {engine.n_clusters} clusters on {len(verified_users)} verified users")
        print(f"✓ Clusters trained successfully")
        
        # Find matches (exclude self)
        all_candidates = [u for u in verified_users if u.get('email') != target_user.get('email')]
        
        matches = engine.find_matches(
            target_user=target_user,
            candidate_users=all_candidates,
            top_k=10
        )
        
        print(f"\n✅ Found {len(matches)} matches for {target_user.get('full_name')}:\n")
        
        if matches:
            for i, match in enumerate(matches, 1):
                matched_user = next((u for u in all_users if u.get("email") == match.matched_user_id or u.get("_id") == match.matched_user_id), None)
                if matched_user:
                    print_match_result(match, matched_user, i)
                    
                    # Check if matched user also has accessibility features
                    matched_profile = matched_user.get('profile', {})
                    if matched_profile.get('wheelchair_access', False) or matched_profile.get('mobility_support', False):
                        print(f"     ♿ ALSO HAS ACCESSIBILITY NEEDS")
                    print()
        else:
            print("  No matches found for this user.")
        
        # ===== PRINT SUMMARY =====
        print_separator("TEST SUMMARY - ACCESSIBILITY MATCHING")
        
        print(f"\n📊 MATCH STATISTICS:")
        print(f"  • Target user: {target_user.get('full_name')}")
        print(f"  • Total matches found: {len(matches)}")
        
        if matches:
            # Calculate statistics
            scores = [m.match_score for m in matches]
            avg_score = sum(scores) / len(scores) if scores else 0
            print(f"  • Average match score: {avg_score:.3f}")
            print(f"  • Top match score: {max(scores):.3f}")
            print(f"  • Matches above 50%: {len([s for s in scores if s >= 0.5])}")
            print(f"  • Matches with accessibility needs: {sum(1 for m in matches if next((u for u in all_users if u.get('email') == m.matched_user_id), {}).get('profile', {}).get('wheelchair_access', False))}")
        
        print(f"\n✅ Accessibility matching test PASSED!")
        print(f"✓ REAL database test completed successfully")
        
    except Exception as e:
        print(f"\n❌ Error during testing: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        # Close database connection
        engine.close()
        print("\n✓ MongoDB connection closed")
        print("✓ Database connection closed")


if __name__ == "__main__":
    test_wheelchair_accessibility_matching()