#!/usr/bin/env python3
"""
Database Verification Script
Checks that all tables were created successfully
"""
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from sqlalchemy import inspect
from app.database import engine
from app.config import settings

def main():
    print("\n" + "=" * 80)
    print("  SmartExplorers - Database Verification")
    print("=" * 80 + "\n")
    
    # Check database connection
    print(f"📊 Database: {settings.DATABASE_URL}\n")
    
    try:
        # Get inspector
        inspector = inspect(engine)
        
        # Get all tables
        tables = inspector.get_table_names()
        
        print(f"✅ Successfully connected to database")
        print(f"📋 Found {len(tables)} tables:\n")
        
        for table in sorted(tables):
            print(f"   ✓ {table}")
            
            # Get columns for each table
            columns = inspector.get_columns(table)
            print(f"     Columns: {len(columns)}")
            
            # Show first few column names
            col_names = [col['name'] for col in columns[:5]]
            if len(columns) > 5:
                col_names.append(f"... +{len(columns)-5} more")
            print(f"     {', '.join(col_names)}")
            print()
        
        print("=" * 80)
        print("  ✅ Database is properly configured!")
        print("=" * 80)
        
        print("\n🎯 Next Steps:\n")
        print("1. Start the backend server:")
        print("   python server.py")
        print("\n2. Test the API:")
        print("   http://localhost:8000/docs")
        print("\n3. Test itinerary generation:")
        print("   python test_itinerary_generation.py")
        print("\n4. Test travel spaces:")
        print("   python test_travel_spaces.py")
        
        print("\n" + "=" * 80 + "\n")
        
        return True
        
    except Exception as e:
        print(f"❌ Database Error: {e}")
        print("\nTry running:")
        print("   python -m alembic upgrade head")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)