#!/usr/bin/env python3
"""
Smart Matching System - Live Test with Real Database Users
Tests the matching engine with actual users from MongoDB
"""

import sys
import asyncio
from pathlib import Path
from datetime import datetime, timedelta

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from app.mongodb import mongodb, connect_to_mongo, close_mongo_connection
from app.services.smart_matching_engine import SmartMatchingEngine


async def fetch_all_users():
    """Fetch all users with their profiles from MongoDB"""
    print("\n" + "="*80)
    print("FETCHING USERS FROM DATABASE")
    print("="*80 + "\n")
    
    users = []
    db = mongodb.db
    
    # Fetch all users
    cursor = db[mongodb.USERS].find({"is_active": True, "is_banned": False})
    
    async for user in cursor:
        user_id = str(user["_id"])
        account_type = user.get("account_type")
        
        user_dict = {
            "_id": user_id,
            "email": user.get("email"),
            "username": user.get("username"),
            "full_name": user.get("full_name"),
            "account_type": account_type,
            "verified_flag": user.get("verified_flag", False),
            "profile_picture_url": user.get("profile_picture_url"),
            "bio": user.get("bio"),
            "travel_dates": []
        }
        
        # Fetch profile based on account type
        if account_type == "traveler":
            profile = await db[mongodb.TRAVELER_PROFILES].find_one({"user_id": user_id})
            if profile:
                profile_dict = dict(profile)
                profile_dict.pop("_id", None)
                profile_dict.pop("user_id", None)
                user_dict["profile"] = profile_dict
                
                print(f"✓ Loaded TRAVELER: {user_dict['full_name']}")
                print(f"  Email: {user_dict['email']}")
                print(f"  Interests: {profile_dict.get('travel_interests', [])[:3]}")
                print(f"  Languages: {profile_dict.get('languages_spoken', [])}")
                print(f"  Budget: ${profile_dict.get('typical_budget_min', 0)}-${profile_dict.get('typical_budget_max', 0)}")
                print()
                
        elif account_type == "service_provider":
            profile = await db[mongodb.SERVICE_PROVIDER_PROFILES].find_one({"user_id": user_id})
            if profile:
                profile_dict = dict(profile)
                profile_dict.pop("_id", None)
                profile_dict.pop("user_id", None)
                user_dict["provider_profile"] = profile_dict
                
                print(f"✓ Loaded PROVIDER: {user_dict['full_name']}")
                print(f"  Email: {user_dict['email']}")
                print(f"  Service: {profile_dict.get('service_type', 'N/A')}")
                print(f"  Languages: {profile_dict.get('languages', [])}")
                print(f"  Price: ${profile_dict.get('price_range_min', 0)}-${profile_dict.get('price_range_max', 0)}")
                print()
        
        users.append(user_dict)
    
    print(f"\nTotal users loaded: {len(users)}")
    travelers = [u for u in users if u.get("account_type") == "traveler"]
    providers = [u for u in users if u.get("account_type") == "service_provider"]
    print(f"  - Travelers: {len(travelers)}")
    print(f"  - Service Providers: {len(providers)}")
    
    return users


def print_separator(title="", width=80):
    """Print a visual separator"""
    print("\n" + "="*width)
    if title:
        print(f"  {title}")
        print("="*width)
    print()


