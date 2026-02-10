"""
Pydantic schemas for request/response validation
"""

from .itinerary import (
    TripType,
    SafetyLevel,
    ItineraryStatus,
    AccessibilityRequirement,
    ItineraryGenerationRequest,
    ItineraryResponse,
    ItineraryApprovalRequest,
    SafetyValidationResponse,
    ActivityResponse
)

__all__ = [
    "TripType",
    "SafetyLevel",
    "ItineraryStatus",
    "AccessibilityRequirement",
    "ItineraryGenerationRequest",
    "ItineraryResponse",
    "ItineraryApprovalRequest",
    "SafetyValidationResponse",
    "ActivityResponse"
]