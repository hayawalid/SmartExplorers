"""
Admin API – Dashboard analytics, provider requests, user reports
"""
from fastapi import APIRouter, HTTPException, status, Query
from pydantic import BaseModel, Field
from typing import Optional, List, Any, Dict
from datetime import datetime, timedelta

from app.mongodb import get_database, mongodb

router = APIRouter(
    prefix="/api/v1/admin",
    tags=["Admin Dashboard"],
)


# ── Response Schemas ──────────────────────────────────────────────────

class DashboardStats(BaseModel):
    total_users: int = 0
    total_travelers: int = 0
    total_providers: int = 0
    total_posts: int = 0
    total_bookings: int = 0
    total_reviews: int = 0
    total_itineraries: int = 0
    total_listings: int = 0
    total_panic_events: int = 0
    verified_providers: int = 0
    new_users_today: int = 0
    new_users_week: int = 0


class UserGrowthPoint(BaseModel):
    date: str
    count: int


class ProviderRequest(BaseModel):
    id: str
    user_id: str
    full_name: str
    email: str
    service_type: str
    bio: str = ""
    phone_number: str = ""
    created_at: str = ""
    verification_status: str = "pending"
    avatar_url: str = ""


class UserReport(BaseModel):
    id: str
    reporter_id: str
    reporter_name: str = ""
    reported_user_id: str = ""
    reported_user_name: str = ""
    reason: str = ""
    description: str = ""
    status: str = "pending"
    created_at: str = ""


class CategoryBreakdown(BaseModel):
    category: str
    count: int


# ── Endpoints ────────────────────────────────────────────────────────