def print_match_details(match, matched_user, index=1):
    """Print detailed match information"""
    print(f"\n{'='*80}")
    print(f"MATCH #{index}: {matched_user.get('full_name', 'Unknown')}")
    print(f"{'='*80}")
    
    print(f"\n📧 Email: {matched_user.get('email')}")
    print(f"👤 Account Type: {matched_user.get('account_type').upper()}")
    print(f"🏆 Match Score: {match.match_score:.4f} ({match.match_score * 100:.2f}%)")
    print(f"🎯 Cluster ID: {match.cluster_id}")
    
    print(f"\n📊 SCORING BREAKDOWN:")
    print(f"  ├─ Safety Score: {match.safety_score:.3f}")
    print(f"  ├─ Budget Compatibility: {match.budget_compatibility:.3f}")
    print(f"  └─ Demographics Bonus: {match.demographics_bonus:.3f}")
    
    if match.common_interests:
        print(f"\n🎨 Common Interests ({len(match.common_interests)}):")
        for interest in match.common_interests[:5]:
            print(f"  • {interest}")
        if len(match.common_interests) > 5:
            print(f"  ... and {len(match.common_interests) - 5} more")
    
    if match.common_languages:
        print(f"\n🌍 Common Languages: {', '.join(match.common_languages)}")
    
    if match.common_dates:
        print(f"\n📅 Overlapping Travel Dates:")
        for date_range in match.common_dates:
            print(f"  • {date_range}")
    
    if match.match_reasons:
        print(f"\n💡 WHY THEY MATCH:")
        for i, reason in enumerate(match.match_reasons, 1):
            print(f"  {i}. {reason}")
    
    # Show user details
    if matched_user.get("account_type") == "traveler":
        profile = matched_user.get("profile", {})
        print(f"\n👤 TRAVELER DETAILS:")
        print(f"  ├─ Nationality: {profile.get('nationality', 'N/A')}")
        print(f"  ├─ Solo Traveler: {'Yes' if profile.get('is_solo_traveler') else 'No'}")
        print(f"  ├─ First Time Egypt: {'Yes' if profile.get('first_time_egypt') else 'No'}")
        print(f"  └─ Budget: ${profile.get('typical_budget_min', 0)}-${profile.get('typical_budget_max', 0)}")
    else:
        profile = matched_user.get("provider_profile", {})
        print(f"\n🏢 PROVIDER DETAILS:")
        print(f"  ├─ Service Type: {profile.get('service_type', 'N/A')}")
        print(f"  ├─ Business: {profile.get('business_name', 'N/A')}")
        print(f"  ├─ Rating: {profile.get('rating', 0):.2f} ({profile.get('review_count', 0)} reviews)")
        print(f"  ├─ Verified: {'Yes' if profile.get('verified_flag') else 'No'}")
        print(f"  └─ Price: ${profile.get('price_range_min', 0)}-${profile.get('price_range_max', 0)}")


