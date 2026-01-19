FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

# Системные зависимости
RUN apt-get update && apt-get install -y \
    ffmpeg libgl1-mesa-glx libgomp1 python3-tk wget git curl build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Клонируем FaceFusion
RUN git clone --branch 3.0.0 --depth 1 https://github.com/facefusion/facefusion.git .

# Фикс библиотек (NumPy) - оставляем этот блок, он работает КРУТО
RUN pip install --upgrade pip
RUN pip install --no-cache-dir \
    "numpy==1.26.4" \
    "onnxruntime-gpu==1.17.1" \
    "opencv-python>=4.8.0,<5.0.0" \
    "insightface>=0.7.3" \
    "onnx>=1.15.0,<2.0.0" \
    "gradio" "runpod" "tqdm" "requests" "filetype" "pyyaml" "protobuf"

# Переменные среды для CUDA
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=/usr/local/cuda/bin:$PATH

COPY handler.py /app/handler.py

CMD ["python", "-u", "handler.py"]