@router.get("/stats", response_model=DashboardStats)
async def get_dashboard_stats():
    """Get overall platform statistics for the admin dashboard."""
    try:
        db = get_database()
        now = datetime.utcnow()
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        week_ago = now - timedelta(days=7)

        total_users = await db[mongodb.USERS].count_documents({})
        total_travelers = await db[mongodb.USERS].count_documents({"account_type": "traveler"})
        total_providers = await db[mongodb.USERS].count_documents({"account_type": "service_provider"})
        total_posts = await db[mongodb.POSTS].count_documents({})
        total_bookings = await db[mongodb.BOOKINGS].count_documents({})
        total_reviews = await db[mongodb.REVIEWS].count_documents({})
        total_itineraries = await db[mongodb.ITINERARIES].count_documents({})
        total_listings = await db[mongodb.SERVICE_LISTINGS].count_documents({})
        total_panic = await db[mongodb.PANIC_EVENTS].count_documents({})

        verified_providers = await db[mongodb.USERS].count_documents({
            "account_type": "service_provider",
            "$or": [
                {"verified_flag": True},
                {"identity_verified": True},
            ]
        })

        new_today = await db[mongodb.USERS].count_documents({
            "created_at": {"$gte": today_start}
        })
        new_week = await db[mongodb.USERS].count_documents({
            "created_at": {"$gte": week_ago}
        })

        return DashboardStats(
            total_users=total_users,
            total_travelers=total_travelers,
            total_providers=total_providers,
            total_posts=total_posts,
            total_bookings=total_bookings,
            total_reviews=total_reviews,
            total_itineraries=total_itineraries,
            total_listings=total_listings,
            total_panic_events=total_panic,
            verified_providers=verified_providers,
            new_users_today=new_today,
            new_users_week=new_week,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Stats error: {str(e)}")


@router.get("/provider-requests", response_model=List[ProviderRequest])
async def get_provider_requests(
    status_filter: Optional[str] = Query(None, alias="status"),
):
    """List service provider signup/verification requests."""
    try:
        db = get_database()
        query: Dict[str, Any] = {"account_type": "service_provider"}

        providers_cursor = db[mongodb.USERS].find(query).sort("created_at", -1).limit(50)
        providers = await providers_cursor.to_list(length=50)

        results: List[ProviderRequest] = []
        for p in providers:
            # Get provider profile for extra details
            profile = await db[mongodb.SERVICE_PROVIDER_PROFILES].find_one(
                {"user_id": str(p["_id"])}
            )
            v_status = "verified" if p.get("verified_flag") or p.get("identity_verified") else "pending"
            if status_filter and v_status != status_filter:
                continue

            results.append(ProviderRequest(
                id=str(p["_id"]),
                user_id=str(p["_id"]),
                full_name=p.get("full_name", ""),
                email=p.get("email", ""),
                service_type=profile.get("service_type", "") if profile else p.get("service_type", ""),
                bio=profile.get("bio", "") if profile else p.get("bio", ""),
                phone_number=p.get("phone_number", ""),
                created_at=str(p.get("created_at", "")),
                verification_status=v_status,
                avatar_url=p.get("avatar_url", ""),
            ))

        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Provider requests error: {str(e)}")


@router.post("/provider-requests/{provider_id}/approve")
async def approve_provider(provider_id: str):
    """Approve a service provider."""
    try:
        db = get_database()
        from bson import ObjectId
        result = await db[mongodb.USERS].update_one(
            {"_id": ObjectId(provider_id)},
            {"$set": {"verified_flag": True, "identity_verified": True, "updated_at": datetime.utcnow()}}
        )
        if result.modified_count == 0:
            raise HTTPException(status_code=404, detail="Provider not found")
        return {"success": True, "message": "Provider approved"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/provider-requests/{provider_id}/reject")
async def reject_provider(provider_id: str):
    """Reject a service provider."""
    try:
        db = get_database()
        from bson import ObjectId
        result = await db[mongodb.USERS].update_one(
            {"_id": ObjectId(provider_id)},
            {"$set": {"verified_flag": False, "identity_verified": False, "updated_at": datetime.utcnow()}}
        )
        if result.modified_count == 0:
            raise HTTPException(status_code=404, detail="Provider not found")
        return {"success": True, "message": "Provider rejected"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/reports", response_model=List[UserReport])
async def get_user_reports(
    status_filter: Optional[str] = Query(None, alias="status"),
):
    """List user reports."""
    try:
        db = get_database()
        query: Dict[str, Any] = {}
        if status_filter:
            query["status"] = status_filter

        reports_cursor = db["reports"].find(query).sort("created_at", -1).limit(50)
        reports = await reports_cursor.to_list(length=50)

        results: List[UserReport] = []
        for r in reports:
            results.append(UserReport(
                id=str(r["_id"]),
                reporter_id=r.get("reporter_id", ""),
                reporter_name=r.get("reporter_name", ""),
                reported_user_id=r.get("reported_user_id", ""),
                reported_user_name=r.get("reported_user_name", ""),
                reason=r.get("reason", ""),
                description=r.get("description", ""),
                status=r.get("status", "pending"),
                created_at=str(r.get("created_at", "")),
            ))

        return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Reports error: {str(e)}")


@router.post("/reports")
async def create_report(report: Dict[str, Any]):
    """Create a user report."""
    try:
        db = get_database()
        report["created_at"] = datetime.utcnow()
        report["status"] = "pending"
        result = await db["reports"].insert_one(report)
        return {"success": True, "report_id": str(result.inserted_id)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/reports/{report_id}/resolve")
async def resolve_report(report_id: str):
    """Mark a report as resolved."""
    try:
        db = get_database()
        from bson import ObjectId
        await db["reports"].update_one(
            {"_id": ObjectId(report_id)},
            {"$set": {"status": "resolved", "resolved_at": datetime.utcnow()}}
        )
        return {"success": True, "message": "Report resolved"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/category-breakdown", response_model=List[CategoryBreakdown])
async def get_category_breakdown():
    """Get provider count by service type category."""
    try:
        db = get_database()
        pipeline = [
            {"$group": {"_id": "$service_type", "count": {"$sum": 1}}},
            {"$sort": {"count": -1}},
        ]
        cursor = db[mongodb.SERVICE_PROVIDER_PROFILES].aggregate(pipeline)
        results = await cursor.to_list(length=50)
        return [CategoryBreakdown(category=r["_id"] or "Unknown", count=r["count"]) for r in results]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/recent-users")
async def get_recent_users(limit: int = Query(10, ge=1, le=50)):
    """Get most recent user signups."""
    try:
        db = get_database()
        cursor = db[mongodb.USERS].find(
            {}, {"password_hash": 0}
        ).sort("created_at", -1).limit(limit)
        users = await cursor.to_list(length=limit)
        for u in users:
            u["_id"] = str(u["_id"])
        return users
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
