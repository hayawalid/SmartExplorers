"""
Encryption Service - Privacy-First Identity Data Protection
"""
from cryptography.fernet import Fernet
from typing import Optional
import os
import base64
import hashlib


class EncryptionService:
    """Handles encryption/decryption of sensitive identity data"""
    
    def __init__(self):
        self.current_version = "v1"
        self.keys = {}
        self._cipher = None
        self._initialized = False
    
    def _ensure_initialized(self):
        """Lazy initialization - only load key when first needed"""
        if self._initialized:
            return
        
        master_secret = os.getenv("ENCRYPTION_MASTER_KEY")
        
        if not master_secret:
            raise ValueError(
                "ENCRYPTION_MASTER_KEY environment variable not set!\n"
                "Generate with: python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'\n"
                "Then add to .env file: ENCRYPTION_MASTER_KEY=<generated_key>"
            )
        
        self.keys = {
            "v1": self._derive_key(master_secret, salt=b"smartexplorers_v1")
        }
        self._cipher = Fernet(self.keys[self.current_version])
        self._initialized = True
        print("✓ Encryption service initialized successfully")
    
    def _derive_key(self, master_secret: str, salt: bytes) -> bytes:
        """Derive Fernet key from master secret using PBKDF2"""
        kdf = hashlib.pbkdf2_hmac(
            'sha256',
            master_secret.encode(),
            salt,
            iterations=100000
        )
        return base64.urlsafe_b64encode(kdf[:32])
    
    def encrypt(self, plaintext: str, key_version: str = "v1") -> str:
        """Encrypt plaintext string"""
        self._ensure_initialized()
        
        if not plaintext:
            return ""
        
        cipher = Fernet(self.keys[key_version])
        encrypted_bytes = cipher.encrypt(plaintext.encode('utf-8'))
        return encrypted_bytes.decode('utf-8')
    
    def decrypt(self, encrypted_text: str, key_version: str = "v1") -> str:
        """Decrypt encrypted string"""
        self._ensure_initialized()
        
        if not encrypted_text:
            return ""
        
        cipher = Fernet(self.keys[key_version])
        decrypted_bytes = cipher.decrypt(encrypted_text.encode('utf-8'))
        return decrypted_bytes.decode('utf-8')


# Global singleton - lazy initialization
encryption_service = EncryptionService()