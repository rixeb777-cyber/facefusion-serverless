# Базовый образ
FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    ffmpeg libgl1-mesa-glx libgomp1 python3-tk wget git curl build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Клонируем FaceFusion 3.0.0
RUN git clone --branch 3.0.0 --depth 1 https://github.com/facefusion/facefusion.git .

# ==============================================================================
# ФИКС CUDA И БИБЛИОТЕК (Теперь с cuDNN для ONNX)
# ==============================================================================
RUN pip install --upgrade pip
RUN pip install --no-cache-dir \
    "numpy==1.26.4" \
    "onnxruntime-gpu==1.17.1" \
    "nvidia-cudnn-cu11==8.9.2.26" \
    "nvidia-cublas-cu11==11.11.3.6" \
    "opencv-python>=4.8.0,<5.0.0" \
    "insightface>=0.7.3" \
    "onnx>=1.15.0,<2.0.0" \
    "gradio" "runpod" "tqdm" "requests" "filetype" "pyyaml" "protobuf"

# Прописываем пути к библиотекам cuDNN, чтобы ONNX их увидел
ENV LD_LIBRARY_PATH=/usr/local/lib/python3.10/dist-packages/nvidia/cudnn/lib:/usr/local/lib/python3.10/dist-packages/nvidia/cublas/lib:/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=/usr/local/cuda/bin:$PATH

# ==============================================================================
# ПРЕДЗАГРУЗКА МОДЕЛЕЙ (Все внутри)
# ==============================================================================
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/inswapper_128_fp16.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/inswapper_128_fp16.onnx && \
    curl -L -o /root/.facefusion/models/open_nsfw.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/open_nsfw.onnx && \
    curl -L -o /root/.facefusion/models/yoloface_8n.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/yoloface_8n.onnx && \
    curl -L -o /root/.facefusion/models/arcface_w600k_r50.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/arcface_w600k_r50.onnx && \
    curl -L -o /root/.facefusion/models/gender_age.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/gender_age.onnx

COPY handler.py /app/handler.py

CMD ["python", "-u", "handler.py"]