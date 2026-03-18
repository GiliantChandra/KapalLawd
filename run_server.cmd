@echo off
echo =======================================================
echo     MENJALANKAN SERVER AI (PYTHON FASTAPI)
echo     Memuat dependensi PyTorch ke Nvidia RTX 3050...
echo =======================================================
cd backend
call venv\Scripts\activate.bat
python main.py
pause
