"""
Full 8-source verification test with realistic reviews
Tests ALL verification checks with good/bad/mixed review scenarios
"""
import asyncio
from datetime import datetime, timezone
from bson import ObjectId

from app.mongodb import connect_to_mongo, close_mongo_connection, mongodb
from app.services.provider_verification_service import provider_verification_service


# ============================================================
# REVIEW SETS — designed to test penalty detection
# ============================================================

REVIEWS_MUSEUM_GOOD = [
    {"rating": 5.0, "content": "Incredible experience at the Egyptian Museum! Our guide was extremely knowledgeable about ancient artifacts. The location on Tahrir Square is easy to find and exactly where they said it would be. Phone number worked perfectly when we called to confirm our booking. Highly recommend!"},
    {"rating": 5.0, "content": "Best tour guide service in Cairo. They were open exactly during the hours listed (9am-5pm). Very professional, licensed, and legitimate business. Worth every penny."},
    {"rating": 4.5, "content": "Wonderful guided tour of the museum. The guide spoke excellent English and knew every exhibit in detail. Location is perfect in downtown Cairo. Will definitely book again!"},
    {"rating": 5.0, "content": "Amazing service! Called them on the listed number and they picked up immediately. Met us right at the museum entrance on Tahrir Square as promised. Totally trustworthy and verified guides."},
    {"rating": 4.8, "content": "Professional, on-time, and incredibly informative. This is clearly a licensed and registered business. The guide had official credentials. No complaints at all — pure excellence."},
]

REVIEWS_KHAN_BAD = [
    {"rating": 1.0, "content": "SCAM! Do not use this service. They took our money and disappeared. The phone number listed does not work — called 10 times, no answer. The address they gave us does not exist, we wandered for an hour. Total fraud, report them!"},
    {"rating": 1.5, "content": "Horrible experience. The location they claimed was completely wrong — we went there and found nothing. They are not licensed at all, someone told us on site they are operating illegally without a permit. Avoid at all costs."},
    {"rating": 2.0, "content": "They said they open at 9am but the place was closed when we arrived at 10am. Called the number and it was disconnected. Very unprofessional. Not sure this is even a real registered business."},
    {"rating": 1.0, "content": "Absolute scam operation. Overcharged us triple the agreed price and threatened us when we complained. The phone number is fake, the address is wrong. These people have no license. We filed a police report."},
    {"rating": 2.5, "content": "Misleading information everywhere. The business hours on their profile say 9-5 but they were closed all day Saturday. Couldn't reach anyone on the phone. Felt very sketchy and unverified."},
]

REVIEWS_PARK_MIXED = [
    {"rating": 4.0, "content": "Pretty good overall experience at Al-Azhar Park. The guide was knowledgeable and the park itself is beautiful. Location was correct and easy to find."},
    {"rating": 3.0, "content": "Mixed experience. The tour was okay but they showed up 45 minutes late. Phone worked fine though and the location was accurate."},
    {"rating": 4.5, "content": "Great service! Very friendly guide who knew the park history well. Would recommend to families visiting Cairo."},
    {"rating": 2.5, "content": "Not great. The hours listed were wrong — they said open at 9am but didn't arrive until 11am. Otherwise the tour content was decent."},
    {"rating": 3.5, "content": "Decent guided tour. Nothing spectacular but nothing terrible either. Location was correct, phone was reachable. Fairly average experience."},
]


async def create_provider(
    name: str,
    email: str,
    business_name: str,
    address: str,
    phone: str,
    business_license: str,
    city: str,
    latitude: float = None,
    longitude: float = None,
    facebook_url: str = None,
    instagram_username: str = None,
    twitter_username: str = None,
) -> str:
    db = mongodb.db

    username = name.lower().replace(" ", "_")
    while await db[mongodb.USERS].find_one({"username": username}):
        username = f"{username}_{ObjectId()}"
    user_doc = {
        "_id": ObjectId(),
        "email": email,
        "username": username,
        "hashed_password": "test_hash",
        "full_name": name,
        "account_type": "service_provider",
        "phone_number": phone,
        "verified_flag": True,
        "is_active": True,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    }
    result = await db[mongodb.USERS].insert_one(user_doc)
    provider_id = str(result.inserted_id)

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
            "monday":    {"open": "09:00", "close": "17:00"},
            "tuesday":   {"open": "09:00", "close": "17:00"},
            "wednesday": {"open": "09:00", "close": "17:00"},
            "thursday":  {"open": "09:00", "close": "17:00"},
            "friday":    {"open": "10:00", "close": "14:00"},
            "saturday":  {"open": "09:00", "close": "17:00"},
            "sunday":    {"open": "09:00", "close": "17:00"},
        },
        "verified_flag": True,
        "verification_status": "verified",
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    }

    if facebook_url:
        profile_doc["facebook_url"] = facebook_url
    if instagram_username:
        profile_doc["instagram_username"] = instagram_username
    if twitter_username:
        profile_doc["twitter_username"] = twitter_username

    await db[mongodb.SERVICE_PROVIDER_PROFILES].update_one(
        {"user_id": provider_id}, {"$set": profile_doc}, upsert=True
    )

    print(f"  ✓ Created provider: {name} (ID: {provider_id})")
    print(f"    Business: {business_name} | City: {city}")
    print(f"    Address: {address}")
    print(f"    Coords: {latitude}, {longitude}")
    print(f"    Phone: {phone} | License: {business_license}")
    if facebook_url:   print(f"    Facebook: {facebook_url}")
    if instagram_username: print(f"    Instagram: @{instagram_username}")
    if twitter_username:   print(f"    Twitter: @{twitter_username}")

    return provider_id


