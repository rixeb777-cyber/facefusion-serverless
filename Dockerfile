# 1. Используем стабильный образ с CUDA 11.8
FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

# 2. Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libgl1-mesa-glx \
    libgomp1 \
    python3-tk \
    wget \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 3. Клонируем FaceFusion 3.0.0
RUN git clone --branch 3.0.0 --depth 1 https://github.com/facefusion/facefusion.git .

# 4. Установка библиотек (NumPy Fix)
# Устанавливаем всё одной командой, чтобы зафиксировать версию 1.26.4
RUN pip install --upgrade pip && \
    pip install --no-cache-dir \
    "numpy==1.26.4" \
    "onnxruntime-gpu==1.17.1" \
    "opencv-python>=4.8.0,<5.0.0" \
    "insightface>=0.7.3" \
    "onnx>=1.15.0,<2.0.0" \
    "gradio" "runpod" "tqdm" "requests" "filetype" "pyyaml" "protobuf"

# 5. ПРЕДЗАГРУЗКА ВСЕХ МОДЕЛЕЙ (Чтобы RunPod ничего не качал)
# Мы кладем их в стандартную папку /root/.facefusion/models
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/inswapper_128_fp16.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/inswapper_128_fp16.onnx && \
    curl -L -o /root/.facefusion/models/open_nsfw.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/open_nsfw.onnx && \
    curl -L -o /root/.facefusion/models/yoloface_8n.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/yoloface_8n.onnx && \
    curl -L -o /root/.facefusion/models/arcface_w600k_r50.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/arcface_w600k_r50.onnx && \
    curl -L -o /root/.facefusion/models/gender_age.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/gender_age.onnx

# Проверка, что модели на месте (увидишь в логах сборки)
RUN ls -lh /root/.facefusion/models/

# 6. Копируем твой оптимизированный handler.py
COPY handler.py /app/handler.py

# 7. Настройка окружения для GPU
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=/usr/local/cuda/bin:$PATH
ENV ONNXRUNTIME_EXECUTION_PROVIDERS=CUDAExecutionProvider

CMD ["python", "-u", "handler.py"]