#!/usr/bin/env python3
"""
Install Real Face Verification (DeepFace)
This will enable actual AI-powered face matching instead of mock mode
"""

import subprocess
import sys
from pathlib import Path


def print_header(title):
    print("\n" + "=" * 80)
    print(f"  {title}")
    print("=" * 80 + "\n")


def install_deepface():
    """Install DeepFace and dependencies for real face verification"""
    
    print_header("Installing Real Face Verification")
    
    print("This will install:")
    print("  • DeepFace - Face recognition library")
    print("  • TensorFlow - AI framework")
    print("  • OpenCV - Computer vision")
    print()
    
    # Packages to install
    packages = [
        "deepface",
        "tf-keras",
        "tensorflow",
        "opencv-python",
    ]
    
    print("Installing packages (this may take a few minutes)...")
    print("-" * 80)
    
    for package in packages:
        print(f"\n📦 Installing {package}...")
        try:
            subprocess.check_call([
                sys.executable, 
                "-m", 
                "pip", 
                "install", 
                package,
                "--upgrade"
            ])
            print(f"  ✅ {package} installed successfully")
        except subprocess.CalledProcessError as e:
            print(f"  ❌ Failed to install {package}: {e}")
            return False
    
    print("\n" + "=" * 80)
    print("  Installation Complete!")
    print("=" * 80)
    
    return True


def test_installation():
    """Test if DeepFace is working"""
    
    print_header("Testing Installation")
    
    try:
        print("Importing DeepFace...")
        from deepface import DeepFace
        print("  ✅ DeepFace imported successfully")
        
        print("\nImporting TensorFlow...")
        import tensorflow as tf
        print(f"  ✅ TensorFlow {tf.__version__} imported successfully")
        
        print("\nImporting OpenCV...")
        import cv2
        print(f"  ✅ OpenCV {cv2.__version__} imported successfully")
        
        print("\n" + "=" * 80)
        print("  ✅ All packages are working correctly!")
        print("=" * 80)
        
        print("\n🎉 You can now use REAL face verification!")
        print("\nRun your test again:")
        print("  python test_with_images.py test_images/id.png test_images/selfie.jpg")
        print("\nIt will now:")
        print("  • Actually compare faces (not mock)")
        print("  • Detect different people correctly")
        print("  • Give accurate confidence scores")
        
        return True
    
    except Exception as e:
        print(f"\n❌ Testing failed: {e}")
        print("\nTry running:")
        print("  pip install --upgrade deepface tf-keras tensorflow opencv-python")
        return False


def main():
    print("=" * 80)
    print("  SmartExplorers - Enable Real Face Verification")
    print("=" * 80)
    
    print("\n⚠️  IMPORTANT:")
    print("   Currently running in MOCK MODE")
    print("   Mock mode always returns fake results (not real face comparison)")
    print("   This installer will enable REAL AI-powered face verification")
    
    input("\nPress Enter to continue with installation...")
    
    # Install
    success = install_deepface()
    
    if success:
        # Test
        test_installation()
    else:
        print("\n❌ Installation failed")
        print("\nManual installation:")
        print("  pip install deepface tf-keras tensorflow opencv-python")


if __name__ == "__main__":
    main()