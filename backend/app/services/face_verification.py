"""
Face verification service for identity matching
Uses DeepFace for face detection and verification
"""

from typing import Dict, Tuple, Optional
import io

try:
    import numpy as np
    from PIL import Image
    import cv2
    CV2_AVAILABLE = True
except ImportError:
    CV2_AVAILABLE = False

try:
    from deepface import DeepFace
    DEEPFACE_AVAILABLE = True
except ImportError:
    DEEPFACE_AVAILABLE = False

if not CV2_AVAILABLE or not DEEPFACE_AVAILABLE:
    print("⚠️  OpenCV/DeepFace not installed. Face verification will use mock mode.")


class FaceVerificationService:
    """Handle face detection and verification"""
    
    def __init__(self):
        """Initialize face verification service"""
        self.deepface_available = DEEPFACE_AVAILABLE and CV2_AVAILABLE
        self.model_name = "VGG-Face"  # Options: VGG-Face, Facenet, OpenFace, DeepFace
        self.distance_metric = "cosine"  # Options: cosine, euclidean, euclidean_l2
        self.confidence_threshold = 0.70  # 70% confidence threshold
    
    def detect_face(self, image_bytes: bytes) -> Dict[str, any]:
        """
        Detect face in image
        
        Args:
            image_bytes: Image file bytes
        
        Returns:
            Detection result with face coordinates and confidence
        """
        if not self.deepface_available:
            return self._mock_detect_face()
        
        try:
            # Convert bytes to PIL Image then to numpy array
            image = Image.open(io.BytesIO(image_bytes))
            img_array = np.array(image)
            
            # DeepFace expects BGR format (OpenCV format)
            if len(img_array.shape) == 3 and img_array.shape[2] == 3:
                # Convert RGB to BGR
                img_array = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
            
            # Detect faces
            faces = DeepFace.extract_faces(
                img_path=img_array,
                detector_backend='opencv',  # Options: opencv, ssd, dlib, mtcnn, retinaface
                enforce_detection=True
            )
            
            if faces and len(faces) > 0:
                face = faces[0]  # Take first detected face
                
                return {
                    "face_detected": True,
                    "confidence": face.get('confidence', 1.0),
                    "face_count": len(faces),
                    "facial_area": face.get('facial_area', {}),
                    "warning": "Multiple faces detected" if len(faces) > 1 else None
                }
            else:
                return {
                    "face_detected": False,
                    "confidence": 0.0,
                    "face_count": 0,
                    "error": "No face detected in image"
                }
        
        except Exception as e:
            return {
                "face_detected": False,
                "confidence": 0.0,
                "error": str(e)
            }
    
    def verify_faces(
        self, 
        id_image_bytes: bytes, 
        selfie_image_bytes: bytes
    ) -> Dict[str, any]:
        """
        Verify if faces in two images match
        
        Args:
            id_image_bytes: ID document photo bytes
            selfie_image_bytes: Selfie photo bytes
        
        Returns:
            Verification result with confidence score
        """
        if not self.deepface_available:
            return self._mock_verify_faces()
        
        try:
            # Convert bytes to PIL Images then to numpy arrays
            id_image = np.array(Image.open(io.BytesIO(id_image_bytes)))
            selfie_image = np.array(Image.open(io.BytesIO(selfie_image_bytes)))
            
            # Convert RGB to BGR for OpenCV
            if len(id_image.shape) == 3:
                id_image = cv2.cvtColor(id_image, cv2.COLOR_RGB2BGR)
            if len(selfie_image.shape) == 3:
                selfie_image = cv2.cvtColor(selfie_image, cv2.COLOR_RGB2BGR)
            
            # Perform verification
            result = DeepFace.verify(
                img1_path=id_image,
                img2_path=selfie_image,
                model_name=self.model_name,
                distance_metric=self.distance_metric,
                enforce_detection=True
            )
            
            # Calculate confidence (1 - normalized distance)
            distance = result.get('distance', 1.0)
            threshold = result.get('threshold', 0.4)
            
            # Normalize confidence to 0-1 range
            if self.distance_metric == 'cosine':
                # Cosine distance ranges from 0 to 2
                confidence = 1 - (distance / 2)
            else:
                # Euclidean distance - normalize by threshold
                confidence = max(0, 1 - (distance / threshold))
            
            confidence = min(1.0, max(0.0, confidence))  # Clamp to [0, 1]
            
            is_match = result.get('verified', False)
            
            return {
                "verified": is_match,
                "confidence": round(confidence, 4),
                "distance": distance,
                "threshold": threshold,
                "model": self.model_name,
                "distance_metric": self.distance_metric,
                "passes_threshold": confidence >= self.confidence_threshold
            }
        
        except Exception as e:
            return {
                "verified": False,
                "confidence": 0.0,
                "error": str(e),
                "passes_threshold": False
            }
    
    def validate_image_quality(self, image_bytes: bytes) -> Dict[str, any]:
        """
        Validate image quality for verification
        
        Args:
            image_bytes: Image file bytes
        
        Returns:
            Quality validation result
        """
        try:
            image = Image.open(io.BytesIO(image_bytes))
            width, height = image.size
            
            # Check minimum resolution
            min_size = 200
            if width < min_size or height < min_size:
                return {
                    "valid": False,
                    "reason": f"Image too small ({width}x{height}). Minimum {min_size}x{min_size} required."
                }
            
            # Check maximum file size (10MB)
            max_size = 10 * 1024 * 1024  # 10MB in bytes
            if len(image_bytes) > max_size:
                return {
                    "valid": False,
                    "reason": f"Image too large ({len(image_bytes)} bytes). Maximum 10MB allowed."
                }
            
            # Check if image is too dark or too bright
            img_array = np.array(image.convert('L'))  # Convert to grayscale
            mean_brightness = np.mean(img_array)
            
            if mean_brightness < 30:
                return {
                    "valid": False,
                    "reason": "Image too dark. Please retake in better lighting."
                }
            
            if mean_brightness > 225:
                return {
                    "valid": False,
                    "reason": "Image too bright/overexposed. Please retake."
                }
            
            return {
                "valid": True,
                "width": width,
                "height": height,
                "file_size": len(image_bytes),
                "brightness": round(mean_brightness, 2)
            }
        
        except Exception as e:
            return {
                "valid": False,
                "reason": f"Invalid image file: {str(e)}"
            }
    
    def _mock_detect_face(self) -> Dict[str, any]:
        """Mock face detection for testing"""
        return {
            "face_detected": True,
            "confidence": 0.95,
            "face_count": 1,
            "facial_area": {"x": 100, "y": 100, "w": 200, "h": 200},
            "warning": None,
            "mock_mode": True
        }
    
    def _mock_verify_faces(self) -> Dict[str, any]:
        """Mock face verification for testing"""
        import random
        
        # Simulate realistic verification
        confidence = random.uniform(0.75, 0.95)
        
        return {
            "verified": True,
            "confidence": round(confidence, 4),
            "distance": round(1 - confidence, 4),
            "threshold": 0.4,
            "model": "VGG-Face (Mock)",
            "distance_metric": "cosine",
            "passes_threshold": confidence >= self.confidence_threshold,
            "mock_mode": True
        }


# Global face verification service instance
face_verification_service = FaceVerificationService()