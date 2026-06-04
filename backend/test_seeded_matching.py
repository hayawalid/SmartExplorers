"""Quick smoke test for the seeded matching data.

This script connects to MongoDB, loads the current users through the same
matching path used by the API, trains the model, and prints one real match run.
"""

import asyncio
import os

from app.api import matching as matching_mod
from app.mongodb import connect_to_mongo, mongodb


async def main() -> None:
    await connect_to_mongo()
    db = mongodb.client[mongodb.DATABASE_NAME]

    loop = asyncio.get_event_loop()
    users = await loop.run_in_executor(None, matching_mod.matching_engine.fetch_all_users)
    verified_users = [u for u in users if u.get("verified_flag", False)]
    travelers = [u for u in verified_users if u.get("account_type") == "traveler"]
    providers = [u for u in verified_users if u.get("account_type") == "service_provider"]

    print(f"Users in DB: {len(users)}")
    print(f"Verified travelers: {len(travelers)}")
    print(f"Verified providers: {len(providers)}")

    if len(verified_users) < 2:
        print("Not enough verified users to test matching.")
        return

    n_clusters = min(5, len(verified_users))
    await matching_mod.initialize_matching_system(db, n_clusters=n_clusters)
    print(f"Matching model trained: {matching_mod._model_trained}")

    target_user = next((u for u in travelers if u.get("email") in {
        "sarah.johnson@email.com",
        "david.oconnor@email.com",
        "maria.garcia@email.com",
    }), None)

    if target_user is None:
        target_user = travelers[0] if travelers else verified_users[0]

    print()
    print(f"Target user: {target_user.get('full_name')} <{target_user.get('email')}>")

    candidate_users = [u for u in verified_users if u.get("email") != target_user.get("email")]
    matches = matching_mod.matching_engine.find_matches(
        target_user=target_user,
        candidate_users=candidate_users,
        top_k=5,
    )

    print(f"Matches found: {len(matches)}")
    for index, match in enumerate(matches, start=1):
        matched_user = next(
            (u for u in users if u.get("email") == match.matched_user_id or u.get("_id") == match.matched_user_id),
            None,
        )
        matched_name = matched_user.get("full_name") if matched_user else match.matched_user_id
        print(
            f"{index}. {matched_name} | score={match.match_score:.3f} | "
            f"cluster={match.cluster_id} | reasons={'; '.join(match.match_reasons)}"
        )


if __name__ == "__main__":
    asyncio.run(main())