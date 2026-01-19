# Используем проверенный образ
FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libgl1-mesa-glx \
    libgomp1 \
    python3-tk \
    wget \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Клонирование FaceFusion
RUN git clone --branch 3.0.0 --depth 1 https://github.com/facefusion/facefusion.git .

# --- КРИТИЧЕСКИЙ БЛОК: ФИКС NUMPY ---
# Удаляем всё, что может конфликтовать
RUN pip uninstall -y numpy onnxruntime onnxruntime-gpu 2>/dev/null || true

# Ставим ПРАВИЛЬНЫЙ NumPy первым и фиксируем его для всех последующих установок
RUN pip install --no-cache-dir "numpy==1.26.4"

# Ставим ONNX Runtime GPU, который дружит с этим NumPy
RUN pip install --no-cache-dir "onnxruntime-gpu==1.17.1"

# Ставим всё остальное, ПРИНУДИТЕЛЬНО запрещая обновлять numpy
RUN pip install --no-cache-dir \
    "opencv-python>=4.8.0,<5.0.0" \
    "pillow>=10.0.0,<11.0.0" \
    "insightface>=0.7.3" \
    "onnx>=1.15.0,<2.0.0" \
    "tqdm" "requests" "filetype" "pyyaml" "protobuf" "gdown" "inquirer" "gradio" runpod

# --- ПРЕДЗАГРУЗКА МОДЕЛЕЙ (Чтобы не упасть на хешах) ---
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/open_nsfw.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/open_nsfw.onnx && \
    curl -L -o /root/.facefusion/models/inswapper_128_fp16.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/inswapper_128_fp16.onnx && \
    curl -L -o /root/.facefusion/models/yoloface_8n.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/yoloface_8n.onnx

COPY handler.py /app/handler.py

ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=/usr/local/cuda/bin:$PATH

CMD ["python", "-u", "handler.py"]