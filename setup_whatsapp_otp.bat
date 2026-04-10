@echo off
REM Quick Start Script untuk WhatsApp OTP Setup (Windows)
REM Jalankan: setup_whatsapp_otp.bat

echo.
echo ^G🚀 StyleSense AI - WhatsApp OTP Setup
echo ======================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ^G❌ Python tidak terinstall. Install Python 3.9+ terlebih dahulu.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('python --version') do set PYTHON_VERSION=%%i
echo ^G✅ %PYTHON_VERSION% terdeteksi
echo.

REM Create .env file jika belum ada
if not exist "backend\.env" (
    echo ^G📝 Membuat file .env dari template...
    copy backend\.env.example backend\.env >nul
    echo ^G✅ File .env berhasil dibuat
    echo.
    echo ^G⚠️  PENTING: Edit backend\.env dan masukkan Twilio credentials Anda:
    echo    - TWILIO_ACCOUNT_SID
    echo    - TWILIO_AUTH_TOKEN
    echo    - TWILIO_WHATSAPP_NUMBER
    echo.
    set /p CONTINUE="Lanjutkan setelah update .env? (y/n) "
    if /i not "%CONTINUE%"=="y" exit /b 1
    echo.
) else (
    echo ^G✅ File .env sudah ada
)

echo.
echo ^G📦 Menginstall dependencies...
echo.

REM Install Python dependencies
cd backend
python -m pip install --upgrade pip
if errorlevel 1 (
    echo ^G❌ Gagal mengupgrade pip
    pause
    exit /b 1
)

python -m pip install -r requirements.txt
if errorlevel 1 (
    echo ^G❌ Gagal menginstall dependencies
    pause
    exit /b 1
)

echo.
echo ^G✅ Dependencies terinstall
echo.

REM Test imports
echo ^G🧪 Testing imports...
python << 'EOF'
try:
    import twilio
    print("✅ Twilio module imported successfully")
except ImportError as e:
    print(f"❌ Failed to import twilio: {e}")
    exit(1)

try:
    import whatsapp_otp
    print("✅ WhatsApp OTP module imported successfully")
except ImportError as e:
    print(f"❌ Failed to import whatsapp_otp: {e}")
    exit(1)

print("")
EOF

if errorlevel 1 (
    echo ^G❌ Ada error saat testing imports
    pause
    exit /b 1
)

echo ^G✅ Semua imports berhasil!
echo.

echo ^G🎉 Setup selesai!
echo.
echo ^G📋 Next steps:
echo 1. Edit backend\.env dengan Twilio credentials
echo 2. Jalankan backend: python -m uvicorn modal_app:fastapi_app --reload
echo 3. Update URL di Flutter: lib\pages\auth_page_whatsapp.dart
echo 4. Run Flutter app: flutter run
echo.
echo ^G📖 Dokumentasi lengkap: docs\WHATSAPP_OTP_SETUP.md
echo.

pause
