import cv2
import os
import glob
import numpy as np

files = [f for f in glob.glob("temp_uploads/*.jpg") if "generated" not in os.path.basename(f)]
if not files:
    print("NO TEMP UPLOADS FOUND")
    exit()

files.sort(key=os.path.getmtime, reverse=True)
latest = files[0]
print(f"Analisis file: {latest}")

img_bgr = cv2.imread(latest)
gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
faces = face_cascade.detectMultiScale(gray, 1.1, 4)

h, w = gray.shape

if len(faces) == 0:
    print("FATAL ERROR: WAJAH TIDAK TERDETEKSI!")
else:
    faces = sorted(faces, key=lambda x: x[2]*x[3], reverse=True)
    fx, fy, fw, fh = faces[0]
    print(f"Image Dim (H, W): {h}, {w}")
    print(f"Face Box: x={fx}, y={fy}, w={fw}, h={fh}")
    print(f"Muka Kiri: {fx}, Muka Kanan: {fx+fw}")
    print(f"Muka Atas: {fy}, Muka Bawah: {fy+fh}")
    
    # Simulate mask
    mask_np = np.zeros((h, w), dtype=np.uint8)
    
    rambut_bawah = int(fy + (fh * 1.5))
    rambut_atas = max(0, fy - int(fh * 0.8))
    rambut_kiri = max(0, fx - int(fw * 0.5))
    rambut_kanan = min(w, fx + fw + int(fw * 0.5))
    
    cv2.rectangle(mask_np, (rambut_kiri, rambut_atas), (rambut_kanan, rambut_bawah), 255, -1)
    print(f"U-Shape Area: y=[{rambut_atas} to {rambut_bawah}], x=[{rambut_kiri} to {rambut_kanan}]")
    
    center_x = fx + int(fw / 2)
    center_y = fy + int(fh / 2)
    axis_x = int(fw * 0.75)
    axis_y = int(fh * 0.95)
    cv2.ellipse(mask_np, (center_x, center_y + int(fh * 0.15)), (axis_x, axis_y), 0, 0, 360, 0, -1)
    print(f"Ellipse Box: x +/- {axis_x}, y +/- {axis_y}")
    
    # Save test mask for inspection
    cv2.imwrite("debug_mask.jpg", mask_np)
    
    # ASCII Art generator for mask
    print("\n--- MASK PREVIEW ---")
    reduced = cv2.resize(mask_np, (64, 32))
    for row in reduced:
        line = ""
        for px in row:
            if px > 200:
                line += "██" # White (Draw AI here)
            elif px > 100:
                line += "▒▒"
            else:
                line += "  " # Black (Protect this)
        print(line)
