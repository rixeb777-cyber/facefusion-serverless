# Базовый образ с CUDA 11.8 и PyTorch
FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    ffmpeg libgl1-mesa-glx libgomp1 python3-tk wget git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Клонирование FaceFusion
RUN git clone --branch 3.0.0 --depth 1 https://github.com/facefusion/facefusion.git .

# Установка зависимостей
RUN pip install --no-cache-dir -r requirements.txt
RUN pip uninstall -y onnxruntime onnxruntime-gpu && \
    pip install --no-cache-dir numpy==1.26.4 onnxruntime-gpu==1.17.1 runpod

# Создание директорий для моделей (в разных местах для надежности)
RUN mkdir -p /root/.facefusion/models && mkdir -p /.facefusion/models

# Предзагрузка моделей (Ссылки обновлены до 3.0.0)
RUN cd /root/.facefusion/models && \
    wget -q https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/inswapper_128_fp16.onnx && \
    wget -q https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.onnx && \
    wget -q https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/arcface_w600k_r50.onnx && \
    wget -q https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/face_landmarker_68_5.onnx

# Копируем модели в корень на всякий случай
RUN cp -r /root/.facefusion/* /.facefusion/ || true

COPY handler.py /app/handler.py

# Переменные окружения для CUDA
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
ENV PYTHONUNBUFFERED=1

CMD ["python", "-u", "handler.py"]