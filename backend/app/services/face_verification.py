"""
Face Verification Service using DeepFace
"""
from deepface import DeepFace
import cv2
import numpy as np
from typing import Dict, Tuple, Optional
import os
import tempfile
from PIL import Image


class FaceVerificationService:
    """Face matching service using DeepFace"""
    
    def __init__(self, model_name: str = "VGG-Face"):
        self.model_name = model_name
        self.distance_metric = "cosine"
        self.detector_backend = "opencv"
        self.face_match_threshold = 0.70
        
        print(f"✓ FaceVerificationService initialized with {model_name}")
    
    def _save_temp_image(self, image_data: bytes, prefix: str = "img") -> str:
        """Save image data to temporary file"""
        temp_file = tempfile.NamedTemporaryFile(
            delete=False, 
            suffix='.jpg', 
            prefix=prefix
        )
        temp_file.write(image_data)
        temp_file.close()
        return temp_file.name
    
    def _cleanup_temp_files(self, *file_paths):
        """Delete temporary files"""
        for path in file_paths:
            try:
                if path and os.path.exists(path):
                    os.unlink(path)
            except Exception as e:
                print(f"Warning: Failed to delete temp file {path}: {e}")
    
    def detect_face(self, image_data: bytes) -> Tuple[bool, Optional[str]]:
        """Detect if image contains a face"""
        temp_path = None
        try:
            temp_path = self._save_temp_image(image_data, prefix="face_detect_")
            
            faces = DeepFace.extract_faces(
                img_path=temp_path,
                detector_backend=self.detector_backend,
                enforce_detection=True
            )
            
            if not faces or len(faces) == 0:
                return False, "No face detected in image"
            
            if len(faces) > 1:
                return False, "Multiple faces detected. Please submit image with single face."
            
            return True, None
            
        except Exception as e:
            return False, f"Face detection failed: {str(e)}"
        finally:
            self._cleanup_temp_files(temp_path)
    
    def verify_faces(
        self, 
        id_image_data: bytes, 
        selfie_image_data: bytes,
        threshold: Optional[float] = None
    ) -> Dict:
        """Verify if faces in two images match"""
        id_path = None
        selfie_path = None
        
        try:
            id_path = self._save_temp_image(id_image_data, prefix="id_")
            selfie_path = self._save_temp_image(selfie_image_data, prefix="selfie_")
            
            use_threshold = threshold if threshold is not None else self.face_match_threshold
            
            result = DeepFace.verify(
                img1_path=id_path,
                img2_path=selfie_path,
                model_name=self.model_name,
                distance_metric=self.distance_metric,
                detector_backend=self.detector_backend,
                enforce_detection=True
            )
            
            distance = result['distance']
            confidence = max(0.0, min(1.0, 1.0 - (distance / 2.0)))
            
            if confidence >= 0.85:
                fraud_risk = "low"
            elif confidence >= 0.70:
                fraud_risk = "medium"
            else:
                fraud_risk = "high"
            
            return {
                "verified": result['verified'],
                "confidence": round(confidence, 4),
                "distance": round(distance, 4),
                "threshold": use_threshold,
                "model": self.model_name,
                "fraud_risk": fraud_risk
            }
            
        except Exception as e:
            return {
                "verified": False,
                "confidence": 0.0,
                "distance": None,
                "threshold": use_threshold if 'use_threshold' in locals() else 0.70,
                "model": self.model_name,
                "fraud_risk": "high",
                "error": f"Verification error: {str(e)}"
            }
        finally:
            self._cleanup_temp_files(id_path, selfie_path)
    
    def analyze_face_quality(self, image_data: bytes) -> Dict:
        """Analyze image quality for face verification"""
        temp_path = None
        try:
            temp_path = self._save_temp_image(image_data, prefix="quality_")
            
            img = cv2.imread(temp_path)
            if img is None:
                return {
                    "has_face": False,
                    "suitable_for_verification": False,
                    "issues": ["Could not read image"]
                }
            
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            brightness = np.mean(gray)
            laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
            
            faces = DeepFace.extract_faces(
                img_path=temp_path,
                detector_backend=self.detector_backend,
                enforce_detection=False
            )
            
            has_face = len(faces) > 0
            face_confidence = faces[0]['confidence'] if has_face else 0.0
            
            issues = []
            if brightness < 50:
                issues.append("Image too dark")
            elif brightness > 200:
                issues.append("Image too bright")
            
            if laplacian_var < 100:
                issues.append("Image too blurry")
            
            if not has_face:
                issues.append("No face detected")
            elif len(faces) > 1:
                issues.append("Multiple faces detected")
            
            suitable = len(issues) == 0 and has_face
            
            return {
                "has_face": has_face,
                "face_confidence": round(face_confidence, 4) if has_face else 0.0,
                "brightness": round(brightness, 2),
                "sharpness": round(laplacian_var, 2),
                "suitable_for_verification": suitable,
                "issues": issues
            }
            
        except Exception as e:
            return {
                "has_face": False,
                "suitable_for_verification": False,
                "issues": [f"Analysis error: {str(e)}"]
            }
        finally:
            self._cleanup_temp_files(temp_path)


# Global singleton
face_verification_service = FaceVerificationService()