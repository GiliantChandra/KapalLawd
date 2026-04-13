#!/usr/bin/env python3
"""
Face Shape Classification Training Script v2.0 (Dual-Input Architecture)
Menggabungkan kekuatan MobileNetV2 (Pixel Wajah) & MediaPipe FaceMesh (Struktur Tulang).
Dilengkapi Pipeline Augmentasi Keras secara Native.
"""

import os
import numpy as np
import tensorflow as tf
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout, Input, Concatenate
from tensorflow.keras.layers import RandomFlip, RandomRotation, RandomZoom, RandomBrightness
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping, ReduceLROnPlateau
from sklearn.model_selection import train_test_split
import cv2
import mediapipe as mp
from tqdm import tqdm

class FaceShapeTrainer:
    def __init__(self):
        self.face_shapes = ['Oval', 'Round', 'Square', 'Heart', 'Oblong']
        self.mp_face_mesh = mp.solutions.face_mesh.FaceMesh(
            static_image_mode=True,
            max_num_faces=1,
            min_detection_confidence=0.5
        )

    def load_and_preprocess_dataset(self, dataset_path):
        """Memuat Foto RGB sekaligus menyedot titik saraf dari MediaPipe di iterasi yang sama 
        untuk menghemat kekuatan CPU dan Ram secara drastis saat Training.
        """
        images = []
        landmarks_list = []
        labels = []

        print("🔮 [PROSES I] Menggali dataset dan merekam bentuk tulang wajah melalui MediaPipe...")
        for shape_idx, shape in enumerate(self.face_shapes):
            # Karena Linux Case-Sensitive, pastikan nama foldernya sama PERSIS kapitalisasinya
            shape_path = os.path.join(dataset_path, shape)
            if not os.path.exists(shape_path):
                print(f"⚠️ Peringatan: Folder Wajah {shape_path} Kosong/Tidak Ditemukan")
                continue

            file_list = [f for f in os.listdir(shape_path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
            
            for img_file in tqdm(file_list, desc=f"Menyedot Saraf Wajah ({shape})", unit="foto"):
                img_path = os.path.join(shape_path, img_file)
                img = cv2.imread(img_path)
                if img is None: continue

                # 1. Konversi Warna RGB Alami untuk MediaPipe
                rgb_img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                
                # 2. Pengeboran 300 Kordinat Titik Tulang Wajah (Face Mesh Landmark)
                results = self.mp_face_mesh.process(rgb_img)
                landmark_features = []
                if results.multi_face_landmarks:
                    landmarks = results.multi_face_landmarks[0]
                    for landmark in landmarks.landmark[:100]:  # Cukup 100 Landmark inti (Rahang, Dagu, Dahi)
                        landmark_features.extend([landmark.x, landmark.y, landmark.z])
                else:
                    # Jika wajah tidak ada/tertutup gelap, isi dummy pelengkap 0
                    landmark_features = [0.0] * 300 
                
                # 3. Formatisasi Pixel Gambar (Size 224 MobileNet & Konversi ke 0..1 Normalisasi)
                img_resized = cv2.resize(rgb_img, (224, 224))
                img_normalized = img_resized.astype(np.float32) / 255.0

                images.append(img_normalized)
                landmarks_list.append(landmark_features)
                labels.append(shape_idx)

        return np.array(images), np.array(landmarks_list), np.array(labels)

    def build_hybrid_model(self):
        """Membangun Arsitektur Neural Ganda"""
        print("🧠 [PROSES II] Merakit Struktur Neural Network Dual-Input...")
        
        # ================= PINTU MASUK 1 (FOTO RGB) =================
        img_input = Input(shape=(224, 224, 3), name="image_input")
        
        # Menambahkan Lensa Augmentasi agar Otak AI Tahan Banting & Tidak Menghafal Soal (Overfitting)
        x_aug = RandomFlip("horizontal")(img_input)
        x_aug = RandomRotation(0.1)(x_aug)
        x_aug = RandomZoom(0.1)(x_aug)
        
        # Masuk ke Otak Raksasa MobileNetV2
        base_model = MobileNetV2(weights='imagenet', include_top=False)
        base_model.trainable = False # Gembok ototnya agar tidak rusak saat masa sekolah duka
        
        x = base_model(x_aug)
        x = GlobalAveragePooling2D()(x)
        x = Dense(512, activation='relu')(x)
        x = Dropout(0.4)(x)

        # ================= PINTU MASUK 2 (VEKTOR TULANG MEDIA-PIPE) =================
        landmark_input = Input(shape=(300,), name="landmark_input")
        y = Dense(256, activation='relu')(landmark_input)
        y = Dropout(0.3)(y)
        y = Dense(128, activation='relu')(y)

        # ================= TITIK PERTEMUAN 2 DIMENSI =================
        combined = Concatenate()([x, y])
        
        # Papan Kesimpulan Akhir
        z = Dense(256, activation='relu')(combined)
        z = Dropout(0.3)(z)
        predictions = Dense(len(self.face_shapes), activation='softmax')(z)

        # Penyatuan Model (Rongga Mesin Utama)
        model = Model(inputs=[img_input, landmark_input], outputs=predictions)
        return model

    def train(self, dataset_path, epochs=100, batch_size=32):
        """Merangkum Pelaksanaan Kompetisi AI Belajar"""
        # 1. Sedot Matriks Data
        images, landmarks, labels = self.load_and_preprocess_dataset(dataset_path)

        if len(images) == 0:
            raise ValueError("Data Latihan Anda Kosong! Harap berikan gambar ke dalam folder dataset.")

        print(f"✅ Amunisi siap: Total {len(images)} gambar berhasil direkam beserta Kordinat Titik Wajahnya.")

        # 2. Partisi Data Sekolah vs Ujian (80% vs 20%)
        X_img_train, X_img_test, X_lm_train, X_lm_test, y_train, y_test = train_test_split(
            images, landmarks, labels, test_size=0.2, random_state=42, stratify=labels
        )

        # Terjemahan Format Kategori Wajah ke Kode Binary Matematika Sparse
        y_train_cat = tf.keras.utils.to_categorical(y_train, len(self.face_shapes))
        y_test_cat = tf.keras.utils.to_categorical(y_test, len(self.face_shapes))

        # 3. Panggil Bengkel Pencetak Model
        model = self.build_hybrid_model()

        # Konfigurasi Kacamata Guru (Adam Optimizer)
        model.compile(
            optimizer=Adam(learning_rate=0.001),
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )

        # 4. Asisten Pengawas Training (Callbacks)
        checkpoint = ModelCheckpoint(
            'face_shape_hybrid_classifier.h5', 
            monitor='val_accuracy', 
            save_best_only=True, 
            mode='max'
        )
        early_stopping = EarlyStopping(
            monitor='val_accuracy', 
            patience=15, 
            restore_best_weights=True
        )
        reduce_lr = ReduceLROnPlateau(
            monitor='val_loss', 
            factor=0.5, 
            patience=5, 
            min_lr=1e-6
        )

        # 5. PELAKSANAAN TRAINING (Eksplosi Kalkulasi Komputasi)
        print("🎯 [PROSES III] Memulai Pertandingan Memori AI! (Training Process)...")
        history = model.fit(
            [X_img_train, X_lm_train], y_train_cat,    # Menyusui Data Visual x Data MediaPipe Multi
            validation_data=([X_img_test, X_lm_test], y_test_cat),
            epochs=epochs,
            batch_size=batch_size,
            callbacks=[checkpoint, early_stopping, reduce_lr]
        )

        # 6. Ujian Lulus (Evaluasi Akhir Score AI)
        loss, accuracy = model.evaluate([X_img_test, X_lm_test], y_test_cat)
        print(f"🏆 Akurasi Tes Kelulusan Model: {accuracy:.4f}")

        return model, history


def main():
    trainer = FaceShapeTrainer()
    dataset_path = "dataset"

    if not os.path.exists(dataset_path):
        print("⚠️ Folder Matrix Dataset Tidak Ditemukan. Membuat pilar pondasi folder..")
        os.makedirs(dataset_path, exist_ok=True)
        for shape in ['oval', 'round', 'square', 'heart', 'diamond']:
            os.makedirs(os.path.join(dataset_path, shape), exist_ok=True)
        print("💡 Harap masukkan foto wajah Anda ke dalam folder /dataset baru dan jalankan kembali script ini.")
        return

    try:
        model, history = trainer.train(dataset_path)
        print("🎉 SELAMAT! Model Kecerdasan Hybrid Anda Lulus secara Sempurna!")
        print("💾 File Sistem Inti Otak AI tersimpan sebagai: `face_shape_hybrid_classifier.h5`")
    except Exception as e:
        import traceback
        print(f"🛑 Training meledak sebelum garis akhir: {e}")
        traceback.print_exc()

if __name__ == "__main__":
    main()