async def insert_reviews(provider_id: str, reviews: list, label: str):
    """Insert reviews via direct DB insert (mirrors social.py POST /reviews logic)"""
    db = mongodb.db
    for i, rev in enumerate(reviews):
        doc = {
            # Matches ReviewModel fields from models.py
            "provider_id": provider_id,
            "author_id":   f"test_tourist_{i+1}",
            "review_type": "providers",
            "title":       f"Review #{i+1}",
            "content":     rev["content"],
            "rating":      rev["rating"],
            "helpful_count": 0,
            "is_public":   True,
            "created_at":  datetime.now(timezone.utc),
        }
        await db[mongodb.REVIEWS].insert_one(doc)
    print(f"  ✓ Inserted {len(reviews)} reviews ({label})")


async def cleanup():
    db = mongodb.db
    test_emails = [
        "museum@test.com",
        "khan@test.com",
        "park@test.com",
    ]
    for email in test_emails:
        user = await db[mongodb.USERS].find_one({"email": email})
        if user:
            uid = str(user["_id"])
            await db[mongodb.SERVICE_PROVIDER_PROFILES].delete_many({"user_id": uid})
            await db[mongodb.REVIEWS].delete_many({"provider_id": uid})
            await db.provider_verifications.delete_many({"provider_id": uid})
            await db[mongodb.USERS].delete_one({"email": email})
            print(f"  Cleaned: {email}")


def print_divider(title=""):
    width = 70
    if title:
        pad = (width - len(title) - 2) // 2
        print("\n" + "=" * pad + f" {title} " + "=" * pad)
    else:
        print("\n" + "=" * width)


def print_all_8_checks(result: dict):
    """Print all 8 verification sources in detail"""
    source_scores = result.get("source_scores", {})

    checks = [
        ("location_verification", "1. Location Verification    ", 15),
        ("business_existence",    "2. Business Existence       ", 10),
        ("social_media",          "3. Social Media             ", 10),
        ("review_analysis",       "4. Review Analysis          ", 15),
        ("duplicate_check",       "5. Duplicate Check          ", 10),
        ("phone_location",        "6. Phone/Location Match     ",  5),
        ("business_hours",        "7. Business Hours           ",  5),
        ("license_validity",      "8. License Validity         ", 10),
    ]

    print(f"\n   {'Check':<35} {'Score':>8}  {'Status'}")
    print(f"   {'-'*35} {'-'*8}  {'-'*12}")

    for key, label, max_pts in checks:
        src = source_scores.get(key, {})
        earned = src.get("earned", 0)
        passed = src.get("passed", False)
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"   {label:<35} {earned:>3}/{max_pts:<3}      {status}")

        # Extra detail per check
        details = src.get("details", {})
        if key == "location_verification":
            dist = details.get("distance_meters")
            coord = details.get("coordinate_match")
            found = details.get("business_found_nearby")
            conf  = details.get("confidence", "?")
            if dist is not None:
                print(f"   {'':35}   distance={dist}m  coord_match={coord}  found={found}  conf={conf}")
        elif key == "social_media":
            platforms = src.get("details", {})
            for plat, data in platforms.items():
                v = "✅" if data.get("verified") else "❌"
                reason = data.get("reason") or data.get("method") or ""
                print(f"   {'':35}   {v} {plat}: {reason}")
        elif key == "review_analysis":
            print(f"   {'':35}   count={details.get('review_count',0)}  "
                  f"avg={details.get('average_rating',0):.1f}  "
                  f"sentiment={details.get('sentiment','?')}  "
                  f"auth={details.get('authenticity_score',0):.2f}")
            red_flags = details.get("red_flags", [])
            penalties = src.get("details", {}).get("verification_penalties", [])
            # penalties stored on result directly from _analyze_reviews
            if red_flags:
                print(f"   {'':35}   🚩 red_flags: {red_flags}")
            if penalties:
                print(f"   {'':35}   ⚠️  penalties: {penalties}")
        elif key == "duplicate_check":
            print(f"   {'':35}   duplicates={details.get('duplicates_found',0)}")
        elif key == "phone_location":
            print(f"   {'':35}   area={details.get('phone_area_code','?')}  "
                  f"expected={details.get('expected_codes',[])}  "
                  f"match={details.get('matches','?')}")
        elif key == "business_hours":
            issues = details.get("issues", [])
            if issues:
                print(f"   {'':35}   issues: {issues}")
        elif key == "license_validity":
            print(f"   {'':35}   {details.get('message','')}  "
                  f"license={details.get('license_number','none')}")


