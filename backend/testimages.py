#!/usr/bin/env python3
"""
Complete Identity Verification Test with Real Images

This script tests:
1. Face comparison between ID photo and selfie
2. OCR text extraction from ID document
3. Data encryption and decryption

Usage:
    python test_with_images.py <id_image_path> <selfie_image_path>

Example:
    python test_with_images.py images/national_id.jpg images/selfie.jpg
"""

import sys
import os
from pathlib import Path
import json
from datetime import datetime

# Add backend to path
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))


def print_section(title: str, char: str = "="):
    """Print formatted section header"""
    print("\n" + char * 80)
    print(f"  {title}")
    print(char * 80 + "\n")


def print_result(label: str, value: any, indent: int = 2):
    """Print a result with formatting"""
    spaces = " " * indent
    if isinstance(value, bool):
        icon = "✅" if value else "❌"
        print(f"{spaces}{icon} {label}: {value}")
    elif isinstance(value, (int, float)):
        print(f"{spaces}📊 {label}: {value}")
    else:
        print(f"{spaces}📝 {label}: {value}")


def load_image(image_path: str) -> tuple[bytes, bool, str]:
    """Load image file and return bytes"""
    path = Path(image_path)
    
    if not path.exists():
        return None, False, f"File not found: {image_path}"
    
    try:
        with open(path, 'rb') as f:
            image_bytes = f.read()
        
        # Check file size
        size_mb = len(image_bytes) / (1024 * 1024)
        
        return image_bytes, True, f"Loaded {size_mb:.2f} MB"
    
    except Exception as e:
        return None, False, f"Error loading file: {str(e)}"


def test_image_quality(image_bytes: bytes, image_name: str):
    """Test image quality for verification"""
    print_section(f"Image Quality Check: {image_name}", "-")
    
    try:
        from app.services.face_verification import face_verification_service
        
        result = face_verification_service.validate_image_quality(image_bytes)
        
        if result['valid']:
            print_result("Quality Check", "PASSED ✅")
            print_result("Dimensions", f"{result['width']}x{result['height']} pixels")
            print_result("File Size", f"{result['file_size'] / 1024:.1f} KB")
            print_result("Brightness", f"{result['brightness']:.1f}/255")
        else:
            print_result("Quality Check", "FAILED ❌")
            print_result("Reason", result['reason'])
            return False
        
        return True
    
    except Exception as e:
        print(f"  ❌ Quality check error: {str(e)}")
        return False


def test_face_detection(image_bytes: bytes, image_name: str):
    """Test face detection in image"""
    print_section(f"Face Detection: {image_name}", "-")
    
    try:
        from app.services.face_verification import face_verification_service
        
        result = face_verification_service.detect_face(image_bytes)
        
        if result.get('face_detected'):
            print_result("Face Detected", "YES ✅")
            print_result("Confidence", f"{result.get('confidence', 0):.1%}")
            print_result("Face Count", result.get('face_count', 0))
            
            if result.get('face_count', 0) > 1:
                print(f"  ⚠️  Warning: {result.get('warning', 'Multiple faces detected')}")
            
            if result.get('mock_mode'):
                print(f"  ℹ️  Running in MOCK MODE (DeepFace not installed)")
            
            return True, result
        else:
            print_result("Face Detected", "NO ❌")
            print_result("Error", result.get('error', 'Unknown error'))
            return False, result
    
    except Exception as e:
        print(f"  ❌ Face detection error: {str(e)}")
        return False, {}


