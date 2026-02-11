"""
Database models for SmartExplorers

Note: Models are imported inside init_db() function to avoid circular imports
"""

# Don't import anything here to avoid circular imports
# Models will be imported in database.py's init_db() function

__all__ = ["Itinerary", "ItineraryActivity", "TripType", "SafetyLevel", "ItineraryStatus", 
           "IdentityVerification", "VerificationAuditLog", "VerificationStatus", "VerificationMethod"]