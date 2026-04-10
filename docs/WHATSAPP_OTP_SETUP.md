# 📱 WhatsApp OTP Integration Guide

## Overview

Sistem OTP via WhatsApp menggunakan **Twilio API** untuk mengirim kode verifikasi melalui WhatsApp atau SMS. Fitur ini memberikan pengalaman autentikasi yang lebih modern dan user-friendly.

## Fitur Utama

✅ **Kirim OTP via WhatsApp** - Metode preferensi pertama  
✅ **Fallback ke SMS** - Jika WhatsApp tidak tersedia  
✅ **Verifikasi OTP** - Validasi kode dengan timeout  
✅ **Resend OTP** - Kirim ulang dengan interface countdown  
✅ **Rate Limiting** - Lindungi dari penyalahgunaan  

---

## 🔧 Instalasi & Setup

### 1. Install Dependencies

**Backend (Python):**
```bash
cd backend
pip install twilio requests
```

**Frontend (Flutter):**
Pastikan `pubspec.yaml` sudah memiliki package `http`:
```yaml
dependencies:
  http: ^1.1.0
```

### 2. Setup Twilio Account

#### Step 1: Buat Twilio Account
- Kunjungi [twilio.com](https://www.twilio.com)
- Sign up dengan email
- Verifikasi nomor telepon Anda

#### Step 2: Dapatkan WhatsApp Sandbox
1. Di Twilio Console, pergi ke **Messaging > Try it out > Send an SMS**
2. Atau akses **Messaging > WhatsApp > Try it Out**
3. Klik **WhatsApp Sandbox**
4. Ikuti instruksi untuk join sandbox dengan WhatsApp

#### Step 3: Dapatkan Credentials
Di Twilio Console:
- **Account SID**: Dari [console.twilio.com/account](https://console.twilio.com/account)
- **Auth Token**: Dari halaman yang sama
- **WhatsApp Number**: Dari WhatsApp Sandbox settings (format: `+1234567890`)
- **From Number (SMS)**: Nomor Twilio untuk SMS (format: `+1234567890`)

### 3. Environment Variables

Buat file `.env` di folder `backend/`:

```bash
# Twilio Configuration
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_WHATSAPP_NUMBER=+1234567890
TWILIO_PHONE_NUMBER=+1234567890

# Environment
ENVIRONMENT=development  # atau "production"
```

**PENTING**: Jangan commit `.env` ke Git!

### 4. Update Backend URL di Flutter

Di file `lib/pages/auth_page_whatsapp.dart`, update:

```dart
final String _backendUrl = 'https://your-backend-url.com';
```

Ganti dengan URL backend Anda (local dev: `http://localhost:8000`)

---

## 📡 API Endpoints

### 1. Send OTP
**POST** `/send-otp`

```json
Request:
{
  "phone_number": "+628123456789",
  "method": "whatsapp"
}

Response (Success - 200):
{
  "success": true,
  "message": "OTP berhasil dikirim ke WhatsApp +628123456789",
  "remaining_time": 300
}

Response (Error - 400):
{
  "detail": "Nomor telepon tidak valid"
}
```

### 2. Verify OTP
**POST** `/verify-otp`

```json
Request:
{
  "phone_number": "+628123456789",
  "otp_code": "123456"
}

Response (Success - 200):
{
  "success": true,
  "message": "OTP berhasil diverifikasi.",
  "verified": true
}

Response (Wrong OTP):
{
  "success": false,
  "message": "OTP salah. Sisa percobaan: 2",
  "verified": false
}
```

### 3. Resend OTP
**POST** `/resend-otp`

```json
Request:
{
  "phone_number": "+628123456789",
  "method": "whatsapp"
}

Response (Success - 200):
{
  "success": true,
  "message": "OTP berhasil dikirim ulang",
  "remaining_time": 300
}
```

### 4. Check OTP Status
**GET** `/otp-status/{phone_number}`

```json
Response:
{
  "phone_number": "+628123456789",
  "has_otp": true,
  "remaining_time": 245,
  "message": "OTP berlaku selama 245 detik"
}
```

---

## 🚀 Integrasi ke Modal Backend

Update `modal_app.py` untuk menambahkan OTP routes:

```python
from fastapi import FastAPI
from otp_routes import setup_otp_routes

# ... existing FastAPI setup ...

fastapi_app = FastAPI(title="Modal Serverless GPU API")

# Setup OTP routes
setup_otp_routes(fastapi_app)

# ... rest of your code ...
```

---

## 🎯 Cara Menggunakan di Flutter

### Opsi 1: Replace Auth Page Existing
Update imports di `main.dart`:

```dart
// Ganti dari:
// import 'pages/auth_page.dart';

// Menjadi:
import 'pages/auth_page_whatsapp.dart' as auth;

// Di AuthGate:
return auth.AuthPageWhatsApp();
```

### Opsi 2: Dual Auth Pages (Recommended)
Buat custom auth selection page:

```dart
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Tampilkan pilihan auth method
    return AuthMethodSelector(); // Pilih SMS atau WhatsApp
  }
}
```

---

## 🧪 Testing

### Test Backend OTP Service (Python)

```python
from whatsapp_otp import get_otp_service

otp_service = get_otp_service()

# Test send OTP
success, otp, msg = otp_service.send_otp_whatsapp('+628123456789')
print(f"Sent: {msg}, OTP: {otp}")

# Test verify OTP
is_valid, verify_msg = otp_service.verify_otp('+628123456789', otp)
print(f"Verified: {is_valid}, {verify_msg}")

# Test resend
success, resend_msg = otp_service.resend_otp('+628123456789', 'sms')
print(f"Resend: {resend_msg}")
```

### Test API Endpoints dengan cURL

```bash
# Send OTP via WhatsApp
curl -X POST http://localhost:8000/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone_number":"+628123456789","method":"whatsapp"}'

# Verify OTP
curl -X POST http://localhost:8000/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone_number":"+628123456789","otp_code":"123456"}'

# Check status
curl http://localhost:8000/otp-status/%2B628123456789
```

### Test Flutter UI
1. Run app: `flutter run`
2. Tap "Sign Up"
3. Fill email & password
4. Select phone number & OTP method (WhatsApp/SMS)
5. Tap "Sign Up"
6. Terima OTP di WhatsApp
7. Masukkan OTP & tap "Confirm"

---

## 🔒 Security Best Practices

### 1. OTP Timeout
- Default: 5 menit (300 detik)
- Dapat dikonfigurasi di `whatsapp_otp.py`

### 2. Rate Limiting
```python
# Tambahkan ke whatsapp_otp.py
from collections import defaultdict
import time

class RateLimiter:
    def __init__(self, max_otp_per_hour=5):
        self.attempts = defaultdict(list)
        self.max_otp_per_hour = max_otp_per_hour
    
    def check_limit(self, phone_number):
        now = time.time()
        attempts = self.attempts[phone_number]
        
        # Remove old attempts (> 1 hour)
        attempts[:] = [t for t in attempts if now - t < 3600]
        
        if len(attempts) >= self.max_otp_per_hour:
            return False, "Terlalu banyak percobaan. Coba lagi nanti."
        
        attempts.append(now)
        return True, "OK"
```

### 3. Validate Phone Numbers
- Format: `+62xxxxxxxxxx` (Indonesia) atau `+[country_code]...`
- Min 8 digits, Max 15 digits
- Gunakan regex: `^\+?\d{8,15}$`

### 4. HTTPS Required
- Selalu gunakan HTTPS di production
- Jangan kirim OTP via plain HTTP

### 5. Environment Variables
- Store semua secrets di `.env`
- Tidak boleh hardcoded di source code
- Gunakan `python-dotenv` untuk load `.env`

```python
from dotenv import load_dotenv
load_dotenv()

account_sid = os.getenv('TWILIO_ACCOUNT_SID')
```

---

## 🐛 Troubleshooting

### Issue 1: "Twilio credentials tidak diset"
**Solusi:** Set environment variables dengan benar
```bash
export TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxx
export TWILIO_AUTH_TOKEN=your_token_here
export TWILIO_WHATSAPP_NUMBER=+1234567890
```

### Issue 2: "OTP tidak terkirim"
**Kemungkinan:**
- Twilio account belum verified (gunakan trial)
- WhatsApp Sandbox belum di-join
- Phone number format tidak sesuai (harus +62...)
- Rate limit tercapai

### Issue 3: Backend URL connection failed
**Solusi:** 
- Pastikan backend running (`python -m uvicorn modal_app:fastapi_app --reload`)
- Update URL di Flutter
- Untuk local testing: gunakan `http://localhost:8000`

### Issue 4: OTP Code Salah Terus
**Kemungkinan:**
- User mengetik OTP salah
- Timeout OTP terlampaui
- Backend restart (OTP di-reset)

---

## 📊 Architecture

```
┌─────────────────┐
│   Flutter App   │
│   (auth_page_   │
│     whatsapp)   │
└────────┬────────┘
         │ HTTP POST
         │ /send-otp
         │ /verify-otp
         │
┌────────▼────────┐      ┌──────────────────┐
│ FastAPI Backend │◄────►│  Twilio API      │
│ (otp_routes.py) │      │  (Business API)  │
└────────┬────────┘      └──────────────────┘
         │
    ┌────▼─────┐      ┌───────────────────┐
    │ WhatsApp  │◄────►│ User's WhatsApp   │
    │ Messaging │      │ (Receives OTP)    │
    └───────────┘      └───────────────────┘
```

---

## 📝 File Structure

```
backend/
├── whatsapp_otp.py           # OTP Service class
├── otp_routes.py             # FastAPI routes
├── modal_app.py              # Main app (import otp_routes)
├── requirements.txt          # Add: twilio, requests
└── .env                       # Environment variables

app/lib/pages/
├── auth_page.dart            # Original SMS auth
├── auth_page_whatsapp.dart   # WhatsApp OTP auth (NEW)
└── main.dart                 # Update imports here
```

---

## ✅ Next Steps

1. ✅ Setup Twilio account & get credentials
2. ✅ Create `.env` file dengan credentials
3. ✅ Install dependencies (`pip install`, `pub get`)
4. ✅ Test backend OTP service
5. ✅ Test API endpoints
6. ✅ Integrate Flutter auth page
7. ✅ Test end-to-end flow
8. ✅ Deploy ke production

---

## 📞 Support

Jika ada masalah:
1. Check Twilio logs: [console.twilio.com/logs](https://console.twilio.com/logs)
2. Check Flutter debug console: `flutter run -v`
3. Check backend logs: `python -m uvicorn ... --reload`
4. Verify phone number format dengan regex tester
5. Test Twilio API directly dengan cURL

---

## 📄 License

Part of StyleSense AI Project
