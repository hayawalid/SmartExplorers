"""
Service Management API for SmartExplorers

Endpoints for:
1. Service providers to create, update, delete their services
2. Users to discover services based on cluster, preferences, and location
"""

from fastapi import APIRouter, HTTPException, Query, Depends
from typing import Dict, Any, Optional, List
from bson import ObjectId
from datetime import datetime
from math import radians, sin, cos, sqrt, atan2

from app.mongodb import get_database, mongodb
from app.models.mongodb_models import ServiceModel, ServiceAvailabilityModel

router = APIRouter(prefix="/api/v1/services", tags=["services"])


def _serialize(doc: Dict[str, Any]) -> Dict[str, Any]:
    """Convert MongoDB document to JSON-serializable format"""
    if not doc:
        return doc
    doc["_id"] = str(doc["_id"])
    return doc


def _validate_provider_ownership(provider_id: str, service_data: Dict[str, Any]) -> bool:
    """Validate that provider_id matches the service provider"""
    return service_data.get("provider_id") == provider_id


def _calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate distance between two coordinates in kilometers
    Using Haversine formula
    """
    R = 6371  # Earth's radius in kilometers
    
    lat1_rad = radians(lat1)
    lon1_rad = radians(lon1)
    lat2_rad = radians(lat2)
    lon2_rad = radians(lon2)
    
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    
    a = sin(dlat/2)**2 + cos(lat1_rad) * cos(lat2_rad) * sin(dlon/2)**2
    c = 2 * atan2(sqrt(a), sqrt(1-a))
    
    return R * c


# ==================== PROVIDER ENDPOINTS ====================

@router.post("/provider/create")
async def create_service(
    provider_id: str = Query(..., description="Provider's user ID"),
    service: Dict[str, Any] = None
):
    """
    Provider creates a new service
    
    Body should contain:
    - service_type: "tour_guide" | "driver" | "photographer" | "interpreter" | "local_expert"
    - service_name: str
    - description: optional str
    - tags: list of strings
    - cluster_keywords: list of strings for matching
    - price_min: float
    - price_max: float
    - availability: {"days": [...], "hours_start": "HH:MM", "hours_end": "HH:MM"}
    """
    db = get_database()
    
    if not service:
        raise HTTPException(status_code=400, detail="Service data required")
    
    # Validate required fields
    required_fields = ["service_type", "service_name"]
    missing = [f for f in required_fields if f not in service or not service[f]]
    if missing:
        raise HTTPException(status_code=400, detail=f"Missing required fields: {', '.join(missing)}")
    
    # Add provider_id and metadata
    service["provider_id"] = provider_id
    service["is_active"] = True
    service["created_at"] = datetime.utcnow()
    service["updated_at"] = datetime.utcnow()
    
    # Set defaults
    service.setdefault("rating", 0.0)
    service.setdefault("reviews_count", 0)
    service.setdefault("bookings_count", 0)
    service.setdefault("tags", [])
    service.setdefault("cluster_keywords", [])
    service.setdefault("currency", "EGP")
    
    try:
        result = await db[mongodb.SERVICES].insert_one(service)
        
        # Update provider's service count
        await db[mongodb.SERVICE_PROVIDER_PROFILES].update_one(
            {"user_id": provider_id},
            {
                "$inc": {"services_count": 1},
                "$push": {"active_services": str(result.inserted_id)}
            }
        )
        
        # Fetch and return created service
        created_service = await db[mongodb.SERVICES].find_one({"_id": result.inserted_id})
        return _serialize(created_service)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create service: {str(e)}")


@router.put("/provider/{service_id}")
async def update_service(
    service_id: str,
    provider_id: str = Query(..., description="Provider's user ID"),
    update_data: Dict[str, Any] = None
):
    """
    Provider updates their service
    Cannot modify: provider_id, created_at
    """
    db = get_database()
    
    if not ObjectId.is_valid(service_id):
        raise HTTPException(status_code=400, detail="Invalid service_id")
    
    if not update_data:
        raise HTTPException(status_code=400, detail="Update data required")
    
    # Fetch service to verify ownership
    service = await db[mongodb.SERVICES].find_one({"_id": ObjectId(service_id)})
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    
    if service["provider_id"] != provider_id:
        raise HTTPException(status_code=403, detail="Not authorized to update this service")
    
    # Remove immutable fields
    update_data.pop("provider_id", None)
    update_data.pop("created_at", None)
    update_data.pop("_id", None)
    
    # Add update timestamp
    update_data["updated_at"] = datetime.utcnow()
    
    try:
        result = await db[mongodb.SERVICES].update_one(
            {"_id": ObjectId(service_id)},
            {"$set": update_data}
        )
        
        if result.modified_count == 0:
            raise HTTPException(status_code=400, detail="Service not updated")
        
        # Return updated service
        updated_service = await db[mongodb.SERVICES].find_one({"_id": ObjectId(service_id)})
        return _serialize(updated_service)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update service: {str(e)}")


@router.delete("/provider/{service_id}")
async def delete_service(
    service_id: str,
    provider_id: str = Query(..., description="Provider's user ID")
):
    """
    Provider deactivates/deletes their service
    """
    db = get_database()
    
    if not ObjectId.is_valid(service_id):
        raise HTTPException(status_code=400, detail="Invalid service_id")
    
    service = await db[mongodb.SERVICES].find_one({"_id": ObjectId(service_id)})
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    
    if service["provider_id"] != provider_id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this service")
    
    try:
        await db[mongodb.SERVICES].delete_one({"_id": ObjectId(service_id)})
        
        # Update provider's service count
        await db[mongodb.SERVICE_PROVIDER_PROFILES].update_one(
            {"user_id": provider_id},
            {
                "$inc": {"services_count": -1},
                "$pull": {"active_services": service_id}
            }
        )
        
        return {"status": "success", "message": "Service deleted", "service_id": service_id}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete service: {str(e)}")


@router.get("/provider/list")
async def list_provider_services(
    provider_id: str = Query(..., description="Provider's user ID"),
    active_only: bool = Query(True, description="Return only active services")
):
    """
    Provider lists their services
    """
    db = get_database()
    
    query = {"provider_id": provider_id}
    if active_only:
        query["is_active"] = True
    
    try:
        cursor = db[mongodb.SERVICES].find(query).sort("created_at", -1)
        services = [_serialize(doc) async for doc in cursor]
        return {
            "provider_id": provider_id,
            "total_count": len(services),
            "services": services
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch services: {str(e)}")


# ==================== USER DISCOVERY ENDPOINTS ====================

def _geo_distance_expr(lat: float, lng: float):
    """
    Haversine formula in MongoDB aggregation (km)
    """
    return {
        "$multiply": [
            6371,  # Earth radius
            {
                "$acos": {
                    "$add": [
                        {
                            "$multiply": [
                                {
                                    "$sin": {"$degreesToRadians": lat}
                                },
                                {
                                    "$sin": {
                                        "$degreesToRadians": "$provider.latitude"
                                    }
                                }
                            ]
                        },
                        {
                            "$multiply": [
                                {
                                    "$cos": {"$degreesToRadians": lat}
                                },
                                {
                                    "$cos": {
                                        "$degreesToRadians": "$provider.latitude"
                                    }
                                },
                                {
                                    "$cos": {
                                        "$subtract": [
                                            {"$degreesToRadians": lng},
                                            {"$degreesToRadians": "$provider.longitude"}
                                        ]
                                    }
                                }
                            ]
                        }
                    ]
                }
            }
        ]
    }


@router.get("/discover")
async def discover_services(
    user_id: str = Query(...),
    cluster_id: Optional[int] = None,
    service_type: Optional[str] = None,
    tags: Optional[List[str]] = None,
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
    radius_km: float = 50,
    min_rating: float = 0,
    limit: int = 20,
    skip: int = 0
):
    db = get_database()

    try:
        match_stage: Dict[str, Any] = {
            "is_active": True
        }

        if service_type:
            match_stage["service_type"] = service_type

        if tags:
            match_stage["tags"] = {"$in": tags}

        if min_rating > 0:
            match_stage["rating"] = {"$gte": min_rating}

        pipeline = [
            {"$match": match_stage},

            # Join provider profile (NO N+1 queries)
            {
                "$lookup": {
                    "from": mongodb.SERVICE_PROVIDER_PROFILES,
                    "localField": "provider_id",
                    "foreignField": "user_id",
                    "as": "provider"
                }
            },
            {"$unwind": {"path": "$provider", "preserveNullAndEmptyArrays": True}},
        ]

        # Add distance only if coordinates provided
        if latitude is not None and longitude is not None:
            pipeline.append({
                "$addFields": {
                    "distance_km": _geo_distance_expr(latitude, longitude)
                }
            })

            pipeline.append({
                "$match": {
                    "$or": [
                        {"distance_km": {"$lte": radius_km}},
                        {"distance_km": None}
                    ]
                }
            })

        pipeline.extend([
            # Join provider user info
            {
                "$lookup": {
                    "from": mongodb.USERS,
                    "localField": "provider_id",
                    "foreignField": "_id",
                    "as": "user"
                }
            },
            {"$unwind": {"path": "$user", "preserveNullAndEmptyArrays": True}},

            # Shape final output
            {
                "$project": {
                    "_id": 1,
                    "service_type": 1,
                    "tags": 1,
                    "rating": 1,
                    "provider_id": 1,
                    "distance_km": 1,

                    "provider_name": "$user.full_name",
                    "provider_email": "$user.email",

                    "provider_location": {
                        "lat": "$provider.latitude",
                        "lng": "$provider.longitude"
                    }
                }
            },

            # Sort logic (distance preferred if available, else rating)
            {
                "$sort": {
                    "distance_km": 1,
                    "rating": -1
                }
            },

            {"$skip": skip},
            {"$limit": limit}
        ])

        services = await db[mongodb.SERVICES].aggregate(pipeline).to_list(length=limit)

        return {
            "user_id": user_id,
            "total_results": len(services),
            "services": services
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/nearby")
async def get_nearby_services(
    latitude: float = Query(..., description="User latitude"),
    longitude: float = Query(..., description="User longitude"),
    service_type: Optional[str] = Query(None),
    radius_km: float = Query(50, ge=1, le=500),
    limit: int = Query(20, ge=1, le=100)
):
    """
    Get nearby providers sorted by distance
    """
    db = get_database()
    
    try:
        query = {"is_active": True}
        if service_type:
            query["service_type"] = service_type
        
        cursor = db[mongodb.SERVICES].find(query)
        all_services = [_serialize(doc) async for doc in cursor]
        
        nearby_services = []
        
        for service in all_services:
            provider_id = service["provider_id"]
            provider_profile = await db[mongodb.SERVICE_PROVIDER_PROFILES].find_one({
                "user_id": provider_id
            })
            
            if provider_profile and provider_profile.get("latitude") and provider_profile.get("longitude"):
                distance = _calculate_distance(
                    latitude, longitude,
                    provider_profile["latitude"], provider_profile["longitude"]
                )
                
                if distance <= radius_km:
                    service["distance_km"] = round(distance, 2)
                    service["location"] = {
                        "city": provider_profile.get("city"),
                        "governorate": provider_profile.get("governorate")
                    }
                    nearby_services.append(service)
        
        # Sort by distance
        nearby_services.sort(key=lambda x: x["distance_km"])
        
        # Add provider names
        for service in nearby_services[:limit]:
            provider = await db[mongodb.USERS].find_one({
                "_id": ObjectId(service["provider_id"])
            })
            if provider:
                service["provider_name"] = provider.get("full_name", "Unknown")
        
        return {
            "user_location": {"latitude": latitude, "longitude": longitude},
            "radius_km": radius_km,
            "total_found": len(nearby_services),
            "services": nearby_services[:limit]
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Nearby search failed: {str(e)}")


@router.get("/{service_id}")
async def get_service_details(service_id: str):
    """
    Get detailed service information with provider profile
    """
    db = get_database()
    
    if not ObjectId.is_valid(service_id):
        raise HTTPException(status_code=400, detail="Invalid service_id")
    
    try:
        service = await db[mongodb.SERVICES].find_one({"_id": ObjectId(service_id)})
        if not service:
            raise HTTPException(status_code=404, detail="Service not found")
        
        service = _serialize(service)
        
        # Fetch provider profile
        provider = await db[mongodb.USERS].find_one({
            "_id": ObjectId(service["provider_id"])
        })
        provider_profile = await db[mongodb.SERVICE_PROVIDER_PROFILES].find_one({
            "user_id": service["provider_id"]
        })
        
        service["provider"] = {
            "id": service["provider_id"],
            "name": provider_profile.get("full_legal_name") if provider_profile else "Unknown",
            "email": provider.get("email") if provider else "",
            "rating": provider_profile.get("rating", 0.0) if provider_profile else 0.0,
            "review_count": provider_profile.get("review_count", 0) if provider_profile else 0,
            "completed_tours": provider_profile.get("completed_tours_count", 0) if provider_profile else 0,
            "verified": provider_profile.get("verified_flag", False) if provider_profile else False,
            "bio": provider_profile.get("bio") if provider_profile else "",
            "location": {
                "city": provider_profile.get("city") if provider_profile else None,
                "governorate": provider_profile.get("governorate") if provider_profile else None
            }
        }
        
        return service
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch service: {str(e)}")


@router.get("/cluster/{cluster_id}")
async def get_services_by_cluster(
    cluster_id: int,
    service_type: Optional[str] = Query(None),
    tags: Optional[List[str]] = Query(None),
    limit: int = Query(20, ge=1, le=100)
):
    """
    Get all services in a cluster with optional filtering
    """
    db = get_database()
    
    try:
        query = {"is_active": True}
        
        if service_type:
            query["service_type"] = service_type
        
        if tags:
            query["tags"] = {"$in": tags}
        
        cursor = db[mongodb.SERVICES].find(query).sort("rating", -1).limit(limit)
        services = [_serialize(doc) async for doc in cursor]
        
        return {
            "cluster_id": cluster_id,
            "total_services": len(services),
            "services": services
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch cluster services: {str(e)}")
