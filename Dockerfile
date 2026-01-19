# Базовый образ (Тот же самый, проверенный)
FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

# Системные зависимости
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

# Клонируем FaceFusion 3.0.0
RUN git clone --branch 3.0.0 --depth 1 https://github.com/facefusion/facefusion.git .

# ==============================================================================
# ШАГ 1: УМНАЯ УСТАНОВКА (Лечим NumPy)
# ==============================================================================
RUN pip uninstall -y numpy onnxruntime onnxruntime-gpu insightface 2>/dev/null || true
RUN pip install --upgrade pip

# Ставим всё одной пачкой. Pip сам подберет версии так, чтобы NumPy остался 1.26.4
RUN pip install --no-cache-dir \
    "numpy==1.26.4" \
    "onnxruntime-gpu==1.17.1" \
    "opencv-python>=4.8.0,<5.0.0" \
    "pillow>=10.0.0,<11.0.0" \
    "insightface>=0.7.3" \
    "onnx>=1.15.0,<2.0.0" \
    "tqdm" "requests" "filetype" "pyyaml" "protobuf" "gdown" "inquirer" "gradio" "runpod"

# Настраиваем окружение, чтобы скрипт видел видеокарту
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=/usr/local/cuda/bin:$PATH
ENV ONNXRUNTIME_EXECUTION_PROVIDERS=CUDAExecutionProvider

# ==============================================================================
# ШАГ 2: АВТО-ЗАГРУЗКА МОДЕЛЕЙ (Лечим ошибку хеша)
# ==============================================================================
# Эта команда сама скачает правильные файлы и положит их куда надо.
# Никаких ошибок "Hash mismatch"!
RUN python facefusion.py force-download

COPY handler.py /app/handler.py

CMD ["python", "-u", "handler.py"]