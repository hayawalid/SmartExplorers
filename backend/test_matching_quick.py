"""Quick test: can we fetch users and train matching model?"""
import asyncio
from app.mongodb import connect_to_mongo, mongodb
from app.api import matching as matching_mod

async def main():
    await connect_to_mongo()
    db = mongodb.client[mongodb.DATABASE_NAME]
    
    import asyncio as _asyncio
    loop = _asyncio.get_event_loop()
    users = await loop.run_in_executor(None, matching_mod.matching_engine.fetch_all_users)
    print(f"Total users: {len(users)}")
    for u in users:
        acct = u.get('account_type')
        verified = u.get('verified_flag', False)
        profile_key = 'profile' if acct == 'traveler' else 'provider_profile'
        profile = u.get(profile_key, {})
        langs = profile.get('languages_spoken', []) or profile.get('languages', [])
        interests = profile.get('travel_interests', []) or profile.get('services_offered', [])
        prov_verified = profile.get('verified_flag', False) if acct == 'service_provider' else 'N/A'
        print(f"  {u['email']:40s} | {acct:18s} | verified={verified} | prov_verified={prov_verified} | langs={langs} | interests={interests[:3]}")

    if len(users) >= 2:
        n = min(5, len(users))
        print(f"\nTraining with {n} clusters...")
        await matching_mod.initialize_matching_system(db, n_clusters=n)
        print(f"Module _model_trained = {matching_mod._model_trained}")

        # Try match
        traveler = next((u for u in users if u.get("account_type") == "traveler"), None)
        if traveler:
            email = traveler["email"]
            print(f"\nFinding matches for: {email}")
            candidates = [u for u in users if u.get("email") != email]
            print(f"  Candidates: {len(candidates)}")
            
            # Check each candidate manually
            engine = matching_mod.matching_engine
            for c in candidates:
                v = engine._is_verified(c)
                cp = c.get('profile', {}) if c.get('account_type') == 'traveler' else c.get('provider_profile', {})
                cl = cp.get('languages_spoken', []) or cp.get('languages', [])
                tl = traveler.get('profile', {}).get('languages_spoken', [])
                common_l = set(tl) & set(cl) if tl and cl else set()
                print(f"  Candidate: {c['email']:40s} | verified={v} | common_langs={common_l}")
            
            matches = engine.find_matches(
                target_user=traveler,
                candidate_users=candidates,
                top_k=5,
            )
            print(f"\nFound {len(matches)} matches:")
            for m in matches:
                print(f"  - {m.matched_user_id} | score={m.match_score:.2f} | reasons={m.match_reasons}")

asyncio.run(main())

