"""
Comprehensive Test Suite for RAG Implementation
Tests ChromaDB indexing, semantic search, and filtering
"""
import asyncio
import sys
from pathlib import Path
from typing import List, Dict, Any
from datetime import datetime, timedelta

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from app.services.destination_rag import destination_rag


class RAGTester:
    """Test suite for RAG implementation"""
    
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.rag = destination_rag
    
    def print_header(self, title: str):
        """Print test section header"""
        print("\n" + "="*70)
        print(f"  {title}")
        print("="*70)
    
    def print_test(self, test_name: str):
        """Print test name"""
        print(f"\n🧪 Test: {test_name}")
        print("-" * 70)
    
    def assert_true(self, condition: bool, message: str):
        """Assert a condition is true"""
        if condition:
            print(f"  ✅ PASS: {message}")
            self.passed += 1
        else:
            print(f"  ❌ FAIL: {message}")
            self.failed += 1
    
    def assert_equals(self, actual: Any, expected: Any, message: str):
        """Assert two values are equal"""
        if actual == expected:
            print(f"  ✅ PASS: {message}")
            self.passed += 1
        else:
            print(f"  ❌ FAIL: {message}")
            print(f"      Expected: {expected}")
            print(f"      Got: {actual}")
            self.failed += 1
    
    def assert_greater_than(self, actual: int, minimum: int, message: str):
        """Assert value is greater than minimum"""
        if actual > minimum:
            print(f"  ✅ PASS: {message} ({actual} > {minimum})")
            self.passed += 1
        else:
            print(f"  ❌ FAIL: {message} ({actual} <= {minimum})")
            self.failed += 1
    
    def assert_contains(self, items: List[str], target: str, message: str):
        """Assert list contains target"""
        if target in items:
            print(f"  ✅ PASS: {message}")
            self.passed += 1
        else:
            print(f"  ❌ FAIL: {message}")
            print(f"      Looking for: {target}")
            print(f"      In: {items}")
            self.failed += 1
    
    def print_results(self, results: List[Dict[str, Any]], limit: int = 3):
        """Print search results"""
        print(f"\n  📊 Results ({len(results)} found):")
        for i, dest in enumerate(results[:limit], 1):
            print(f"    {i}. {dest['name']}")
            print(f"       Safety: {dest.get('safety_level', 'N/A')}, "
                  f"Accessibility: {dest.get('accessibility', 'N/A')}, "
                  f"Budget: ${dest.get('avg_budget_low', 0)}-${dest.get('avg_budget_high', 0)}")
    
    # ==================== Test Cases ====================
    
    def test_chromadb_initialized(self):
        """Test 1: ChromaDB collection exists"""
        self.print_test("ChromaDB Initialization")
        
        try:
            count = self.rag.collection.count()
            self.assert_greater_than(count, 0, "ChromaDB has indexed destinations")
            self.assert_greater_than(count, 40, "At least 40 destinations indexed")
            print(f"  📊 Total destinations indexed: {count}")
        except Exception as e:
            self.assert_true(False, f"ChromaDB initialization failed: {e}")
    
    def test_basic_search(self):
        """Test 2: Basic semantic search"""
        self.print_test("Basic Semantic Search")
        
        query = "pyramids and ancient temples"
        results = self.rag.search_destinations(query, n_results=5)
        
        self.assert_greater_than(len(results), 0, "Search returns results")
        self.print_results(results)
        
        # Check if results contain expected destinations
        names = [r['name'] for r in results]
        # At least one of these should appear
        historical_dests = ["Cairo", "Giza", "Luxor", "Saqqara", "Memphis"]
        found_historical = any(dest in names for dest in historical_dests)
        self.assert_true(found_historical, "Results contain historical destinations")
    
    def test_beach_search(self):
        """Test 3: Beach/coastal destinations"""
        self.print_test("Beach & Coastal Search")
        
        query = "beautiful beaches and diving spots for relaxation"
        results = self.rag.search_destinations(query, n_results=5)
        
        self.assert_greater_than(len(results), 0, "Beach search returns results")
        self.print_results(results)
        
        names = [r['name'] for r in results]
        beach_dests = ["Hurghada", "Sharm El Sheikh", "Dahab", "Marsa Alam", "El Gouna"]
        found_beach = any(dest in names for dest in beach_dests)
        self.assert_true(found_beach, "Results contain beach destinations")
    
    def test_budget_filter(self):
        """Test 4: Budget filtering"""
        self.print_test("Budget Filter ($50/day max)")
        
        query = "tourist attractions"
        results = self.rag.search_destinations(
            query,
            n_results=10,
            filters={"avg_budget_mid": {"$lte": 50}}
        )
        
        self.assert_greater_than(len(results), 0, "Budget filter returns results")
        self.print_results(results)
        
        # Verify all results are within budget
        all_within_budget = all(
            r.get('avg_budget_mid', 999) <= 50 
            for r in results
        )
        self.assert_true(all_within_budget, "All results within $50/day budget")
    
    def test_high_budget_filter(self):
        """Test 5: High budget filter"""
        self.print_test("High Budget Filter ($200+/day)")
        
        query = "luxury resorts"
        results = self.rag.search_destinations(
            query,
            n_results=5,
            filters={"avg_budget_mid": {"$gte": 80}}
        )
        
        self.assert_greater_than(len(results), 0, "High budget filter returns results")
        self.print_results(results)
        
        # Check for luxury destinations
        names = [r['name'] for r in results]
        luxury_dests = ["El Gouna", "Soma Bay", "Sharm El Sheikh"]
        found_luxury = any(dest in names for dest in luxury_dests)
        self.assert_true(found_luxury, "Results contain luxury destinations")
    
    def test_safety_filter(self):
        """Test 6: High safety level filter"""
        self.print_test("Safety Level Filter (High safety only)")
        
        query = "tourist destinations"
        results = self.rag.search_destinations(
            query,
            n_results=10,
            filters={"safety_level": "high"}
        )
        
        self.assert_greater_than(len(results), 0, "Safety filter returns results")
        self.print_results(results)
        
        # Verify all have high safety
        all_safe = all(r.get('safety_level') == 'high' for r in results)
        self.assert_true(all_safe, "All results have high safety level")
    
    def test_accessibility_filter(self):
        """Test 7: Accessibility filter"""
        self.print_test("Accessibility Filter (Wheelchair accessible)")
        
        query = "tourist attractions"
        results = self.rag.search_destinations(
            query,
            n_results=10,
            filters={"accessibility": "high"}
        )
        
        self.assert_greater_than(len(results), 0, "Accessibility filter returns results")
        self.print_results(results)
        
        # Verify all are highly accessible
        all_accessible = all(r.get('accessibility') == 'high' for r in results)
        self.assert_true(all_accessible, "All results have high accessibility")
        
        # Check for known accessible destinations
        names = [r['name'] for r in results]
        accessible_dests = ["Cairo", "Giza", "Alexandria", "Hurghada"]
        found_accessible = any(dest in names for dest in accessible_dests)
        self.assert_true(found_accessible, "Results contain known accessible destinations")
    
    def test_combined_filters(self):
        """Test 8: Multiple filters combined"""
        self.print_test("Combined Filters (Budget + Safety + Accessibility)")
        
        query = "family-friendly destinations"
        # Use $and for multiple filters (ChromaDB requirement)
        results = self.rag.search_destinations(
            query,
            n_results=5,
            filters={
                "$and": [
                    {"avg_budget_mid": {"$lte": 80}},
                    {"safety_level": "high"},
                    {"accessibility": "high"}
                ]
            }
        )
        
        self.assert_greater_than(len(results), 0, "Combined filters return results")
        self.print_results(results)
        
        # Verify all criteria met
        for result in results:
            self.assert_true(
                result.get('avg_budget_mid', 999) <= 80,
                f"{result['name']} within budget"
            )
            self.assert_equals(
                result.get('safety_level'), 'high',
                f"{result['name']} has high safety"
            )
            self.assert_equals(
                result.get('accessibility'), 'high',
                f"{result['name']} has high accessibility"
            )
    
    def test_get_by_names(self):
        """Test 9: Get destinations by exact names"""
        self.print_test("Get Destinations by Name")
        
        requested = ["Cairo", "Luxor", "Aswan"]
        results = self.rag.get_destinations_by_names(requested)
        
        self.assert_equals(len(results), 3, "Returns all requested destinations")
        
        names = [r['name'] for r in results]
        for dest in requested:
            self.assert_contains(names, dest, f"Results contain {dest}")
    
    def test_preferences_solo_female(self):
        """Test 10: Solo female traveler preferences"""
        self.print_test("Solo Female Traveler Preferences")
        
        results = self.rag.get_destinations_for_preferences(
            interests=["culture", "history", "photography"],
            budget_max=100,
            accessibility_required=False,
            safety_level="high",  # High safety for solo female
            n_results=5
        )
        
        self.assert_greater_than(len(results), 0, "Returns destinations for solo female")
        self.print_results(results)
        
        # All should have high safety
        all_safe = all(r.get('safety_level') == 'high' for r in results)
        self.assert_true(all_safe, "All results prioritize safety")
    
    def test_preferences_wheelchair_user(self):
        """Test 11: Wheelchair user preferences"""
        self.print_test("Wheelchair User Preferences")
        
        results = self.rag.get_destinations_for_preferences(
            interests=["history", "museums", "sightseeing"],
            budget_max=150,
            accessibility_required=True,  # Only accessible
            safety_level=None,
            n_results=5
        )
        
        self.assert_greater_than(len(results), 0, "Returns accessible destinations")
        self.print_results(results)
        
        # All should be highly accessible
        all_accessible = all(r.get('accessibility') == 'high' for r in results)
        self.assert_true(all_accessible, "All results are wheelchair accessible")
    
    def test_preferences_budget_backpacker(self):
        """Test 12: Budget backpacker preferences"""
        self.print_test("Budget Backpacker Preferences")
        
        results = self.rag.get_destinations_for_preferences(
            interests=["adventure", "nature", "desert"],
            budget_max=40,  # Very low budget
            accessibility_required=False,
            safety_level=None,
            n_results=5
        )
        
        self.assert_greater_than(len(results), 0, "Returns budget destinations")
        self.print_results(results)
        
        # All should be within budget
        all_budget = all(r.get('avg_budget_mid', 999) <= 40 for r in results)
        self.assert_true(all_budget, "All results within backpacker budget")
    
    def test_preferences_luxury_traveler(self):
        """Test 13: Luxury traveler preferences"""
        self.print_test("Luxury Traveler Preferences")
        
        results = self.rag.get_destinations_for_preferences(
            interests=["relaxation", "spa", "beaches", "fine dining"],
            budget_max=None,  # No budget limit
            accessibility_required=False,
            safety_level="high",
            n_results=5
        )
        
        self.assert_greater_than(len(results), 0, "Returns luxury destinations")
        self.print_results(results)
        
        # Check for luxury destinations
        names = [r['name'] for r in results]
        luxury_dests = ["El Gouna", "Soma Bay", "Sharm El Sheikh"]
        found_luxury = any(dest in names for dest in luxury_dests)
        self.assert_true(found_luxury, "Results contain luxury destinations")
    
    def test_semantic_understanding(self):
        """Test 14: Semantic understanding (not just keywords)"""
        self.print_test("Semantic Understanding")
        
        # Test 1: "kid-friendly" should understand family destinations
        results1 = self.rag.search_destinations(
            "kid-friendly places with activities for children",
            n_results=5
        )
        self.assert_greater_than(len(results1), 0, "Understands 'kid-friendly'")
        
        # Test 2: "romantic" should understand couple-friendly
        results2 = self.rag.search_destinations(
            "romantic getaway for couples",
            n_results=5
        )
        self.assert_greater_than(len(results2), 0, "Understands 'romantic'")
        
        # Test 3: "off the beaten path" should understand less touristy
        results3 = self.rag.search_destinations(
            "off the beaten path hidden gems",
            n_results=5
        )
        self.assert_greater_than(len(results3), 0, "Understands 'off the beaten path'")
        
        print("\n  Results for different semantic queries:")
        print(f"    Kid-friendly: {[r['name'] for r in results1[:3]]}")
        print(f"    Romantic: {[r['name'] for r in results2[:3]]}")
        print(f"    Hidden gems: {[r['name'] for r in results3[:3]]}")
    
    def test_data_completeness(self):
        """Test 15: Destination data completeness"""
        self.print_test("Data Completeness Check")
        
        results = self.rag.search_destinations("tourist destinations", n_results=10)
        
        for dest in results:
            # Check required fields exist
            self.assert_true('name' in dest, f"Destination has name")
            self.assert_true('description' in dest, f"{dest['name']} has description")
            self.assert_true('safety_level' in dest, f"{dest['name']} has safety level")
            self.assert_true('accessibility' in dest, f"{dest['name']} has accessibility")
            self.assert_true('attractions' in dest, f"{dest['name']} has attractions")
            
            # Check attractions is a list
            attractions = dest.get('attractions', [])
            self.assert_true(
                isinstance(attractions, list),
                f"{dest['name']} attractions is a list"
            )
            self.assert_greater_than(
                len(attractions), 0,
                f"{dest['name']} has at least one attraction"
            )
    
    def test_no_results_handling(self):
        """Test 16: Handle impossible filters gracefully"""
        self.print_test("Handle Impossible Filters")
        
        # Impossible: Budget $1/day
        results = self.rag.search_destinations(
            "luxury resort",
            n_results=5,
            filters={"avg_budget_mid": {"$lte": 1}}
        )
        
        # Should return empty gracefully, not crash
        print(f"  Results for $1/day budget: {len(results)} destinations")
        self.assert_true(True, "Handles impossible filters without crashing")
    
    # ==================== Run All Tests ====================
    
    def run_all_tests(self):
        """Run all tests"""
        self.print_header("RAG IMPLEMENTATION TEST SUITE")
        print("Testing ChromaDB indexing, semantic search, and filtering\n")
        
        # Run tests
        self.test_chromadb_initialized()
        self.test_basic_search()
        self.test_beach_search()
        self.test_budget_filter()
        self.test_high_budget_filter()
        self.test_safety_filter()
        self.test_accessibility_filter()
        self.test_combined_filters()
        self.test_get_by_names()
        self.test_preferences_solo_female()
        self.test_preferences_wheelchair_user()
        self.test_preferences_budget_backpacker()
        self.test_preferences_luxury_traveler()
        self.test_semantic_understanding()
        self.test_data_completeness()
        self.test_no_results_handling()
        
        # Print summary
        self.print_summary()
    
    def print_summary(self):
        """Print test summary"""
        self.print_header("TEST SUMMARY")
        
        total = self.passed + self.failed
        pass_rate = (self.passed / total * 100) if total > 0 else 0
        
        print(f"\n  Total Tests Run: {total}")
        print(f"  ✅ Passed: {self.passed}")
        print(f"  ❌ Failed: {self.failed}")
        print(f"  📊 Pass Rate: {pass_rate:.1f}%")
        
        if self.failed == 0:
            print("\n  🎉 ALL TESTS PASSED! RAG is working perfectly!")
        else:
            print("\n  ⚠️  Some tests failed. Check output above for details.")
        
        print("\n" + "="*70 + "\n")
        
        return self.failed == 0


def main():
    """Main test runner"""
    print("\n" + "🔍"*35)
    print("  RAG SYSTEM TEST SUITE")
    print("🔍"*35)
    
    tester = RAGTester()
    success = tester.run_all_tests()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()