async def main():
    print_divider("FULL 8-SOURCE VERIFICATION TEST")

    await connect_to_mongo()

    print("\n🧹 Cleaning up old test data...")
    await cleanup()

    # ----------------------------------------------------------------
    # PROVIDER 1: Egyptian Museum
    # Expected: HIGH score
    # - Real OSM location + real coordinates ✅
    # - Real Facebook + Instagram accounts ✅
    # - 5 glowing reviews, no red flags ✅
    # - Valid phone for Cairo ✅
    # - Valid license ✅
    # - Normal business hours ✅
    # ----------------------------------------------------------------
    print_divider("Provider 1: Egyptian Museum (SHOULD SCORE HIGH)")

    p1_id = await create_provider(
        name="Cairo Museum Guides",
        email="museum@test.com",
        business_name="Egyptian Museum",
        address="Tahrir Square, Downtown Cairo, Egypt",
        latitude=30.0478,
        longitude=31.2335,
        phone="+20 2 25796948",
        business_license="ETA-GUIDE-2024-001",
        city="Cairo",
        facebook_url="https://facebook.com/EgyptianMuseumCairo",
        instagram_username="grandegyptianmuseum",
        twitter_username="EgyptianMuseum",
    )
    await insert_reviews(p1_id, REVIEWS_MUSEUM_GOOD, "5 positive reviews — no red flags")

    # ----------------------------------------------------------------
    # PROVIDER 2: Khan el-Khalili (fake socials, scam reviews)
    # Expected: LOW score
    # - Real OSM location (business exists) but no coordinates ✅/❌
    # - Fake Facebook + Instagram ❌
    # - 5 scam/fraud reviews with penalty triggers ❌
    # - Valid phone format for Cairo ✅
    # - Valid license format ✅
    # ----------------------------------------------------------------
    print_divider("Provider 2: Khan Bazaar Experts (SHOULD SCORE LOW)")

    p2_id = await create_provider(
        name="Khan Bazaar Experts",
        email="khan@test.com",
        business_name="Khan el-Khalili",
        address="Khan El Khalili, El-Gamaleya, Cairo Governorate, Egypt",
        phone="+20 2 25903533",
        business_license="KHAN-2024-002",
        city="Cairo",
        facebook_url="https://facebook.com/thisplacedoesnotexist12345xyz",
        instagram_username="fake_account_that_doesnt_exist_xyz99999",
    )
    await insert_reviews(p2_id, REVIEWS_KHAN_BAD, "5 scam/fraud reviews — phone/location/license penalties")

    # ----------------------------------------------------------------
    # PROVIDER 3: Lokally (real Instagram, mixed reviews, no coords, no FB)
    # Expected: MEDIUM score
    # - Real address but no coordinates (partial location) ✅/❌
    # - Real Instagram only, no Facebook ✅/❌
    # - Mixed reviews — hours complaint but no scam ❌/✅
    # - Valid phone + license ✅
    # ----------------------------------------------------------------
    print_divider("Provider 3: Lokally / Al-Azhar Park (SHOULD SCORE MEDIUM)")

    p3_id = await create_provider(
        name="Lokally Egypt",
        email="park@test.com",
        business_name="Al-Azhar Park",
        address="Al-Azhar Park, Salah Salem St, El-Darassa, Cairo, Egypt",
        phone="+20 2 25190251",
        business_license="PARK-2024-003",
        city="Cairo",
        instagram_username="lokalegypt",
    )
    await insert_reviews(p3_id, REVIEWS_PARK_MIXED, "5 mixed reviews — minor hours complaint")

    # ----------------------------------------------------------------
    # RUN VERIFICATION
    # ----------------------------------------------------------------
    print_divider("RUNNING ALL VERIFICATIONS")

    print("\n⏳ Verifying Provider 1 (Egyptian Museum)...")
    r1 = await provider_verification_service.verify_provider_complete(p1_id)

    print("⏳ Verifying Provider 2 (Khan Bazaar / Fake)...")
    r2 = await provider_verification_service.verify_provider_complete(p2_id)

    print("⏳ Verifying Provider 3 (Lokally / Mixed)...")
    r3 = await provider_verification_service.verify_provider_complete(p3_id)

    # ----------------------------------------------------------------
    # RESULTS
    # ----------------------------------------------------------------
    print_divider("RESULTS — ALL 8 CHECKS")

    for label, result, expected_tier in [
        ("Egyptian Museum Guides  (expect: HIGH  / verified+)",  r1, "verified"),
        ("Khan Bazaar Experts     (expect: LOW   / basic)",       r2, "basic"),
        ("Lokally Egypt           (expect: MEDIUM/ standard)",    r3, "standard"),
    ]:
        score = result.get("overall_score", 0)
        level = result.get("verification_level", "?")
        tier_ok = "✅" if level in expected_tier else "❌"
        print(f"\n{'─'*70}")
        print(f"📊 {label}")
        print(f"   Overall Score : {score:.1f}/100")
        print(f"   Level         : {level}  {tier_ok} (expected ~{expected_tier})")
        print_all_8_checks(result)

    # ----------------------------------------------------------------
    # SUMMARY TABLE
    # ----------------------------------------------------------------
    print_divider("SUMMARY TABLE")

    headers = ["Provider", "Score", "Level", "Loc", "Biz", "Social", "Reviews", "Dup", "Phone", "Hours", "License"]
    row_fmt  = "{:<28} {:>6} {:>12}  {:>5} {:>5} {:>7} {:>8} {:>5} {:>6} {:>6} {:>8}"
    print("\n" + row_fmt.format(*headers))
    print("─" * 100)

    for name, result in [
        ("Cairo Museum Guides",   r1),
        ("Khan Bazaar Experts",   r2),
        ("Lokally Egypt",         r3),
    ]:
        ss = result.get("source_scores", {})
        def e(k): return ss.get(k, {}).get("earned", 0)
        print(row_fmt.format(
            name,
            f"{result.get('overall_score',0):.1f}/100",
            result.get("verification_level", "?"),
            f"{e('location_verification')}/15",
            f"{e('business_existence')}/10",
            f"{e('social_media')}/10",
            f"{e('review_analysis')}/15",
            f"{e('duplicate_check')}/10",
            f"{e('phone_location')}/5",
            f"{e('business_hours')}/5",
            f"{e('license_validity')}/10",
        ))

    # ----------------------------------------------------------------
    # PASS/FAIL ASSERTIONS
    # ----------------------------------------------------------------
    print_divider("PASS / FAIL ASSERTIONS")

    assertions = [
        # (description, condition)
        ("Museum social score >= 5",          r1["source_scores"]["social_media"]["earned"] >= 5),
        ("Museum reviews score > 0",          r1["source_scores"]["review_analysis"]["earned"] > 0),
        ("Museum location score >= 5",        r1["source_scores"]["location_verification"]["earned"] >= 5),
        ("Museum overall score > Khan score", r1["overall_score"] > r2["overall_score"]),
        ("Khan social score == 0",            r2["source_scores"]["social_media"]["earned"] == 0),
        ("Khan social FAIL",                  not r2["source_scores"]["social_media"]["passed"]),
        ("Khan reviews score <= Museum",      r2["source_scores"]["review_analysis"]["earned"] <= r1["source_scores"]["review_analysis"]["earned"]),
        ("Park Instagram fails (no API)",     not r3["source_scores"]["social_media"]["details"].get("instagram", {}).get("verified", True)),
        ("License valid for all 3",           all(
            r["source_scores"]["license_validity"]["earned"] > 0
            for r in [r1, r2, r3]
        )),
        ("No duplicates for any",             all(
            r["source_scores"]["duplicate_check"]["passed"]
            for r in [r1, r2, r3]
        )),
    ]

    all_passed = True
    for desc, condition in assertions:
        icon = "✅" if condition else "❌"
        print(f"  {icon} {desc}")
        if not condition:
            all_passed = False

    print(f"\n{'✅ ALL ASSERTIONS PASSED' if all_passed else '❌ SOME ASSERTIONS FAILED'}")

    await close_mongo_connection()
    print("\n✓ Test complete!")


if __name__ == "__main__":
    asyncio.run(main())