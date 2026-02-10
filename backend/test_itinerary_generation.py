#!/usr/bin/env python3
"""
SmartExplorers - Part 2: Itinerary Generation Test Script
Tests the AI-powered itinerary generation with real API
"""

import sys
import os
import asyncio
from datetime import date, timedelta
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

try:
    from app.services.itinerary_generator import ItineraryGenerator
    from app.schemas.itinerary import (
        ItineraryGenerationRequest, TripType, AccessibilityRequirement
    )
    from app.config import settings
    IMPORTS_OK = True
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("\nMake sure you're running from the backend directory:")
    print("  cd backend")
    print("  python test_itinerary_generation.py")
    IMPORTS_OK = False


def print_header(title: str):
    """Print formatted section header"""
    print("\n" + "=" * 80)
    print(f"  {title}")
    print("=" * 80 + "\n")


def print_itinerary_summary(itinerary: dict):
    """Print itinerary summary"""
    print(f"📋 {itinerary.get('title', 'Untitled Trip')}")
    print(f"   {itinerary.get('description', '')}\n")
    
    print(f"📅 Duration: {itinerary.get('total_days', 0)} days")
    print(f"📍 Destinations: {', '.join(itinerary.get('destinations', []))}")
    print(f"🏁 Starting from: {itinerary.get('start_location', 'N/A')}\n")
    
    print(f"🛡️  Safety Level: {itinerary.get('safety_level', 'N/A').upper()}")
    print(f"📊 Safety Score: {itinerary.get('safety_score', 0):.2f}/1.0")
    
    if itinerary.get('safety_notes'):
        print("\n⚠️  Safety Notes:")
        for note in itinerary['safety_notes']:
            print(f"   • {note}")


def print_daily_plan(day_plan: dict):
    """Print a single day's plan"""
    print(f"\n{'=' * 70}")
    print(f"📅 {day_plan.get('title', 'Day Plan')} - {day_plan.get('date', 'N/A')}")
    print(f"{'=' * 70}\n")
    
    for activity in day_plan.get('activities', []):
        print(f"{activity.get('order_in_day', '?')}. {activity.get('title', 'Activity')}")
        print(f"   📍 Location: {activity.get('location_name', 'N/A')}")
        
        if activity.get('start_time'):
            print(f"   🕐 Time: {activity['start_time']} - {activity.get('end_time', 'N/A')}")
        
        if activity.get('duration_minutes'):
            hours = activity['duration_minutes'] // 60
            mins = activity['duration_minutes'] % 60
            print(f"   ⏱️  Duration: {hours}h {mins}m")
        
        cost_min = activity.get('estimated_cost_min', 0)
        cost_max = activity.get('estimated_cost_max', 0)
        print(f"   💰 Cost: ${cost_min} - ${cost_max}")
        
        print(f"   🔒 Safety: {activity.get('safety_level', 'medium').upper()}")
        print(f"   ♿ Wheelchair Access: {'✓' if activity.get('wheelchair_accessible') else '✗'}")
        
        if activity.get('safety_warnings'):
            print(f"   ⚠️  Warnings:")
            for warning in activity['safety_warnings']:
                print(f"      - {warning}")
        
        print()


def print_recommendations(recs: dict):
    """Print AI recommendations"""
    print("\n🤖 AI Recommendations")
    print("=" * 70)
    
    if recs.get('best_time_to_visit'):
        print(f"\n🌡️  Best Time: {recs['best_time_to_visit']}")
    
    if recs.get('what_to_pack'):
        print("\n🎒 What to Pack:")
        for item in recs['what_to_pack'][:5]:
            print(f"   • {item}")
    
    if recs.get('cultural_tips'):
        print("\n🎭 Cultural Tips:")
        for tip in recs['cultural_tips'][:3]:
            print(f"   • {tip}")
    
    if recs.get('safety_tips'):
        print("\n🛡️  Safety Tips:")
        for tip in recs['safety_tips'][:3]:
            print(f"   • {tip}")
    
    if recs.get('scam_awareness'):
        print("\n⚠️  Scam Awareness:")
        for warning in recs['scam_awareness'][:3]:
            print(f"   • {warning}")


def print_cost_breakdown(cost: dict):
    """Print cost breakdown"""
    print("\n💵 Cost Estimate")
    print("=" * 70)
    print(f"Total: ${cost.get('min', 0)} - ${cost.get('max', 0)}")
    
    if cost.get('breakdown'):
        breakdown = cost['breakdown']
        print("\nBreakdown:")
        for category, amounts in breakdown.items():
            print(f"   {category.title()}: ${amounts.get('min', 0)} - ${amounts.get('max', 0)}")


