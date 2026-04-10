from dotenv import load_dotenv
load_dotenv()
import os
import random
import string
from datetime import datetime, timedelta
from typing import Dict, Tuple
import requests
from fastapi import HTTPException
import json

class WhatsAppOTPService:
    """Layanan pengiriman OTP melalui WhatsApp menggunakan Twilio"""
    
    def __init__(self):
        self.account_sid = os.getenv('TWILIO_ACCOUNT_SID', '')
        self.auth_token = os.getenv('TWILIO_AUTH_TOKEN', '')
        self.twilio_phone = os.getenv('TWILIO_WHATSAPP_NUMBER', '+1234567890')  # WhatsApp Number dari Twilio
        self.base_url = 'https://api.twilio.com/2010-04-01'
        
        # Penyimpanan OTP sementara (dalam production, gunakan Redis atau Database)
        self.otp_store: Dict[str, Dict] = {}
        
        if not self.account_sid or not self.auth_token:
            print("WARNING: Twilio credentials tidak diset. WhatsApp OTP tidak akan berfungsi.")
    
    def generate_otp(self, length: int = 6) -> str:
        """Buat kode OTP acak"""
        return ''.join(random.choices(string.digits, k=length))
    
    def store_otp(self, phone_number: str, otp: str, expires_in_minutes: int = 5) -> None:
        """Simpan OTP dengan waktu kadaluarsa"""
        expiry_time = datetime.now() + timedelta(minutes=expires_in_minutes)
        self.otp_store[phone_number] = {
            'otp': otp,
            'created_at': datetime.now(),
            'expires_at': expiry_time,
            'attempts': 0
        }
    
    def verify_otp(self, phone_number: str, otp: str, max_attempts: int = 3) -> Tuple[bool, str]:
        """Verifikasi OTP yang diinput user"""
        if phone_number not in self.otp_store:
            return False, "OTP tidak ditemukan. Silakan minta OTP baru."
        
        otp_data = self.otp_store[phone_number]
        
        # Cek kadaluarsa
        if datetime.now() > otp_data['expires_at']:
            del self.otp_store[phone_number]
            return False, "OTP telah kadaluarsa. Silakan minta OTP baru."
        
        # Cek jumlah percobaan
        if otp_data['attempts'] >= max_attempts:
            del self.otp_store[phone_number]
            return False, "Terlalu banyak percobaan gagal. Silakan minta OTP baru."
        
        # Verifikasi OTP
        if otp_data['otp'] != otp:
            otp_data['attempts'] += 1
            return False, f"OTP salah. Sisa percobaan: {max_attempts - otp_data['attempts']}"
        
        # OTP benar, hapus dari store
        del self.otp_store[phone_number]
        return True, "OTP berhasil diverifikasi."
    
    def send_otp_whatsapp(self, phone_number: str) -> Tuple[bool, str, str]:
        """Kirim OTP melalui WhatsApp"""
        try:
            # Normalisasi nomor telepon (tambahkan +62 jika belum ada kode negara)
            normalized_phone = self._normalize_phone_number(phone_number)
            
            # Generate OTP
            otp = self.generate_otp()
            
            # Simpan OTP
            self.store_otp(normalized_phone, otp)
            
            # Kirim via Twilio WhatsApp API
            if self.account_sid and self.auth_token:
                success = self._send_via_twilio(normalized_phone, otp)
                if success:
                    return True, otp, f"OTP berhasil dikirim ke WhatsApp {normalized_phone}"
            
            # Fallback: dalam development, tampilkan OTP (JANGAN DI PRODUCTION!)
            if os.getenv('ENVIRONMENT') == 'development':
                return True, otp, f"[DEV] OTP untuk {normalized_phone}: {otp}"
            
            return False, "", "Gagal mengirim OTP. Silakan coba lagi."
            
        except Exception as e:
            return False, "", f"Error mengirim WhatsApp OTP: {str(e)}"
    
    def send_otp_sms(self, phone_number: str) -> Tuple[bool, str, str]:
        """Kirim OTP melalui SMS (fallback dari WhatsApp)"""
        try:
            normalized_phone = self._normalize_phone_number(phone_number)
            otp = self.generate_otp()
            self.store_otp(normalized_phone, otp)
            
            if self.account_sid and self.auth_token:
                success = self._send_sms_via_twilio(normalized_phone, otp)
                if success:
                    return True, otp, f"OTP berhasil dikirim via SMS ke {normalized_phone}"
            
            if os.getenv('ENVIRONMENT') == 'development':
                return True, otp, f"[DEV] SMS OTP untuk {normalized_phone}: {otp}"
            
            return False, "", "Gagal mengirim OTP via SMS."
            
        except Exception as e:
            return False, "", f"Error mengirim SMS OTP: {str(e)}"
    
    def _normalize_phone_number(self, phone: str) -> str:
        """Normalisasi nomor telepon ke format internasional"""
        # Hapus karakter non-digit kecuali +
        phone = ''.join(c for c in phone if c.isdigit() or c == '+')
        
        if phone.startswith('+'):
            return phone
        
        # Jika dimulai dengan 0, ganti dengan +62
        if phone.startswith('0'):
            return '+62' + phone[1:]
        
        # Jika tidak ada kode negara, asumsikan +62 (Indonesia)
        if not phone.startswith('+'):
            return '+62' + phone
        
        return phone
    
    def _send_via_twilio(self, phone_number: str, otp: str) -> bool:
        """Kirim OTP melalui Twilio WhatsApp API"""
        try:
            url = f"{self.base_url}/Accounts/{self.account_sid}/Messages.json"
            
            message_body = f"""Halo! Kode OTP Anda adalah:

*{otp}*

Kode ini berlaku selama 5 menit. Jangan bagikan kode ini kepada siapa pun.

StyleSense AI"""
            
            auth = (self.account_sid, self.auth_token)
            data = {
                'From': f'whatsapp:{self.twilio_phone}',
                'To': f'whatsapp:{phone_number}',
                'Body': message_body
            }
            
            response = requests.post(url, data=data, auth=auth, timeout=10)
            
            if response.status_code in [200, 201]:
                print(f"WhatsApp OTP berhasil dikirim ke {phone_number}")
                return True
            else:
                print(f"Twilio error: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            print(f"Error Twilio WhatsApp: {str(e)}")
            return False
    
    def _send_sms_via_twilio(self, phone_number: str, otp: str) -> bool:
        """Kirim OTP melalui Twilio SMS API"""
        try:
            url = f"{self.base_url}/Accounts/{self.account_sid}/Messages.json"
            
            message_body = f"Kode OTP StyleSense AI Anda: {otp} (berlaku 5 menit)"
            
            auth = (self.account_sid, self.auth_token)
            data = {
                'From': self.twilio_phone,  # Twilio phone number untuk SMS
                'To': phone_number,
                'Body': message_body
            }
            
            response = requests.post(url, data=data, auth=auth, timeout=10)
            
            if response.status_code in [200, 201]:
                print(f"SMS OTP berhasil dikirim ke {phone_number}")
                return True
            else:
                print(f"Twilio SMS error: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            print(f"Error Twilio SMS: {str(e)}")
            return False
    
    def get_remaining_time(self, phone_number: str) -> int:
        """Dapatkan sisa waktu OTP dalam detik"""
        if phone_number not in self.otp_store:
            return 0
        
        expiry = self.otp_store[phone_number]['expires_at']
        remaining = (expiry - datetime.now()).total_seconds()
        return max(0, int(remaining))
    
    def resend_otp(self, phone_number: str, method: str = 'whatsapp') -> Tuple[bool, str]:
        """Kirim ulang OTP"""
        if phone_number in self.otp_store:
            del self.otp_store[phone_number]
        
        if method == 'whatsapp':
            success, otp, message = self.send_otp_whatsapp(phone_number)
        else:
            success, otp, message = self.send_otp_sms(phone_number)
        
        return success, message


# Singleton instance
_otp_service = None

def get_otp_service() -> WhatsAppOTPService:
    """Dapatkan instance WhatsAppOTPService"""
    global _otp_service
    if _otp_service is None:
        _otp_service = WhatsAppOTPService()
    return _otp_service
