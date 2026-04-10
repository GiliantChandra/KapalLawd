#!/bin/bash
# Setup script for advanced AI models

echo "Setting up advanced AI models for KapalLawd..."

# Create models directory
mkdir -p models

# Download Dlib shape predictor (68-point face landmarks)
echo "Downloading Dlib shape predictor..."
wget -O models/shape_predictor_68_face_landmarks.dat.bz2 "http://dlib.net/files/shape_predictor_68_face_landmarks.dat.bz2"
bunzip2 models/shape_predictor_68_face_landmarks.dat.bz2

# Download face shape classifier weights (placeholder - would need actual trained model)
echo "Note: Face shape classifier weights need to be trained separately"
echo "Using base MobileNetV2 weights for now"

echo "Setup complete!"
echo "Make sure to install all Python dependencies:"
echo "pip install -r requirements.txt"