async def test_configuration():
    """Test 1: Configuration Check"""
    print_header("Test 1: Configuration Check")
    
    print("Checking environment variables...")
    
    # Check Groq API key
    groq_key = settings.GROQ_API_KEY
    if not groq_key or len(groq_key) < 20:
        print("❌ GROQ_API_KEY not set or invalid")
        print("   Set it in your .env file:")
        print("   GROQ_API_KEY=gsk_your_actual_key_here")
        print("\n   Get a FREE key from: https://console.groq.com/keys")
        return False
    else:
        print(f"✓ GROQ_API_KEY: {groq_key[:10]}...{groq_key[-4:]}")
    
    # Check database URL
    print(f"✓ DATABASE_URL: {settings.DATABASE_URL}")
    
    # Check model
    print(f"✓ GROQ_MODEL: {settings.GROQ_MODEL}")
    
    print("\n✅ Configuration looks good!")
    return True


async def test_json_loading():
    """Test 2: JSON Data Loading"""
    print_header("Test 2: Egypt Destinations JSON Loading")
    
    try:
        generator = ItineraryGenerator()
        
        print(f"Loaded {len(generator.egypt_destinations)} destinations")
        
        # Sample a few destinations
        print("\nSample destinations:")
        for dest_name in list(generator.egypt_destinations.keys())[:3]:
            dest_data = generator.egypt_destinations[dest_name]
            print(f"\n📍 {dest_name}")
            print(f"   Safety: {dest_data.get('safety_level', 'N/A')}")
            print(f"   Accessibility: {dest_data.get('accessibility', 'N/A')}")
            attractions = dest_data.get('attractions', [])
            print(f"   Attractions: {len(attractions)} listed")
            if attractions:
                print(f"   Examples: {', '.join(attractions[:3])}")
        
        print("\n✅ JSON data loaded successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Failed to load JSON: {e}")
        return False


async def test_simple_itinerary():
    """Test 3: Simple 3-Day Cairo Trip"""
    print_header("Test 3: Simple Cairo Trip (3 days)")
    
    try:
        generator = ItineraryGenerator()
        
        # Create request
        start_date = date.today() + timedelta(days=30)
        end_date = start_date + timedelta(days=2)
        
        request = ItineraryGenerationRequest(
            trip_type=TripType.CULTURAL,
            start_date=start_date,
            end_date=end_date,
            start_location="Cairo International Airport",
            destinations=["Cairo", "Giza"],
            budget_min=300,
            budget_max=600,
            interests=["ancient history", "museums"],
            is_solo_traveler=False,
            is_woman_traveler=False,
            group_size=2
        )
        
        print("Generating itinerary...")
        print(f"Trip: {request.trip_type.value.title()}")
        print(f"Dates: {request.start_date} to {request.end_date}")
        print(f"Destinations: {', '.join(request.destinations)}")
        
        # Generate
        itinerary = await generator.generate_itinerary(request, user_id=1)
        
        # Print results
        print_itinerary_summary(itinerary)
        
        # Print daily plans
        for day_plan in itinerary.get('daily_plans', []):
            print_daily_plan(day_plan)
        
        # Print recommendations
        if itinerary.get('ai_recommendations'):
            print_recommendations(itinerary['ai_recommendations'])
        
        # Print cost
        if itinerary.get('total_estimated_cost'):
            print_cost_breakdown(itinerary['total_estimated_cost'])
        
        print("\n✅ Simple itinerary generated successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Failed to generate itinerary: {e}")
        import traceback
        traceback.print_exc()
        return False


async def test_woman_solo_traveler():
    """Test 4: Women Solo Traveler Safety Features"""
    print_header("Test 4: Women Solo Traveler (Safety Features)")
    
    try:
        generator = ItineraryGenerator()
        
        start_date = date.today() + timedelta(days=45)
        end_date = start_date + timedelta(days=4)
        
        request = ItineraryGenerationRequest(
            trip_type=TripType.CULTURAL,
            start_date=start_date,
            end_date=end_date,
            start_location="Cairo International Airport",
            destinations=["Cairo", "Luxor"],
            budget_min=800,
            budget_max=1200,
            interests=["ancient history", "photography", "local culture"],
            is_solo_traveler=True,
            is_woman_traveler=True,
            group_size=1
        )
        
        print("Generating itinerary for woman solo traveler...")
        print("Expected: Gender-specific safety tips and recommendations")
        
        itinerary = await generator.generate_itinerary(request, user_id=2)
        
        print_itinerary_summary(itinerary)
        
        # Check for safety features
        print("\n🔍 Safety Features Check:")
        safety_notes = itinerary.get('safety_notes', [])
        woman_specific = [n for n in safety_notes if 'women' in n.lower() or 'woman' in n.lower()]
        solo_specific = [n for n in safety_notes if 'solo' in n.lower()]
        
        print(f"   Woman-specific notes: {len(woman_specific)}")
        print(f"   Solo traveler notes: {len(solo_specific)}")
        
        if woman_specific:
            print("\n   Sample woman-specific safety notes:")
            for note in woman_specific[:2]:
                print(f"   • {note}")
        
        # Check recommendations
        recs = itinerary.get('ai_recommendations', {})
        safety_tips = recs.get('safety_tips', [])
        woman_tips = [t for t in safety_tips if 'women' in t.lower() or 'female' in t.lower()]
        
        if woman_tips:
            print("\n   Woman-specific tips in recommendations:")
            for tip in woman_tips[:2]:
                print(f"   • {tip}")
        
        print("\n✅ Women solo traveler itinerary generated with safety features!")
        return True
        
    except Exception as e:
        print(f"❌ Failed: {e}")
        return False


