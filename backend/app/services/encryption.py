"""
Encryption service for sensitive identity verification data
Uses Fernet symmetric encryption (AES-128 CBC mode)
"""

from cryptography.fernet import Fernet
from typing import Optional
import base64
import os
from ..config import settings


class EncryptionService:
    """Handle encryption/decryption of sensitive identity data"""
    
    def __init__(self):
        """Initialize encryption service with master key from environment"""
        if not settings.ENCRYPTION_MASTER_KEY:
            raise ValueError(
                "ENCRYPTION_MASTER_KEY environment variable not set!\n"
                "Generate with: python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'\n"
                "Then add to .env file: ENCRYPTION_MASTER_KEY=<generated_key>"
            )
        
        # Ensure the key is properly formatted
        key = settings.ENCRYPTION_MASTER_KEY.strip()
        
        # If the key is not base64 encoded, encode it
        try:
            self.cipher = Fernet(key.encode() if isinstance(key, str) else key)
        except Exception as e:
            raise ValueError(
                f"Invalid ENCRYPTION_MASTER_KEY format: {str(e)}\n"
                "The key must be a valid Fernet key (44 characters, base64-encoded)"
            )
    
    def encrypt(self, plaintext: str) -> str:
        """
        Encrypt sensitive data
        
        Args:
            plaintext: Data to encrypt (e.g., ID number, name)
        
        Returns:
            Base64-encoded encrypted string
        """
        if not plaintext:
            return ""
        
        # Convert to bytes if string
        plaintext_bytes = plaintext.encode('utf-8')
        
        # Encrypt
        encrypted_bytes = self.cipher.encrypt(plaintext_bytes)
        
        # Return as base64 string for database storage
        return encrypted_bytes.decode('utf-8')
    
    def decrypt(self, ciphertext: str) -> str:
        """
        Decrypt sensitive data
        
        Args:
            ciphertext: Base64-encoded encrypted string
        
        Returns:
            Original plaintext string
        """
        if not ciphertext:
            return ""
        
        try:
            # Convert from base64 string to bytes
            ciphertext_bytes = ciphertext.encode('utf-8')
            
            # Decrypt
            plaintext_bytes = self.cipher.decrypt(ciphertext_bytes)
            
            # Return as string
            return plaintext_bytes.decode('utf-8')
        except Exception as e:
            raise ValueError(f"Decryption failed: {str(e)}")
    
    def encrypt_dict(self, data: dict) -> dict:
        """
        Encrypt all string values in a dictionary
        
        Args:
            data: Dictionary with plaintext values
        
        Returns:
            Dictionary with encrypted values
        """
        encrypted = {}
        for key, value in data.items():
            if isinstance(value, str) and value:
                encrypted[f"encrypted_{key}"] = self.encrypt(value)
            else:
                encrypted[key] = value
        return encrypted
    
    def decrypt_dict(self, data: dict, keys: list) -> dict:
        """
        Decrypt specific keys in a dictionary
        
        Args:
            data: Dictionary with encrypted values
            keys: List of keys to decrypt (without 'encrypted_' prefix)
        
        Returns:
            Dictionary with decrypted values
        """
        decrypted = data.copy()
        for key in keys:
            encrypted_key = f"encrypted_{key}"
            if encrypted_key in data and data[encrypted_key]:
                decrypted[key] = self.decrypt(data[encrypted_key])
        return decrypted


# Global encryption service instance
encryption_service = EncryptionService()