def test_face_verification(id_image_bytes: bytes, selfie_image_bytes: bytes):
    """Compare faces between ID and selfie"""
    print_section("Face Verification (ID vs Selfie)")
    
    try:
        from app.services.face_verification import face_verification_service
        
        print("  🔄 Comparing faces using VGG-Face model...")
        
        result = face_verification_service.verify_faces(
            id_image_bytes,
            selfie_image_bytes
        )
        
        verified = result.get('verified', False)
        confidence = result.get('confidence', 0)
        
        print_result("Faces Match", verified)
        print_result("Confidence Score", f"{confidence:.1%}")
        print_result("Distance", f"{result.get('distance', 0):.4f}")
        print_result("Threshold", f"{result.get('threshold', 0):.4f}")
        print_result("Model Used", result.get('model', 'Unknown'))
        
        if result.get('mock_mode'):
            print(f"\n  ℹ️  Running in MOCK MODE (DeepFace not installed)")
            print(f"      Install with: pip install deepface tf-keras opencv-python")
        
        # Interpretation
        print("\n  📋 Interpretation:")
        if verified and confidence >= 0.7:
            print("     ✅ HIGH CONFIDENCE - Faces match well")
            print("     ✅ Person in selfie matches ID photo")
        elif verified and confidence >= 0.5:
            print("     ⚠️  MEDIUM CONFIDENCE - Faces likely match")
            print("     ⚠️  Manual review recommended")
        else:
            print("     ❌ LOW CONFIDENCE - Faces may not match")
            print("     ❌ Potential identity mismatch")
        
        return verified, result
    
    except Exception as e:
        print(f"  ❌ Face verification error: {str(e)}")
        import traceback
        traceback.print_exc()
        return False, {}


def test_ocr_extraction(id_image_bytes: bytes):
    """Extract text from ID using OCR"""
    print_section("OCR Text Extraction from ID")
    
    try:
        from app.services.ocr import ocr_service
        
        if not ocr_service.tesseract_available:
            print("  ⚠️  Tesseract not available - using mock extraction")
        
        print("  🔄 Extracting text from ID document...")
        
        # Extract raw text
        raw_text = ocr_service.extract_text(id_image_bytes)
        
        print("\n  📄 Raw OCR Text:")
        print("  " + "-" * 76)
        for line in raw_text.split('\n')[:10]:  # Show first 10 lines
            if line.strip():
                print(f"  {line}")
        if len(raw_text.split('\n')) > 10:
            print(f"  ... ({len(raw_text.split('\n')) - 10} more lines)")
        print("  " + "-" * 76)
        
        # Parse Egyptian National ID
        print("\n  🔍 Parsing Egyptian National ID format...")
        
        parsed_data = ocr_service.parse_egyptian_national_id(raw_text)
        
        print("\n  📋 Extracted Data:")
        print_result("Document Type", parsed_data.get('document_type', 'Unknown'))
        print_result("ID Number", parsed_data.get('document_number', 'Not found'))
        print_result("Full Name", parsed_data.get('full_name', 'Not found'))
        print_result("Date of Birth", parsed_data.get('date_of_birth', 'Not found'))
        print_result("Gender", parsed_data.get('gender', 'Not found'))
        print_result("Nationality", parsed_data.get('nationality', 'Unknown'))
        print_result("Extraction Confidence", f"{parsed_data.get('confidence', 0):.1%}")
        
        if parsed_data.get('confidence', 0) < 0.5:
            print("\n  ⚠️  Low confidence - OCR may be inaccurate")
            print("     Suggestions:")
            print("     • Ensure image is clear and well-lit")
            print("     • Check that text is horizontal")
            print("     • Use higher resolution image")
        
        return True, parsed_data
    
    except Exception as e:
        print(f"  ❌ OCR extraction error: {str(e)}")
        import traceback
        traceback.print_exc()
        return False, {}


