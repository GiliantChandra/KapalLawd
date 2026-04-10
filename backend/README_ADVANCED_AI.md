# Advanced AI Hair Styling System

This backend implements a state-of-the-art AI-powered hair styling recommendation system using advanced computer vision and machine learning techniques.

## 🧠 AI Pipeline Overview

### 1. Face Detection and Segmentation
- **MediaPipe Face Mesh**: 468+ facial landmark detection for precise face mapping
- **Dlib**: 68-point facial landmark predictor for additional accuracy
- **DeepLabV3**: Advanced semantic segmentation to separate face from background
- **Fallback**: Haar cascades for reliable face detection

### 2. Face Shape Classification
- **Geometric Analysis**: Mathematical ratios of forehead width, cheekbone width, jaw width, and face height
- **CNN Classification**: MobileNetV2-based deep learning model for automated face shape recognition
- **Supported Shapes**: Oval, Round, Square, Heart, Diamond

### 3. Intelligent Recommendation Engine
- **Knowledge-Based**: Expert rules from professional hair stylists
- **Content-Based Filtering**: Feature similarity matching with user preferences
- **Compatibility Scoring**: Face shape to hairstyle matching algorithms

### 4. Virtual Try-On Visualization
- **GAN-Based**: StyleGAN architecture for realistic hair transfer
- **Stable Diffusion Inpainting**: High-quality hair generation and blending
- **Seamless Integration**: Advanced image processing for natural results

## 🚀 Key Features

### Advanced Face Analysis
- Precise facial landmark detection (468+ points)
- Real-time face segmentation
- Multi-modal face shape classification
- Robust error handling and fallbacks

### Smart Recommendations
- Face-shape optimized hairstyle suggestions
- Compatibility scoring system
- Multiple recommendation approaches
- Personalized styling advice

### Professional-Quality Results
- 8K resolution output
- Razor-sharp focus and detail
- Natural hair strand rendering
- Seamless face-hair blending

## 📋 Requirements

### Python Dependencies
```
mediapipe>=0.10.0
dlib>=19.24.0
tensorflow>=2.13.0
keras>=2.13.0
scikit-learn>=1.3.0
opencv-python-headless>=4.8.0
torch>=2.0.0
torchvision>=0.15.0
diffusers>=0.20.0
transformers>=4.30.0
```

### Model Files
- `shape_predictor_68_face_landmarks.dat`: Dlib facial landmark predictor
- `face_shape_classifier.h5`: Trained CNN model for face shape classification (optional)

## 🛠️ Setup Instructions

1. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Download Models**
   ```bash
   chmod +x setup_models.sh
   ./setup_models.sh
   ```

3. **Train Face Shape Classifier** (Optional)
   ```bash
   python train_face_shape_classifier.py
   ```

## 🔧 API Usage

### Generate Hairstyle
```python
POST /generate-hairstyle
Form Data:
- user_id: str
- style_name: str
- image: UploadFile

Response:
{
    "image_base64": "base64_encoded_image",
    "face_shape": "Oval|Round|Square|Heart|Diamond",
    "style_applied": "Middle Part",
    "recommendations": [...],
    "analysis_details": {...}
}
```

## 🎯 Supported Hairstyles

- **Middle Part**: Symmetrical center parting
- **Side Part**: Elegant side parting
- **French Crop**: Short sides with textured fringe
- **Faux Hawk**: Spiked crest with short sides
- **Buzz Cut**: Very short military style
- **Mullet**: Short top/sides, long back

## 📊 Face Shape Compatibility

| Face Shape | Best Styles | Avoid |
|------------|-------------|-------|
| Oval | All styles | None |
| Round | Faux Hawk, Mullet | Middle Part |
| Square | Side Part, Buzz Cut | French Crop |
| Heart | French Crop, Side Part | Middle Part |
| Diamond | French Crop, Middle Part | Buzz Cut |

## 🔬 Technical Details

### Face Landmarking Process
1. MediaPipe Face Mesh processes RGB image
2. Extracts 468+ facial landmarks
3. Converts normalized coordinates to pixels
4. Validates landmark quality and coverage

### Geometric Classification
- Forehead width / Cheekbone width ratio
- Cheekbone width / Jaw width ratio
- Cheekbone width / Face height ratio
- Decision tree based classification

### Segmentation Pipeline
1. DeepLabV3 semantic segmentation
2. Face class extraction (PASCAL VOC class 15)
3. Morphological operations for cleanup
4. Gaussian blur for smooth transitions

### Recommendation Algorithm
1. Knowledge-based filtering using expert rules
2. Content-based similarity matching
3. Collaborative filtering (future enhancement)
4. Weighted scoring and ranking

## 🚀 Performance Optimizations

- **GPU Acceleration**: CUDA support for TensorFlow and PyTorch
- **Model Caching**: Singleton pattern for model instances
- **Memory Management**: Automatic cleanup and optimization
- **Fallback Systems**: Graceful degradation on model failures
- **Batch Processing**: Efficient image preprocessing pipelines

## 🔒 Privacy & Security

- **Ephemeral Processing**: Images deleted after processing
- **No Data Storage**: User images not persisted
- **Secure Transmission**: Base64 encoding for safe transfer
- **Error Handling**: Comprehensive exception management

## 📈 Future Enhancements

- [ ] StyleGAN-based virtual try-on
- [ ] ARCore integration for mobile AR
- [ ] User preference learning system
- [ ] Multi-angle hairstyle visualization
- [ ] Real-time video processing
- [ ] Collaborative filtering from user data