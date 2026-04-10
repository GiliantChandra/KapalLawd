#!/usr/bin/env python3
"""
Face Shape Classification Training Script
Trains a CNN model to classify face shapes using MobileNetV2 backbone
"""

import os
import numpy as np
import tensorflow as tf
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping
from sklearn.model_selection import train_test_split
import cv2
import mediapipe as mp
from tqdm import tqdm

class FaceShapeTrainer:
    def __init__(self):
        self.face_shapes = ['Oval', 'Round', 'Square', 'Heart', 'Diamond']
        self.mp_face_mesh = mp.solutions.face_mesh.FaceMesh(
            static_image_mode=True,
            max_num_faces=1,
            min_detection_confidence=0.5
        )

    def load_dataset(self, dataset_path):
        """Load face shape dataset"""
        images = []
        labels = []

        for shape_idx, shape in enumerate(self.face_shapes):
            shape_path = os.path.join(dataset_path, shape.lower())
            if not os.path.exists(shape_path):
                print(f"Warning: {shape_path} not found")
                continue

            for img_file in os.listdir(shape_path):
                if img_file.endswith(('.jpg', '.jpeg', '.png')):
                    img_path = os.path.join(shape_path, img_file)
                    img = cv2.imread(img_path)
                    if img is not None:
                        # Preprocess image
                        img = cv2.resize(img, (224, 224))
                        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                        img = img.astype(np.float32) / 255.0

                        images.append(img)
                        labels.append(shape_idx)

        return np.array(images), np.array(labels)

    def extract_face_features(self, images):
        """Extract facial landmarks as additional features"""
        features = []

        for img in tqdm(images, desc="Extracting face features"):
            rgb_img = (img * 255).astype(np.uint8)
            results = self.mp_face_mesh.process(rgb_img)

            if results.multi_face_landmarks:
                landmarks = results.multi_face_landmarks[0]
                # Extract key landmark coordinates
                landmark_features = []
                for landmark in landmarks.landmark[:100]:  # Use first 100 landmarks
                    landmark_features.extend([landmark.x, landmark.y, landmark.z])

                # Pad or truncate to fixed size
                if len(landmark_features) < 300:
                    landmark_features.extend([0.0] * (300 - len(landmark_features)))
                else:
                    landmark_features = landmark_features[:300]

                features.append(landmark_features)
            else:
                # No face detected, use zeros
                features.append([0.0] * 300)

        return np.array(features)

    def build_model(self):
        """Build CNN model for face shape classification"""
        # Load MobileNetV2 as base
        base_model = MobileNetV2(
            weights='imagenet',
            include_top=False,
            input_shape=(224, 224, 3)
        )

        # Freeze base model layers
        for layer in base_model.layers:
            layer.trainable = False

        # Add custom classification head
        x = base_model.output
        x = GlobalAveragePooling2D()(x)
        x = Dense(1024, activation='relu')(x)
        x = Dropout(0.5)(x)
        x = Dense(512, activation='relu')(x)
        x = Dropout(0.3)(x)
        predictions = Dense(len(self.face_shapes), activation='softmax')(x)

        model = Model(inputs=base_model.input, outputs=predictions)

        return model

    def train(self, dataset_path, epochs=50, batch_size=32):
        """Train the face shape classification model"""
        print("Loading dataset...")
        images, labels = self.load_dataset(dataset_path)

        if len(images) == 0:
            raise ValueError("No images found in dataset")

        print(f"Dataset loaded: {len(images)} images")

        # Split dataset
        X_train, X_test, y_train, y_test = train_test_split(
            images, labels, test_size=0.2, random_state=42, stratify=labels
        )

        # Convert labels to categorical
        y_train = tf.keras.utils.to_categorical(y_train, len(self.face_shapes))
        y_test = tf.keras.utils.to_categorical(y_test, len(self.face_shapes))

        # Build model
        model = self.build_model()

        # Compile model
        model.compile(
            optimizer=Adam(learning_rate=0.001),
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )

        # Callbacks
        checkpoint = ModelCheckpoint(
            'face_shape_classifier.h5',
            monitor='val_accuracy',
            save_best_only=True,
            mode='max'
        )

        early_stopping = EarlyStopping(
            monitor='val_accuracy',
            patience=10,
            restore_best_weights=True
        )

        # Train model
        print("Training model...")
        history = model.fit(
            X_train, y_train,
            validation_data=(X_test, y_test),
            epochs=epochs,
            batch_size=batch_size,
            callbacks=[checkpoint, early_stopping]
        )

        # Evaluate model
        loss, accuracy = model.evaluate(X_test, y_test)
        print(f"Test accuracy: {accuracy:.4f}")

        return model, history

def main():
    trainer = FaceShapeTrainer()

    # Assuming dataset is organized as: dataset/face_shape/image.jpg
    dataset_path = "dataset"

    if not os.path.exists(dataset_path):
        print("Dataset not found. Creating sample structure...")
        os.makedirs(dataset_path, exist_ok=True)
        for shape in ['oval', 'round', 'square', 'heart', 'diamond']:
            os.makedirs(os.path.join(dataset_path, shape), exist_ok=True)
        print("Please add face images to the dataset folders and run again.")
        return

    try:
        model, history = trainer.train(dataset_path)
        print("Training completed successfully!")
        print("Model saved as: face_shape_classifier.h5")
    except Exception as e:
        print(f"Training failed: {e}")

if __name__ == "__main__":
    main()