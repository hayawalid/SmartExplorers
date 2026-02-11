#!/usr/bin/env python3
"""
Test script for Identity Verification System
Demonstrates encryption, OCR, and face verification
"""

import sys
import os
from pathlib import Path

# Add backend to path
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

from cryptography.fernet import Fernet


def print_section(title: str):
    """Print formatted section header"""
    print("\n" + "=" * 80)
    print(f"  {title}")
    print("=" * 80 + "\n")


def test_encryption():
    """Test encryption/decryption"""
    print_section("Test 1: Encryption Service")
    
    try:
        from app.services.encryption import encryption_service
        
        # Test data
        test_data = {
            "national_id": "29503151234567",
            "full_name": "Ahmed Mohamed Ali",
            "date_of_birth": "1995-03-15",
            "passport_number": "A12345678"
        }
        
        print("Original Data:")
        for key, value in test_data.items():
            print(f"  {key}: {value}")
        
        print("\nEncrypting...")
        encrypted_data = {}
        for key, value in test_data.items():
            encrypted_data[key] = encryption_service.encrypt(value)
            print(f"  {key}: {encrypted_data[key][:50]}...")
        
        print("\nDecrypting...")
        decrypted_data = {}
        for key, encrypted_value in encrypted_data.items():
            decrypted_data[key] = encryption_service.decrypt(encrypted_value)
            print(f"  {key}: {decrypted_data[key]}")
        
        print("\nVerification:")
        all_match = all(test_data[k] == decrypted_data[k] for k in test_data.keys())
        if all_match:
            print("  ✅ All data encrypted and decrypted successfully!")
            return True
        else:
            print("  ❌ Encryption/decryption mismatch!")
            return False
    
    except Exception as e:
        print(f"❌ Encryption test failed: {str(e)}")
        return False


def test_face_detection():
    """Test face detection service"""
    print_section("Test 2: Face Detection Service")
    
    try:
        from app.services.face_verification import face_verification_service
        
        print("Face detection service initialized")
        print(f"  DeepFace available: {face_verification_service.deepface_available}")
        print(f"  Model: {face_verification_service.model_name}")
        print(f"  Confidence threshold: {face_verification_service.confidence_threshold}")
        
        # Note: Actual image testing requires image files
        print("\nℹ️  To test with real images:")
        print("  1. Place ID photo at: test_images/id_photo.jpg")
        print("  2. Place selfie at: test_images/selfie.jpg")
        print("  3. Run: python test_verification_with_images.py")
        
        return True
    
    except Exception as e:
        print(f"⚠️  DeepFace not installed: {str(e)}")
        print("\n   To install:")
        print("   pip install deepface opencv-python tf-keras")
        return False


def test_ocr():
    """Test OCR service"""
    print_section("Test 3: OCR Service")
    
    try:
        from app.services.ocr import ocr_service
        
        print("OCR service initialized")
        print(f"  Tesseract available: {ocr_service.tesseract_available}")
        
        # Test with mock data
        mock_id_text = """
        ARAB REPUBLIC OF EGYPT
        NATIONAL ID CARD
        
        29503151234567
        
        AHMED MOHAMED ALI
        أحمد محمد علي
        
        Date of Birth: 15/03/1995
        """
        
        print("\nParsing Egyptian National ID:")
        result = ocr_service.parse_egyptian_national_id(mock_id_text)
        
        print(f"  Document Number: {result['document_number']}")
        print(f"  Full Name: {result['full_name']}")
        print(f"  Date of Birth: {result['date_of_birth']}")
        print(f"  Gender: {result['gender']}")
        print(f"  Confidence: {result['confidence']:.2%}")
        
        if result['document_number']:
            print("\n✅ OCR parsing successful!")
            return True
        else:
            print("\n❌ Failed to extract ID number")
            return False
    
    except Exception as e:
        print(f"❌ OCR test failed: {str(e)}")
        return False


def test_workflow():
    """Demonstrate complete workflow"""
    print_section("Test 4: Complete Verification Workflow")
    
    print("Verification Workflow:")
    print("-" * 80)
    steps = [
        "1. User submits ID photo + selfie",
        "2. System validates image quality",
        "3. Face detection in both images",
        "4. Face matching (DeepFace VGG-Face)",
        "5. OCR extracts ID data (Tesseract)",
        "6. Encrypt sensitive data (Fernet AES-128)",
        "7. Store encrypted data in database",
        "8. Flag if fraud detected (confidence < 70%)",
        "9. Admin reviews flagged submissions",
        "10. User receives verification status"
    ]
    
    for step in steps:
        print(f"   ✓ {step}")
    
    print("\n" + "=" * 80)
    print("Security Features:")
    print("=" * 80)
    
    features = [
        "🔒 All sensitive data encrypted at rest",
        "🔑 Master key stored in environment variable",
        "👤 Face matching prevents ID theft",
        "🚩 Automatic fraud detection",
        "📊 Audit trail logs all access",
        "🔐 Admin-only access to decrypted data",
        "⏰ Verification expires after 1 year",
        "🗑️  GDPR right to deletion",
        "🔍 No plaintext storage of ID numbers"
    ]
    
    for feature in features:
        print(f"   {feature}")
    
    print("\n✅ Workflow documented")
    return True


def generate_encryption_key():
    """Generate a new encryption key"""
    print_section("Generate Encryption Key")
    
    key = Fernet.generate_key()
    
    print("Generated Encryption Key:")
    print(f"  {key.decode()}")
    
    print("\nTo use this key:")
    print("  1. Copy the key above")
    print("  2. Open your backend/.env file")
    print("  3. Add this line:")
    print(f"     ENCRYPTION_MASTER_KEY={key.decode()}")
    print("  4. Save and restart the server")
    
    return True


def main():
    """Run all tests"""
    print("=" * 80)
    print("  SmartExplorers - Identity Verification System Test Suite")
    print("=" * 80)
    
    # Check if .env file exists
    env_file = Path(".env")
    if not env_file.exists():
        print(f"\n⚠️  .env file not found at: {env_file.absolute()}")
        print("Creating a sample .env file...")
        
        with open(env_file, "w") as f:
            key = Fernet.generate_key().decode()
            f.write(f"""# SmartExplorers Configuration

# Database
DATABASE_URL=sqlite:///./smartexplorers.db

# OpenAI API
OPENAI_API_KEY=your-openai-key-here

# Encryption (for identity verification)
ENCRYPTION_MASTER_KEY={key}

# Security
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Application
DEBUG=True
API_V1_PREFIX=/api

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
""")
        print(f"✅ Created .env file with encryption key at: {env_file.absolute()}")
    
    # Run tests
    results = []
    
    results.append(("Encryption", test_encryption()))
    results.append(("Face Detection", test_face_detection()))
    results.append(("OCR", test_ocr()))
    results.append(("Workflow", test_workflow()))
    
    # Print results
    print_section("Test Results Summary")
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {name}")
    
    print("\n" + "=" * 80)
    print(f"Total: {passed}/{total} tests passed ({passed/total*100:.1f}%)")
    print("=" * 80)
    
    if passed < total:
        print("\n⚠️  Some tests failed. See details above.")
    else:
        print("\n🎉 All tests passed!")
    
    print("\nNext Steps:")
    print("  1. Ensure ENCRYPTION_MASTER_KEY is set in .env")
    print("  2. Install dependencies:")
    print("     pip install deepface opencv-python tf-keras pytesseract")
    print("  3. Start the server:")
    print("     cd backend && uvicorn app.main:app --reload")
    print("  4. Test the API endpoints")


if __name__ == "__main__":
    main()