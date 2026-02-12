"""
Seed script to create a dummy admin account for SmartExplorers.

Credentials:
  Email:    admin@smartexplorers.com
  Password: Admin123!
"""

import asyncio
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

MONGODB_URI = "mongodb+srv://hayaadawy66_db_user:IrclengEMDTg443m@smartexplorers.5dz2fei.mongodb.net/"
DATABASE_NAME = "smartexplorers"


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


async def seed_admin():
    print("Connecting to MongoDB...")
    client = AsyncIOMotorClient(MONGODB_URI)
    db = client[DATABASE_NAME]

    admin_doc = {
        "$set": {
            "username": "admin",
            "full_name": "Admin User",
            "account_type": "admin",
            "is_active": True,
            "updated_at": datetime.now(),
        },
        "$setOnInsert": {
            "hashed_password": hash_password("Admin123!"),
            "created_at": datetime.now(),
        },
    }

    result = await db.users.update_one(
        {"email": "admin@smartexplorers.com"}, admin_doc, upsert=True
    )

    if result.upserted_id:
        print(f"✓ Admin user created  (id: {result.upserted_id})")
    else:
        print("✓ Admin user already exists — updated fields refreshed")

    print("\n  Email:    admin@smartexplorers.com")
    print("  Password: Admin123!")
    print("  Type:     admin\n")

    client.close()


if __name__ == "__main__":
    asyncio.run(seed_admin())
