# Базовый образ с CUDA 11.8 и PyTorch для стабильной работы с RTX картами
FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libgl1-mesa-glx \
    libgomp1 \
    python3-tk \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# Установка рабочей директории
WORKDIR /app

# Клонирование FaceFusion
RUN git clone https://github.com/facefusion/facefusion.git .

# Сначала устанавливаем numpy нужной версии
RUN pip install --no-cache-dir numpy==1.26.4

# Удаляем конфликтующие пакеты если есть
RUN pip uninstall -y onnxruntime onnxruntime-gpu || true

# Устанавливаем onnxruntime-gpu для CUDA 11.8
RUN pip install --no-cache-dir onnxruntime-gpu==1.17.1

# Устанавливаем остальные зависимости, игнорируя конфликты версий
RUN pip install --no-cache-dir -r requirements.txt --no-deps || true

# Устанавливаем основные зависимости FaceFusion вручную
RUN pip install --no-cache-dir \
    opencv-python \
    pillow \
    tqdm \
    requests \
    gradio \
    insightface \
    onnx

# Установка RunPod SDK для работы с serverless
RUN pip install --no-cache-dir runpod

# Создание директории для моделей
RUN mkdir -p /root/.facefusion/models

# Скачиваем модели напрямую (используем корректные URL)
RUN wget -O /root/.facefusion/models/inswapper_128_fp16.onnx \
    "https://huggingface.co/deepinsight/inswapper/resolve/main/inswapper_128_fp16.onnx" && \
    wget -O /root/.facefusion/models/yoloface_8n.onnx \
    "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.onnx" && \
    wget -O /root/.facefusion/models/arcface_w600k_r50.onnx \
    "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/arcface_w600k_r50.onnx" && \
    wget -O /root/.facefusion/models/face_landmarker_68_5.onnx \
    "https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/face_landmarker_68_5.onnx"

# Копирование обработчика
COPY handler.py /app/handler.py

# Настройка переменных окружения для корректной работы CUDA
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=/usr/local/cuda/bin:$PATH

# Запуск handler при старте контейнера
CMD ["python", "-u", "handler.py"]