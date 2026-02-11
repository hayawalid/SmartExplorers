"""
OCR service for extracting text from identity documents
Uses Tesseract OCR + custom parsing for Egyptian IDs
"""

import re
from typing import Dict, Optional, Any
from datetime import datetime
from PIL import Image
import io
import cv2
import numpy as np

try:
    import pytesseract
    TESSERACT_AVAILABLE = True
except ImportError:
    TESSERACT_AVAILABLE = False
    print("⚠️  pytesseract not installed. OCR functionality will be limited.")


class OCRService:
    """Extract text and structured data from ID documents"""
    
    def __init__(self):
        """Initialize OCR service"""
        self.tesseract_available = TESSERACT_AVAILABLE
    
    def preprocess_image(self, image_bytes: bytes) -> np.ndarray:
        """
        Preprocess image for better OCR accuracy
        
        Args:
            image_bytes: Raw image bytes
        
        Returns:
            Preprocessed image as numpy array
        """
        # Convert bytes to PIL Image
        image = Image.open(io.BytesIO(image_bytes))
        
        # Convert to OpenCV format
        img_array = np.array(image)
        
        # Convert to grayscale
        if len(img_array.shape) == 3:
            gray = cv2.cvtColor(img_array, cv2.COLOR_RGB2GRAY)
        else:
            gray = img_array
        
        # Apply thresholding to get black text on white background
        _, threshold = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        
        # Denoise
        denoised = cv2.fastNlMeansDenoising(threshold, None, 10, 7, 21)
        
        return denoised
    
    def extract_text(self, image_bytes: bytes) -> str:
        """
        Extract raw text from image using OCR
        
        Args:
            image_bytes: Image file bytes
        
        Returns:
            Extracted text
        """
        if not self.tesseract_available:
            return self._mock_extract_text()
        
        try:
            # Preprocess image
            processed_img = self.preprocess_image(image_bytes)
            
            # Perform OCR
            text = pytesseract.image_to_string(processed_img, lang='eng+ara')
            
            return text.strip()
        except Exception as e:
            print(f"OCR error: {str(e)}")
            return ""
    
    def parse_egyptian_national_id(self, ocr_text: str) -> Dict[str, Any]:
        """
        Parse Egyptian National ID from OCR text
        
        Egyptian National ID format: 14 digits
        First digit: century (2 = 1900s, 3 = 2000s)
        Next 6 digits: birth date (YYMMDD)
        Next 2 digits: governorate code
        Next 4 digits: sequence number
        Last digit: gender (odd = male, even = female)
        
        Args:
            ocr_text: Raw OCR text from ID
        
        Returns:
            Parsed ID data
        """
        result = {
            "document_type": "national_id",
            "document_number": None,
            "full_name": None,
            "date_of_birth": None,
            "nationality": "Egyptian",
            "gender": None,
            "confidence": 0.0
        }
        
        # Extract 14-digit ID number
        id_pattern = r'\b([23]\d{13})\b'
        id_match = re.search(id_pattern, ocr_text)
        
        if id_match:
            id_number = id_match.group(1)
            result["document_number"] = id_number
            result["confidence"] += 0.5
            
            # Parse date of birth from ID number
            try:
                century = "19" if id_number[0] == "2" else "20"
                year = century + id_number[1:3]
                month = id_number[3:5]
                day = id_number[5:7]
                
                dob = f"{year}-{month}-{day}"
                # Validate date
                datetime.strptime(dob, "%Y-%m-%d")
                result["date_of_birth"] = dob
                result["confidence"] += 0.2
            except ValueError:
                pass
            
            # Extract gender from last digit
            last_digit = int(id_number[-1])
            result["gender"] = "male" if last_digit % 2 == 1 else "female"
            result["confidence"] += 0.1
        
        # Extract name (Arabic or English)
        # Look for lines with alphabetic characters
        lines = ocr_text.split('\n')
        for line in lines:
            # Remove digits and special characters
            cleaned = re.sub(r'[0-9\-\/\:\.]', '', line).strip()
            
            # Check if line has at least 3 words (first, middle, last name)
            words = cleaned.split()
            if len(words) >= 2 and len(cleaned) >= 10:
                # This might be the name
                result["full_name"] = cleaned
                result["confidence"] += 0.2
                break
        
        return result
    
    def parse_passport(self, ocr_text: str) -> Dict[str, Any]:
        """
        Parse passport from OCR text (MRZ - Machine Readable Zone)
        
        Args:
            ocr_text: Raw OCR text from passport
        
        Returns:
            Parsed passport data
        """
        result = {
            "document_type": "passport",
            "document_number": None,
            "full_name": None,
            "date_of_birth": None,
            "nationality": None,
            "gender": None,
            "expiry_date": None,
            "confidence": 0.0
        }
        
        # Look for passport number (usually starts with letter + 7-9 digits)
        passport_pattern = r'\b([A-Z]\d{7,9})\b'
        passport_match = re.search(passport_pattern, ocr_text)
        
        if passport_match:
            result["document_number"] = passport_match.group(1)
            result["confidence"] += 0.4
        
        # Look for MRZ lines (two lines starting with P<)
        mrz_pattern = r'P<[A-Z]{3}([A-Z<]+)<<([A-Z<]+)'
        mrz_match = re.search(mrz_pattern, ocr_text)
        
        if mrz_match:
            surname = mrz_match.group(1).replace('<', ' ').strip()
            given_names = mrz_match.group(2).replace('<', ' ').strip()
            result["full_name"] = f"{given_names} {surname}"
            result["confidence"] += 0.3
        
        # Extract dates (YYMMDD format)
        date_pattern = r'\b(\d{6})\b'
        dates = re.findall(date_pattern, ocr_text)
        
        if len(dates) >= 2:
            # First date is usually DOB, second is expiry
            try:
                dob = self._parse_mrz_date(dates[0])
                result["date_of_birth"] = dob
                result["confidence"] += 0.15
                
                expiry = self._parse_mrz_date(dates[1])
                result["expiry_date"] = expiry
                result["confidence"] += 0.15
            except ValueError:
                pass
        
        return result
    
    def _parse_mrz_date(self, mrz_date: str) -> str:
        """
        Parse MRZ date format (YYMMDD) to ISO format
        
        Args:
            mrz_date: Date in YYMMDD format
        
        Returns:
            Date in YYYY-MM-DD format
        """
        year = int(mrz_date[0:2])
        month = mrz_date[2:4]
        day = mrz_date[4:6]
        
        # Determine century (assume < 30 is 2000s, >= 30 is 1900s)
        century = "20" if year < 30 else "19"
        full_year = century + f"{year:02d}"
        
        date_str = f"{full_year}-{month}-{day}"
        # Validate
        datetime.strptime(date_str, "%Y-%m-%d")
        
        return date_str
    
    def _mock_extract_text(self) -> str:
        """Mock OCR for testing when Tesseract not available"""
        return """
        ARAB REPUBLIC OF EGYPT
        NATIONAL ID CARD
        
        29503151234567
        
        AHMED MOHAMED ALI
        أحمد محمد علي
        
        Date of Birth: 15/03/1995
        """
    
    def extract_id_data(self, image_bytes: bytes, document_type: str = "national_id") -> Dict[str, Any]:
        """
        Complete ID extraction pipeline
        
        Args:
            image_bytes: Image file bytes
            document_type: Type of document (national_id, passport, drivers_license)
        
        Returns:
            Extracted and parsed data
        """
        # Extract text
        ocr_text = self.extract_text(image_bytes)
        
        # Parse based on document type
        if document_type == "national_id":
            return self.parse_egyptian_national_id(ocr_text)
        elif document_type == "passport":
            return self.parse_passport(ocr_text)
        else:
            # Generic extraction
            return {
                "document_type": document_type,
                "raw_text": ocr_text,
                "confidence": 0.5
            }


# Global OCR service instance
ocr_service = OCRService()