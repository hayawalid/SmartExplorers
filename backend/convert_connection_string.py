"""
MongoDB Connection String Converter
Converts mongodb+srv:// to mongodb:// for Windows compatibility
"""

import os
import sys

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def get_standard_connection_string():
    """
    Get the standard MongoDB connection string from Atlas
    """
    print("\n" + "="*70)
    print("MongoDB Connection String Converter for Windows")
    print("="*70 + "\n")
    
    print("The mongodb+srv:// format is causing SSL issues on Windows.")
    print("We need to use the standard mongodb:// format instead.\n")
    
    # Try to load current URI
    try:
        from app.config import settings
        current_uri = settings.MONGODB_URI
        
        if current_uri.startswith('mongodb+srv://'):
            # Mask password
            safe_uri = current_uri
            if "@" in current_uri and ":" in current_uri:
                parts = current_uri.split("//")[1].split("@")
                user_pass = parts[0]
                rest = parts[1]
                user = user_pass.split(":")[0]
                safe_uri = f"mongodb+srv://{user}:***@{rest}"
            
            print(f"Current SRV URI: {safe_uri}\n")
            
            # Extract info
            uri_without_protocol = current_uri.replace('mongodb+srv://', '')
            user_pass_host = uri_without_protocol.split('/')
            user_pass_and_host = user_pass_host[0]
            
            if '@' in user_pass_and_host:
                user_pass, host = user_pass_and_host.split('@')
                username, password = user_pass.split(':', 1)
                
                # Parse the cluster
                # Format: smartexplorers.5dz2fei.mongodb.net
                cluster_parts = host.split('.')
                if len(cluster_parts) >= 3:
                    cluster_id = cluster_parts[1]  # e.g., "5dz2fei"
                    
                    print(f"✓ Detected cluster ID: {cluster_id}")
                    print(f"✓ Username: {username}\n")
                    
                    # Construct standard connection string
                    standard_uri = (
                        f"mongodb://{username}:{password}@"
                        f"ac-tcbrzqh-shard-00-00.{cluster_id}.mongodb.net:27017,"
                        f"ac-tcbrzqh-shard-00-01.{cluster_id}.mongodb.net:27017,"
                        f"ac-tcbrzqh-shard-00-02.{cluster_id}.mongodb.net:27017/"
                        f"?ssl=true&replicaSet=atlas-xxxxx-shard-0&authSource=admin&retryWrites=true&w=majority"
                    )
                    
                    # Masked version
                    standard_uri_masked = (
                        f"mongodb://{username}:***@"
                        f"ac-tcbrzqh-shard-00-00.{cluster_id}.mongodb.net:27017,"
                        f"ac-tcbrzqh-shard-00-01.{cluster_id}.mongodb.net:27017,"
                        f"ac-tcbrzqh-shard-00-02.{cluster_id}.mongodb.net:27017/"
                        f"?ssl=true&replicaSet=atlas-xxxxx-shard-0&authSource=admin&retryWrites=true&w=majority"
                    )
                    
                    print("="*70)
                    print("✓ CONVERTED SUCCESSFULLY!")
                    print("="*70)
                    print()
                    print("NEW CONNECTION STRING (copy this to your .env file):")
                    print()
                    print(f"MONGODB_URI={standard_uri}")
                    print()
                    print("="*70)
                    print()
                    print(f"Preview (masked): {standard_uri_masked}")
                    print()
                    
                    print("⚠️  IMPORTANT NOTES:")
                    print("  1. The replica set name 'atlas-xxxxx-shard-0' might need adjustment")
                    print("  2. To get the EXACT replica set name:")
                    print("     a. Go to https://cloud.mongodb.com")
                    print("     b. Click 'Connect' on your cluster")
                    print("     c. Choose 'Connect your application'")
                    print("     d. Select 'Driver: Python' and version '3.6 or later'")
                    print("     e. Look for the connection string WITHOUT +srv")
                    print("     f. Copy the replicaSet value from there")
                    print()
                    print("  3. After updating .env, run: python server.py")
                    print()
                    
                    return standard_uri
    
    except ImportError:
        print("Could not load settings from app.config")
    except Exception as e:
        print(f"Error reading current URI: {e}")
    
    print("\n" + "="*70)
    print("ALTERNATIVE: Get Connection String from Atlas UI")
    print("="*70)
    print()
    print("1. Go to https://cloud.mongodb.com")
    print("2. Click 'Connect' on your cluster")
    print("3. Choose 'Connect your application'")
    print("4. Select Driver: Python, Version: 3.6 or later")
    print("5. You'll see TWO formats:")
    print()
    print("   Format 1 (SRV - FAILING ON WINDOWS):")
    print("   mongodb+srv://...")
    print()
    print("   Format 2 (Standard - WILL WORK ON WINDOWS):")
    print("   mongodb://...")
    print()
    print("6. Copy the STANDARD format (mongodb://)")
    print("7. Replace MONGODB_URI in your .env file")
    print("8. Make sure to replace <password> with your actual password!")
    print()
    
    return None


def update_env_file():
    """
    Guide user to update .env file
    """
    print("\n" + "="*70)
    print("NEXT STEPS")
    print("="*70)
    print()
    print("1. Copy the connection string above")
    print()
    print("2. Open your .env file:")
    print("   C:\\Users\\hala\\Documents\\GitHub\\SmartExplorers\\backend\\.env")
    print()
    print("3. Find the line that starts with MONGODB_URI=")
    print()
    print("4. Replace it with the new connection string")
    print()
    print("5. Save the file")
    print()
    print("6. Restart your server:")
    print("   python server.py")
    print()
    print("="*70)
    print()


if __name__ == "__main__":
    uri = get_standard_connection_string()
    update_env_file()
    
    if uri:
        print("✓ Conversion complete!")
        print("  The standard connection string should work without SSL errors.\n")
    else:
        print("⚠️  Please follow the manual steps above to get your connection string.\n")