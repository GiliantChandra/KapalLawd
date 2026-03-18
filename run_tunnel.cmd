@echo off
echo =======================================================
echo     MEMBUKA GERBANG INTERNET GLOBAL (TUNNELING)
echo     Menghubungkan Server AI lokal ke Domain Publik...
echo =======================================================
echo.
echo Tunggu beberapa detik sampai muncul tulisan hijau/putih berisi link (seperti https://xxxx.lhr.life)
echo Link tersebut adalah API Publik Anda!
echo.
ssh -o StrictHostKeyChecking=accept-new -R 80:localhost:8000 nokey@localhost.run
pause