def test_encryption(data: dict):
    """Test encryption and decryption of sensitive data"""
    print_section("Data Encryption & Decryption")
    
    try:
        from app.services.encryption import encryption_service
        
        # Filter out None values
        sensitive_data = {
            k: str(v) for k, v in data.items() 
            if v is not None and k in ['document_number', 'full_name', 'date_of_birth']
        }
        
        if not sensitive_data:
            print("  ⚠️  No data to encrypt")
            return False
        
        print("  🔒 Encrypting sensitive data...")
        print("\n  📝 Original Data:")
        for key, value in sensitive_data.items():
            print_result(key, value)
        
        # Encrypt each field
        encrypted_data = {}
        for key, value in sensitive_data.items():
            encrypted_data[key] = encryption_service.encrypt(value)
        
        print("\n  🔐 Encrypted Data:")
        for key, value in encrypted_data.items():
            display_value = value[:50] + "..." if len(value) > 50 else value
            print_result(key, display_value)
        
        # Decrypt
        print("\n  🔓 Decrypting data...")
        decrypted_data = {}
        for key, encrypted_value in encrypted_data.items():
            decrypted_data[key] = encryption_service.decrypt(encrypted_value)
        
        print("\n  ✅ Decrypted Data:")
        for key, value in decrypted_data.items():
            print_result(key, value)
        
        # Verify
        print("\n  🧪 Verification:")
        all_match = all(
            sensitive_data[k] == decrypted_data[k] 
            for k in sensitive_data.keys()
        )
        
        if all_match:
            print_result("Encryption/Decryption", "SUCCESS ✅")
            print("     All data encrypted and decrypted correctly!")
            return True
        else:
            print_result("Encryption/Decryption", "FAILED ❌")
            print("     Data mismatch after decryption!")
            return False
    
    except Exception as e:
        print(f"  ❌ Encryption error: {str(e)}")
        import traceback
        traceback.print_exc()
        return False


def generate_verification_report(results: dict):
    """Generate final verification report"""
    print_section("FINAL VERIFICATION REPORT")
    
    # Overall status
    all_passed = all([
        results.get('quality_id', False),
        results.get('quality_selfie', False),
        results.get('face_detected_id', False),
        results.get('face_detected_selfie', False),
        results.get('faces_match', False),
        results.get('ocr_success', False),
        results.get('encryption_success', False),
    ])
    
    print(f"  Overall Status: {'✅ VERIFIED' if all_passed else '❌ VERIFICATION FAILED'}")
    print("\n  Individual Checks:")
    
    checks = [
        ("ID Image Quality", results.get('quality_id', False)),
        ("Selfie Image Quality", results.get('quality_selfie', False)),
        ("Face Detected in ID", results.get('face_detected_id', False)),
        ("Face Detected in Selfie", results.get('face_detected_selfie', False)),
        ("Face Matching", results.get('faces_match', False)),
        ("OCR Extraction", results.get('ocr_success', False)),
        ("Data Encryption", results.get('encryption_success', False)),
    ]
    
    for check_name, passed in checks:
        icon = "✅" if passed else "❌"
        print(f"     {icon} {check_name}")
    
    # Confidence scores
    if 'face_confidence' in results:
        print(f"\n  Face Match Confidence: {results['face_confidence']:.1%}")
    
    if 'ocr_confidence' in results:
        print(f"  OCR Extraction Confidence: {results['ocr_confidence']:.1%}")
    
    # Extracted data
    if results.get('extracted_data'):
        data = results['extracted_data']
        print("\n  Extracted Identity Data:")
        if data.get('document_number'):
            # Mask the ID number for security
            id_num = data['document_number']
            masked = id_num[:4] + "*" * (len(id_num) - 8) + id_num[-4:]
            print(f"     ID Number: {masked}")
        if data.get('full_name'):
            print(f"     Name: {data['full_name']}")
        if data.get('date_of_birth'):
            print(f"     DOB: {data['date_of_birth']}")
        if data.get('gender'):
            print(f"     Gender: {data['gender']}")
    
    # Recommendation
    print("\n  📋 Recommendation:")
    if all_passed:
        print("     ✅ Identity verification PASSED")
        print("     ✅ User can be marked as verified")
        print("     ✅ All data encrypted and stored securely")
    elif results.get('faces_match') and results.get('ocr_success'):
        print("     ⚠️  Verification PASSED with warnings")
        print("     ⚠️  Manual review recommended")
        print("     ⚠️  Check image quality issues")
    else:
        print("     ❌ Verification FAILED")
        print("     ❌ Do NOT verify user")
        print("     ❌ Request new documents")
    
    print("\n" + "=" * 80)


