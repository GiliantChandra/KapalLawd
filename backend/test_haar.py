import cv2
import os

img_path = "temp_resized.jpg"
img_bgr = cv2.imread(img_path)
gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)

cascades = [
    'haarcascade_frontalface_default.xml',
    'haarcascade_frontalface_alt.xml',
    'haarcascade_frontalface_alt2.xml',
    'haarcascade_frontalface_alt_tree.xml',
    'haarcascade_profileface.xml'
]

for c_name in cascades:
    cascade_path = cv2.data.haarcascades + c_name
    if not os.path.exists(cascade_path):
        continue
    cascade = cv2.CascadeClassifier(cascade_path)
    faces = cascade.detectMultiScale(gray, scaleFactor=1.05, minNeighbors=3)
    print(f"{c_name}: {len(faces)} faces found.")
    for f in faces:
        print(f"  -> {f}")
