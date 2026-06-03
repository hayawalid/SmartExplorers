"""Print matches for every traveler in the database.

Rules:
- Service providers do NOT request matches (they are only candidates).
- For each traveler, we run the engine and print detailed match info.

Run: .venv/Scripts/python.exe backend/print_all_matches.py
"""
from app.api import matching as matching_mod


def format_match(match):
    return (
        f"email={match.matched_user_id} | score={match.match_score:.3f} | "
        f"cluster={match.cluster_id} | reasons={'; '.join(match.match_reasons)} | "
        f"interests={match.common_interests} | langs={match.common_languages} | "
        f"budget_compat={match.budget_compatibility:.2f} | safety={match.safety_score:.2f}"
    )


def main():
    engine = matching_mod.matching_engine

    # Fetch all users via engine (synchronous)
    users = engine.fetch_all_users()

    # Ensure model is trained
    verified_users = [u for u in users if u.get('verified_flag', False)]
    if not matching_mod._model_trained:
        n = min(5, max(2, len(verified_users)))
        engine.train_clusters(verified_users, n_clusters=n)
        matching_mod._model_trained = True

    travelers = [u for u in users if u.get('account_type') == 'traveler']
    providers = [u for u in users if u.get('account_type') == 'service_provider']

    print(f"Total users: {len(users)} | travelers: {len(travelers)} | providers: {len(providers)}")

    for t in travelers:
        print("\n" + "-"*80)
        print(f"Traveler: {t.get('full_name')} <{t.get('email')}> | verified={t.get('verified_flag', False)}")

        # Candidate list: all users except the target
        candidates = [u for u in verified_users if u.get('email') != t.get('email')]

        matches = engine.find_matches(target_user=t, candidate_users=candidates, top_k=10)

        if not matches:
            print("  No matches found.")
            continue

        print(f"  Matches for {t.get('email')}: {len(matches)}")
        for i, m in enumerate(matches, start=1):
            print(f"  {i}. {format_match(m)})")

    # For providers, state that they do not request matches
    print("\n" + "="*80)
    print("Service providers do not request matches; they are only candidates for travelers.")


if __name__ == '__main__':
    main()
