#!/usr/bin/env python3
"""
Fix .env file - Remove inline comments that break parsing
"""

from pathlib import Path


def fix_env_file():
    """Fix common .env file issues"""
    
    # Find .env file
    env_file = Path(__file__).parent / ".env"
    
    if not env_file.exists():
        print(f"❌ .env file not found at: {env_file}")
        return
    
    print(f"📝 Fixing .env file at: {env_file}")
    
    # Read current content
    with open(env_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Fix the file
    fixed_lines = []
    issues_found = []
    
    for i, line in enumerate(lines, 1):
        original_line = line.rstrip('\n')
        
        # Skip empty lines and pure comments
        if not line.strip() or line.strip().startswith('#'):
            fixed_lines.append(original_line)
            continue
        
        # Check for inline comments (key=value # comment)
        if '=' in line and '#' in line:
            parts = line.split('#', 1)
            key_value = parts[0].strip()
            
            # Only fix if the comment is truly inline (not in the value)
            if '=' in key_value:
                key, value = key_value.split('=', 1)
                key = key.strip()
                value = value.strip()
                
                # Check if this looks like it was supposed to be just key=value
                if key and value:
                    issues_found.append(f"Line {i}: Removed inline comment from {key}")
                    fixed_lines.append(f"{key}={value}")
                    continue
        
        # No issues, keep as is
        fixed_lines.append(original_line)
    
    # Show what will be fixed
    if issues_found:
        print(f"\n🔧 Found {len(issues_found)} issues to fix:")
        for issue in issues_found:
            print(f"  - {issue}")
        
        # Backup original
        backup_file = env_file.with_suffix('.env.backup')
        with open(backup_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join([line.rstrip('\n') for line in lines]))
        print(f"\n💾 Backed up original to: {backup_file}")
        
        # Write fixed version
        with open(env_file, 'w', encoding='utf-8') as f:
            f.write('\n'.join(fixed_lines))
        
        print(f"✅ Fixed .env file!")
    else:
        print("✅ No issues found - .env file is already properly formatted")
    
    # Verify the key can be read
    print("\n🧪 Testing if key can be loaded...")
    
    try:
        from dotenv import load_dotenv
        import os
        
        # Reload environment
        load_dotenv(env_file, override=True)
        
        key = os.getenv('ENCRYPTION_MASTER_KEY')
        
        if key:
            print(f"✅ ENCRYPTION_MASTER_KEY loaded successfully!")
            print(f"   Value: {key[:30]}...")
            
            # Test if it's a valid Fernet key
            from cryptography.fernet import Fernet
            try:
                cipher = Fernet(key.encode() if isinstance(key, str) else key)
                test_text = "test"
                encrypted = cipher.encrypt(test_text.encode())
                decrypted = cipher.decrypt(encrypted).decode()
                
                if decrypted == test_text:
                    print("✅ Encryption key is valid and working!")
                else:
                    print("❌ Encryption test failed")
            except Exception as e:
                print(f"❌ Invalid encryption key: {e}")
        else:
            print("❌ ENCRYPTION_MASTER_KEY still not loading")
            print("\nYour .env file content:")
            with open(env_file, 'r', encoding='utf-8') as f:
                for i, line in enumerate(f, 1):
                    if 'ENCRYPTION' in line.upper():
                        print(f"  Line {i}: {line.rstrip()}")
    
    except Exception as e:
        print(f"❌ Error testing key: {e}")


if __name__ == "__main__":
    fix_env_file()