#!/bin/bash

# Quick Start Script untuk WhatsApp OTP Setup
# Jalankan: bash setup_whatsapp_otp.sh

set -e

echo "🚀 StyleSense AI - WhatsApp OTP Setup"
echo "======================================"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 tidak terinstall. Install Python 3.9+ terlebih dahulu."
    exit 1
fi

echo "✅ Python3 terdeteksi: $(python3 --version)"
echo ""

# Create .env file jika belum ada
if [ ! -f "backend/.env" ]; then
    echo "📝 Membuat file .env dari template..."
    cp backend/.env.example backend/.env
    echo "✅ File .env berhasil dibuat"
    echo ""
    echo "⚠️  PENTING: Edit backend/.env dan masukkan Twilio credentials Anda:"
    echo "   - TWILIO_ACCOUNT_SID"
    echo "   - TWILIO_AUTH_TOKEN"
    echo "   - TWILIO_WHATSAPP_NUMBER"
    echo ""
    read -p "Lanjutkan setelah update .env? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ File .env sudah ada"
fi

echo ""
echo "📦 Menginstall dependencies..."

# Install Python dependencies
cd backend
pip install --upgrade pip
pip install -r requirements.txt

echo "✅ Dependencies terinstall"
echo ""

# Test imports
echo "🧪 Testing imports..."
python3 << 'EOF'
try:
    import twilio
    print("✅ Twilio module imported successfully")
except ImportError:
    print("❌ Failed to import twilio")
    exit(1)

try:
    import whatsapp_otp
    print("✅ WhatsApp OTP module imported successfully")
except ImportError:
    print("❌ Failed to import whatsapp_otp")
    exit(1)

print("")
EOF

echo "✅ Semua imports berhasil!"
echo ""

echo "🎉 Setup selesai!"
echo ""
echo "📋 Next steps:"
echo "1. Edit backend/.env dengan Twilio credentials"
echo "2. Jalankan backend: python -m uvicorn modal_app:fastapi_app --reload"
echo "3. Update URL di Flutter: lib/pages/auth_page_whatsapp.dart"
echo "4. Run Flutter app: flutter run"
echo ""
echo "📖 Dokumentasi lengkap: docs/WHATSAPP_OTP_SETUP.md"
echo ""