def main():
    """Main test function"""
    print("=" * 80)
    print("  SmartExplorers - Identity Verification System")
    print("  Complete Image Testing Suite")
    print("=" * 80)
    
    # Check arguments
    if len(sys.argv) < 3:
        print("\n❌ Error: Missing image paths")
        print("\nUsage:")
        print("  python test_with_images.py <id_image_path> <selfie_image_path>")
        print("\nExample:")
        print("  python test_with_images.py images/national_id.jpg images/selfie.jpg")
        print("\nSupported formats: .jpg, .jpeg, .png")
        sys.exit(1)
    
    id_image_path = sys.argv[1]
    selfie_image_path = sys.argv[2]
    
    print(f"\n📁 ID Image: {id_image_path}")
    print(f"📁 Selfie Image: {selfie_image_path}")
    
    results = {}
    
    # Load images
    print_section("Loading Images")
    
    id_bytes, id_loaded, id_msg = load_image(id_image_path)
    print_result("ID Image", id_msg)
    
    selfie_bytes, selfie_loaded, selfie_msg = load_image(selfie_image_path)
    print_result("Selfie Image", selfie_msg)
    
    if not id_loaded or not selfie_loaded:
        print("\n❌ Failed to load images. Exiting.")
        sys.exit(1)
    
    # Test 1: Image Quality
    results['quality_id'] = test_image_quality(id_bytes, "ID Document")
    results['quality_selfie'] = test_image_quality(selfie_bytes, "Selfie")
    
    # Test 2: Face Detection
    id_face_ok, id_face_result = test_face_detection(id_bytes, "ID Document")
    results['face_detected_id'] = id_face_ok
    
    selfie_face_ok, selfie_face_result = test_face_detection(selfie_bytes, "Selfie")
    results['face_detected_selfie'] = selfie_face_ok
    
    # Test 3: Face Verification
    if id_face_ok and selfie_face_ok:
        faces_match, match_result = test_face_verification(id_bytes, selfie_bytes)
        results['faces_match'] = faces_match
        results['face_confidence'] = match_result.get('confidence', 0)
    else:
        print_section("Face Verification (ID vs Selfie)")
        print("  ⚠️  Skipped - face detection failed")
        results['faces_match'] = False
        results['face_confidence'] = 0
    
    # Test 4: OCR Extraction
    ocr_ok, extracted_data = test_ocr_extraction(id_bytes)
    results['ocr_success'] = ocr_ok
    results['extracted_data'] = extracted_data
    results['ocr_confidence'] = extracted_data.get('confidence', 0) if ocr_ok else 0
    
    # Test 5: Encryption
    if ocr_ok:
        encryption_ok = test_encryption(extracted_data)
        results['encryption_success'] = encryption_ok
    else:
        print_section("Data Encryption & Decryption")
        print("  ⚠️  Skipped - no data to encrypt")
        results['encryption_success'] = False
    
    # Generate report
    generate_verification_report(results)
    
    # Save results to file
    report_file = Path("verification_report.json")
    with open(report_file, 'w') as f:
        # Convert results to JSON-serializable format
        json_results = {
            k: v for k, v in results.items()
            if not isinstance(v, (bytes, object))
        }
        json.dump({
            'timestamp': datetime.now().isoformat(),
            'id_image': id_image_path,
            'selfie_image': selfie_image_path,
            'results': json_results
        }, f, indent=2)
    
    print(f"\n💾 Full report saved to: {report_file}")
    
    # Exit code
    sys.exit(0 if results.get('faces_match') and results.get('ocr_success') else 1)


if __name__ == "__main__":
    main()