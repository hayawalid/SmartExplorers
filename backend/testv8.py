"""
Test with REAL Cairo businesses that exist in OpenStreetMap
"""
import asyncio
from datetime import datetime, timezone
from bson import ObjectId

from app.mongodb import connect_to_mongo, close_mongo_connection, mongodb
from app.services.provider_verification_service import provider_verification_service


async def create_real_provider(
    name: str,
    email: str,
    business_name: str,
    address: str,
    latitude: float,
    longitude: float,
    phone: str,
    business_license: str,
    city: str,
    has_social: bool = True,
):
    """Create a test provider with REAL Cairo coordinates"""
    
    db = mongodb.db
    
    # Create user
    user_doc = {
        "_id": ObjectId(),
        "email": email,
        "username": name.lower().replace(" ", "_"),
        "hashed_password": "test_hash",
        "full_name": name,
        "account_type": "service_provider",
        "phone_number": phone,
        "verified_flag": True,
        "is_active": True,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc)
    }
    
    result = await db[mongodb.USERS].insert_one(user_doc)
    provider_id = str(result.inserted_id)
    
    # Create provider profile with REAL data
    profile_doc = {
        "user_id": provider_id,
        "full_legal_name": name,
        "phone_number": phone,
        "bio": f"Professional {business_name} service in {city}",
        "service_type": "tour_guide",
        "business_name": business_name,
        "address": address,
        "city": city,
        "governorate": "Cairo",
        "latitude": latitude,
        "longitude": longitude,
        "business_license_number": business_license,
        "business_hours": {
            "monday": {"open": "09:00", "close": "17:00"},
            "tuesday": {"open": "09:00", "close": "17:00"},
            "wednesday": {"open": "09:00", "close": "17:00"},
            "thursday": {"open": "09:00", "close": "17:00"},
            "friday": {"open": "10:00", "close": "14:00"},
            "saturday": {"open": "09:00", "close": "17:00"},
            "sunday": {"open": "09:00", "close": "17:00"}
        },
        "verified_flag": True,
        "verification_status": "verified",
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc)
    }
    
    # Add social media if requested
    if has_social:
        profile_doc["facebook_url"] = f"https://facebook.com/{business_name.lower().replace(' ', '')}"
        profile_doc["instagram_username"] = business_name.lower().replace(" ", "_")
    
    await db[mongodb.SERVICE_PROVIDER_PROFILES].update_one(
        {"user_id": provider_id}, {"$set": profile_doc}, upsert=True
    )
    
    print(f"✓ Created: {name} (ID: {provider_id})")
    print(f"  Business Name in OSM: {business_name}")
    print(f"  Address: {address}")
    print(f"  Coordinates: {latitude}, {longitude}")
    return provider_id


async def add_test_reviews(provider_id: str, db):
    """Add test reviews for a provider"""
    for i in range(5):
        review = {
            "provider_id": provider_id,
            "author_id": "test_user",
            "rating": 4.5 + (i * 0.1),
            "content": f"Excellent service! Very knowledgeable guide. Would recommend! #{i+1}",
            "created_at": datetime.now(timezone.utc)
        }
        await db.reviews.insert_one(review)
    print(f"  ✓ Added 5 test reviews")


async def cleanup_old_test_data():
    """Clean up any existing test data before running"""
    db = mongodb.db
    
    test_emails = [
        "museum@cairoguides.com",
        "khan@bazaarguides.com", 
        "park@azharguides.com"
    ]
    
    for email in test_emails:
        # Find and delete user
        user = await db[mongodb.USERS].find_one({"email": email})
        if user:
            user_id = str(user["_id"])
            # Delete profile
            await db[mongodb.SERVICE_PROVIDER_PROFILES].delete_many({"user_id": user_id})
            # Delete reviews
            await db.reviews.delete_many({"provider_id": user_id})
            # Delete user
            await db[mongodb.USERS].delete_one({"email": email})
            print(f"  Cleaned up: {email}")