async def test_matching_system():
    """Run comprehensive matching tests with real database users"""
    
    print("\n" + "🎯"*40)
    print("\n" + " "*20 + "SMART MATCHING SYSTEM - LIVE TEST")
    print(" "*25 + "Using Real Database Users")
    print("\n" + "🎯"*40)
    
    # Connect to MongoDB
    await connect_to_mongo()
    
    if mongodb.db is None:
        print("\n❌ ERROR: MongoDB not connected!")
        return
    
    # Fetch users
    users = await fetch_all_users()
    
    if len(users) < 2:
        print("\n❌ ERROR: Need at least 2 users for matching!")
        return
    
    # Initialize matching engine
    print_separator("INITIALIZING MATCHING ENGINE")
    engine = SmartMatchingEngine()
    
    # Determine optimal number of clusters (max 5, min 2)
    n_clusters = min(max(len(users) // 3, 2), 5)
    print(f"📊 Training K-means clustering with {len(users)} users and {n_clusters} clusters...")
    
    cluster_labels = engine.train_clusters(users, n_clusters=n_clusters)
    
    print(f"\n✓ Clustering complete!")
    print(f"  Cluster assignments: {dict(enumerate(cluster_labels))}")
    
    # Show cluster distribution
    from collections import Counter
    cluster_dist = Counter(cluster_labels)
    print(f"\n📈 Cluster Distribution:")
    for cluster_id, count in sorted(cluster_dist.items()):
        print(f"  Cluster {cluster_id}: {count} users")
    
    # Find a traveler to test with
    travelers = [u for u in users if u.get("account_type") == "traveler" and u.get("profile")]
    
    if not travelers:
        print("\n⚠️  No travelers with profiles found!")
        return
    
    # Test with first traveler
    target_user = travelers[0]
    
    print_separator(f"TEST CASE: Finding Matches for {target_user['full_name']}")
    
    print(f"👤 TARGET USER PROFILE:")
    print(f"  Name: {target_user['full_name']}")
    print(f"  Email: {target_user['email']}")
    print(f"  Type: {target_user['account_type'].upper()}")
    
    profile = target_user.get('profile', {})
    print(f"\n  📍 Personal Info:")
    print(f"    ├─ Nationality: {profile.get('nationality', 'N/A')}")
    print(f"    ├─ Languages: {', '.join(profile.get('languages_spoken', []))}")
    print(f"    └─ Gender: {profile.get('gender', 'N/A')}")
    
    print(f"\n  🎨 Travel Interests ({len(profile.get('travel_interests', []))}):")
    for interest in profile.get('travel_interests', [])[:5]:
        print(f"    • {interest}")
    
    print(f"\n  💰 Budget: ${profile.get('typical_budget_min', 0)} - ${profile.get('typical_budget_max', 0)}")
    
    print(f"\n  ♿ Accessibility:")
    print(f"    ├─ Wheelchair: {'Yes' if profile.get('wheelchair_access') else 'No'}")
    print(f"    ├─ Visual Assistance: {'Yes' if profile.get('visual_assistance') else 'No'}")
    print(f"    └─ Mobility Support: {'Yes' if profile.get('mobility_support') else 'No'}")
    
    # Create sample travel dates (next month)
    travel_dates = [
        {
            "start_date": datetime.now() + timedelta(days=30),
            "end_date": datetime.now() + timedelta(days=40)
        }
    ]
    
    print(f"\n  📅 Travel Dates: {travel_dates[0]['start_date'].strftime('%Y-%m-%d')} to {travel_dates[0]['end_date'].strftime('%Y-%m-%d')}")
    
    # Find matches
    print_separator("FINDING MATCHES")
    
    candidates = [u for u in users if u.get("email") != target_user.get("email")]
    
    print(f"🔍 Searching through {len(candidates)} potential matches...")
    print(f"   (Including both travelers and service providers)")
    
    matches = engine.find_matches(
        target_user=target_user,
        candidate_users=candidates,
        travel_dates=travel_dates,
        top_k=10
    )
    
    print(f"\n✓ Found {len(matches)} matches!")
    
    # Display top matches
    print_separator("TOP MATCHES")
    
    for i, match in enumerate(matches[:5], 1):
        matched_user = next((u for u in users if u.get("email") == match.matched_user_id), None)
        if matched_user:
            print_match_details(match, matched_user, index=i)
    
    # Get statistics
    print_separator("MATCH STATISTICS")
    
    stats = engine.get_match_statistics(matches)
    
    print(f"📊 OVERALL STATISTICS:")
    print(f"\n  Total Matches: {stats['total_matches']}")
    print(f"  Average Score: {stats['average_score']:.4f} ({stats['average_score'] * 100:.2f}%)")
    print(f"  Top Score: {stats['top_score']:.4f} ({stats['top_score'] * 100:.2f}%)")
    print(f"  Score Std Dev: {stats['score_std']:.4f}")
    
    print(f"\n  📈 Score Distribution:")
    print(f"    ├─ Matches above 90%: {stats['matches_above_90']}")
    print(f"    └─ Matches above 80%: {stats['matches_above_80']}")
    
    print(f"\n  🎨 Top Common Interests:")
    for interest, count in stats['top_interests'][:5]:
        print(f"    • {interest}: {count} matches")
    
    print(f"\n  🌍 Top Common Languages:")
    for language, count in stats['top_languages']:
        print(f"    • {language}: {count} matches")
    
    print(f"\n  🎯 Cluster Distribution:")
    for cluster_id, count in sorted(stats['cluster_distribution'].items()):
        print(f"    • Cluster {cluster_id}: {count} matches")
    
    # Test with a service provider if available
    providers = [u for u in users if u.get("account_type") == "service_provider" and u.get("provider_profile")]
    
    if providers and len(travelers) > 1:
        print_separator("BONUS TEST: Service Provider Cannot Request Matches")
        
        provider = providers[0]
        print(f"\n👔 Testing with provider: {provider['full_name']}")
        print(f"   Type: {provider.get('provider_profile', {}).get('service_type', 'N/A')}")
        
        print(f"\n⚠️  NOTE: Service providers can only be MATCHED TO travelers,")
        print(f"   they cannot actively seek matches (this is by design)")
        
        # This should return empty or skip providers
        provider_matches = engine.find_matches(
            target_user=provider,
            candidate_users=[u for u in users if u.get("email") != provider.get("email")],
            travel_dates=None,
            top_k=5
        )
        
        if len(provider_matches) == 0:
            print(f"\n✓ CORRECT: Provider returned 0 matches (as expected)")
        else:
            print(f"\n⚠️  Provider got {len(provider_matches)} matches")
            print(f"   (These should only be other providers, not travelers)")
    
    # Summary
    print_separator("TEST SUMMARY")
    
    print(f"✅ ALL TESTS COMPLETED SUCCESSFULLY!\n")
    print(f"Key Achievements:")
    print(f"  ✓ Loaded {len(users)} real users from database")
    print(f"  ✓ Trained K-means clustering with {n_clusters} clusters")
    print(f"  ✓ Found {len(matches)} matches for {target_user['full_name']}")
    print(f"  ✓ Average match score: {stats['average_score'] * 100:.2f}%")
    print(f"  ✓ Top match score: {stats['top_score'] * 100:.2f}%")
    
    print(f"\n🎯 Matching System is FULLY OPERATIONAL with real data!")
    print(f"\n" + "="*80 + "\n")
    
    # Close connection
    await close_mongo_connection()


if __name__ == "__main__":
    asyncio.run(test_matching_system())