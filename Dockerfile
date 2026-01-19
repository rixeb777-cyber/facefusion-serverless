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

# Установка Python зависимостей из requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Принудительная установка совместимых версий для избежания конфликтов
RUN pip uninstall -y onnxruntime onnxruntime-gpu && \
    pip install --no-cache-dir numpy==1.26.4 && \
    pip install --no-cache-dir onnxruntime-gpu==1.17.1

# Установка RunPod SDK для работы с serverless
RUN pip install --no-cache-dir runpod

# Создание директории для моделей
RUN mkdir -p /root/.facefusion/models

# Предзагрузка всех необходимых моделей для избежания таймаутов при первом запуске
# Используем правильные URL из официального репозитория
RUN cd /root/.facefusion/models && \
    wget --no-check-certificate https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/inswapper_128_fp16.onnx && \
    wget --no-check-certificate https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.onnx && \
    wget --no-check-certificate https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/arcface_w600k_r50.onnx && \
    wget --no-check-certificate https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/face_landmarker_68_5.onnx

# Копирование обработчика
COPY handler.py /app/handler.py

# Настройка переменных окружения для корректной работы CUDA
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=/usr/local/cuda/bin:$PATH

# Запуск handler при старте контейнера
CMD ["python", "-u", "handler.py"]