async def main():
    """Test with REAL Cairo businesses"""
    
    print("\n" + "=" * 70)
    print("TESTING WITH REAL CAIRO BUSINESSES")
    print("=" * 70 + "\n")
    
    # Connect to MongoDB
    await connect_to_mongo()
    
    # Clean up old test data
    print("🧹 Cleaning up old test data...")
    await cleanup_old_test_data()
    print()
    
    # =========================================================
    # REAL BUSINESS 1: The Egyptian Museum (Tahrir)
    # Using OSM name: "Egyptian Museum"
    # =========================================================
    print("📍 Creating Provider 1: The Egyptian Museum Tour Guide")
    print("-" * 50)
    
    provider1_id = await create_real_provider(
        name="Cairo Museum Guides",
        email="museum@cairoguides.com",
        business_name="Egyptian Museum",  # ← OSM name!
        address="Tahrir Square, Downtown Cairo, Egypt",
        latitude=30.0478,
        longitude=31.2335,
        phone="+20 2 25796948",
        business_license="MUSEUM-2024-001",
        city="Cairo",
        has_social=True
    )
    await add_test_reviews(provider1_id, mongodb.db)
    
    # =========================================================
    # REAL BUSINESS 2: Khan El Khalili Bazaar
    # Using OSM name: "Khan el-Khalili"
    # =========================================================
    print("\n📍 Creating Provider 2: Khan El Khalili Guide")
    print("-" * 50)
    
    provider2_id = await create_real_provider(
        name="Khan Bazaar Experts",
        email="khan@bazaarguides.com",
        business_name="Khan el-Khalili",  # ← OSM name!
        address="Khan El Khalili, El-Gamaleya, Cairo Governorate 4331302, Egypt",
        latitude=30.0472,
        longitude=31.2625,
        phone="+20 2 25903533",
        business_license="KHAN-2024-002",
        city="Cairo",
        has_social=False
    )
    await add_test_reviews(provider2_id, mongodb.db)
    
    # =========================================================
    # REAL BUSINESS 3: Al-Azhar Park
    # Using OSM name: "Al-Azhar Park"
    # =========================================================
    print("\n📍 Creating Provider 3: Al-Azhar Park Guide")
    print("-" * 50)
    
    provider3_id = await create_real_provider(
        name="Al-Azhar Park Tours",
        email="park@azharguides.com",
        business_name="Al-Azhar Park",  # ← OSM name!
        address="Al-Azhar Park, Salah Salem Road, Cairo, Egypt",
        latitude=30.0386,
        longitude=31.2669,
        phone="+20 2 25190251",
        business_license="PARK-2024-003",
        city="Cairo",
        has_social=True
    )
    await add_test_reviews(provider3_id, mongodb.db)
    
    print("\n" + "=" * 70)
    print("RUNNING VERIFICATION FOR ALL PROVIDERS")
    print("=" * 70 + "\n")
    
    # Verify each provider
    results = {}
    
    print("1. Verifying Egyptian Museum Guide...")
    results["museum"] = await provider_verification_service.verify_provider_complete(provider1_id)
    
    print("\n2. Verifying Khan El Khalili Guide...")
    results["khan"] = await provider_verification_service.verify_provider_complete(provider2_id)
    
    print("\n3. Verifying Al-Azhar Park Guide...")
    results["park"] = await provider_verification_service.verify_provider_complete(provider3_id)
    
    # Print detailed results
    print("\n" + "=" * 70)
    print("VERIFICATION RESULTS")
    print("=" * 70)
    
    for name, result in [("Egyptian Museum", results["museum"]), 
                          ("Khan El Khalili", results["khan"]),
                          ("Al-Azhar Park", results["park"])]:
        
        print(f"\n📊 {name}:")
        print(f"   Overall Score: {result.get('overall_score', 0)}/100")
        print(f"   Verification Level: {result.get('verification_level', 'unknown')}")
        print(f"   Total Earned: {result.get('total_earned', 0)}/{result.get('total_max', 0)}")
        print(f"   Checks Passed: {', '.join(result.get('checks_passed', []))}")
        
        # Show individual source scores
        print(f"\n   Source Details:")
        source_scores = result.get('source_scores', {})
        
        # Location
        loc = source_scores.get('location_verification', {})
        loc_passed = "✅ PASS" if loc.get('passed') else "❌ FAIL"
        print(f"   • Location: {loc.get('earned', 0)}/{loc.get('max', 0)} points - {loc_passed}")
        if loc.get('details', {}).get('distance_meters'):
            print(f"     Distance from claimed: {loc['details']['distance_meters']}m")
        if loc.get('details', {}).get('coordinate_match'):
            print(f"     Coordinates match: ✓")
        if loc.get('details', {}).get('business_found_nearby'):
            print(f"     Business found nearby: ✓")
        
        # Business
        bus = source_scores.get('business_existence', {})
        bus_passed = "✅ PASS" if bus.get('passed') else "❌ FAIL"
        print(f"   • Business: {bus.get('earned', 0)}/{bus.get('max', 0)} points - {bus_passed}")
        if bus.get('details', {}).get('osm_id'):
            print(f"     OSM ID: {bus['details']['osm_id']}")
        
        # Social
        soc = source_scores.get('social_media', {})
        soc_passed = "✅ PASS" if soc.get('passed') else "❌ FAIL"
        print(f"   • Social Media: {soc.get('earned', 0)}/{soc.get('max', 0)} points - {soc_passed}")
        
        # Reviews
        rev = source_scores.get('review_analysis', {})
        rev_passed = "✅ PASS" if rev.get('passed') else "❌ FAIL"
        print(f"   • Reviews: {rev.get('earned', 0)}/{rev.get('max', 0)} points - {rev_passed}")
        if rev.get('details', {}).get('review_count'):
            print(f"     Review count: {rev['details']['review_count']}")
            print(f"     Average rating: {rev['details'].get('average_rating', 0)}")
        
        # Duplicates
        dup = source_scores.get('duplicate_check', {})
        dup_passed = "✅ PASS" if dup.get('passed') else "❌ FAIL"
        print(f"   • Duplicates: {dup.get('earned', 0)}/{dup.get('max', 0)} points - {dup_passed}")
        
        # Phone
        phn = source_scores.get('phone_location', {})
        phn_passed = "✅ PASS" if phn.get('passed') else "❌ FAIL"
        print(f"   • Phone: {phn.get('earned', 0)}/{phn.get('max', 0)} points - {phn_passed}")
        
        # Hours
        hrs = source_scores.get('business_hours', {})
        hrs_passed = "✅ PASS" if hrs.get('passed') else "❌ FAIL"
        print(f"   • Hours: {hrs.get('earned', 0)}/{hrs.get('max', 0)} points - {hrs_passed}")
        
        # License
        lic = source_scores.get('license_validity', {})
        lic_passed = "✅ PASS" if lic.get('passed') else "❌ FAIL"
        print(f"   • License: {lic.get('earned', 0)}/{lic.get('max', 0)} points - {lic_passed}")
    
    # Get recommendations (should be sorted by score)
    print("\n" + "=" * 70)
    print("RECOMMENDATIONS (Sorted by Verification Score)")
    print("=" * 70)
    
    recommendations = await provider_verification_service.get_recommended_providers(limit=10)
    
    print("\nRank | Provider Name | Score | Level")
    print("-" * 60)
    for i, provider in enumerate(recommendations, 1):
        if provider.get('full_name') in ["Cairo Museum Guides", "Khan Bazaar Experts", "Al-Azhar Park Tours"]:
            print(f"  {i}.   {provider.get('full_name')[:25]:25} | {provider.get('verification_score', 0):.1f}/100 | {provider.get('verification_level', 'N/A')}")
    
    # Summary
    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print("\n✅ Location verification: Should now get points (address found in OSM)")
    print("✅ Business existence: Should now get points (business name matches OSM)")
    print("✅ Reviews: Should now get points (internal reviews added)")
    print("\nExpected improvement: 36/100 → 60-70/100")
    
    await close_mongo_connection()
    print("\n✓ Test complete!")


if __name__ == "__main__":
    asyncio.run(main())