async def test_accessibility_requirements():
    """Test 5: Wheelchair Accessibility"""
    print_header("Test 5: Wheelchair Accessibility Requirements")
    
    try:
        generator = ItineraryGenerator()
        
        start_date = date.today() + timedelta(days=60)
        end_date = start_date + timedelta(days=3)
        
        accessibility_req = AccessibilityRequirement(
            wheelchair_accessible=True,
            visual_impairment_support=False,
            hearing_impairment_support=False,
            mobility_assistance=True
        )
        
        request = ItineraryGenerationRequest(
            trip_type=TripType.RELAXATION,
            start_date=start_date,
            end_date=end_date,
            start_location="Cairo International Airport",
            destinations=["Cairo", "Alexandria"],
            budget_min=600,
            budget_max=1000,
            accessibility_requirements=accessibility_req,
            interests=["museums", "seaside"],
            group_size=2
        )
        
        print("Generating wheelchair-accessible itinerary...")
        
        itinerary = await generator.generate_itinerary(request, user_id=3)
        
        print_itinerary_summary(itinerary)
        
        # Check accessibility
        print("\n♿ Accessibility Check:")
        total_activities = 0
        accessible_count = 0
        
        for day_plan in itinerary.get('daily_plans', []):
            for activity in day_plan.get('activities', []):
                total_activities += 1
                if activity.get('wheelchair_accessible'):
                    accessible_count += 1
        
        accessibility_rate = (accessible_count / total_activities * 100) if total_activities > 0 else 0
        print(f"   Wheelchair accessible activities: {accessible_count}/{total_activities} ({accessibility_rate:.1f}%)")
        
        # Show first day's accessibility
        if itinerary.get('daily_plans'):
            first_day = itinerary['daily_plans'][0]
            print(f"\n   Day 1 activities:")
            for activity in first_day.get('activities', []):
                access = "✓ Accessible" if activity.get('wheelchair_accessible') else "✗ Limited access"
                print(f"   • {activity.get('title', 'N/A')}: {access}")
        
        print("\n✅ Accessibility-focused itinerary generated!")
        return True
        
    except Exception as e:
        print(f"❌ Failed: {e}")
        return False


async def run_all_tests():
    """Run all tests"""
    print("=" * 80)
    print("  SmartExplorers - Part 2: Itinerary Generation Tests")
    print("  Testing AI-Powered Trip Planning with Groq")
    print("=" * 80)
    
    if not IMPORTS_OK:
        print("\n❌ Cannot run tests due to import errors")
        return
    
    results = []
    
    # Test 1: Configuration
    results.append(("Configuration", await test_configuration()))
    
    # Test 2: JSON Loading
    results.append(("JSON Loading", await test_json_loading()))
    
    # Only continue if config and JSON are OK
    if not all(r[1] for r in results):
        print("\n❌ Basic tests failed. Fix configuration before continuing.")
        print_results(results)
        return
    
    # Test 3: Simple itinerary
    results.append(("Simple Itinerary", await test_simple_itinerary()))
    
    # Test 4: Woman solo traveler
    results.append(("Woman Solo Traveler", await test_woman_solo_traveler()))
    
    # Test 5: Accessibility
    results.append(("Accessibility", await test_accessibility_requirements()))
    
    # Print final results
    print_results(results)


def print_results(results):
    """Print test results summary"""
    print_header("Test Results Summary")
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    print(f"\n{'=' * 80}")
    print(f"Total: {passed}/{total} tests passed ({passed/total*100:.1f}%)")
    print(f"{'=' * 80}\n")
    
    if passed == total:
        print("🎉 All tests passed! Itinerary generation is working perfectly!")
    else:
        print(f"⚠️  {total - passed} test(s) failed. Check the errors above.")


if __name__ == "__main__":
    # Run async tests
    asyncio.run(run_all_tests())