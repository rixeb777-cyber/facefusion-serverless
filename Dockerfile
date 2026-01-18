FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Системные зависимости + библиотеки NVIDIA
RUN apt-get update && apt-get install -y \
    ffmpeg libsm6 libxext6 libgl1-mesa-glx git curl libgomp1 \
    libglib2.0-0 libcudnn8 libcudnn8-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем проект
RUN git clone --branch 3.0.0 --depth 1 https://github.com/facefusion/facefusion.git .

# 3. Python и библиотеки
RUN python3 -m pip install --upgrade pip

# КРУТО: Ставим ONNX, который гарантированно работает с CUDA 11.8
RUN python3 -m pip uninstall -y onnxruntime onnxruntime-gpu && \
    python3 -m pip install onnxruntime-gpu==1.17.1

# Ставим зависимости FaceFusion
RUN python3 -m pip install --no-cache-dir -r requirements.txt || echo "Done"
RUN python3 -m pip install runpod requests gdown

# 4. Модели
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/inswapper_128_fp16.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/inswapper_128_fp16.onnx && \
    curl -L -o /root/.facefusion/models/yoloface_8n.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.onnx

# 5. Фикс путей (самое важное)
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
ENV ONNXRUNTIME_EXECUTION_PROVIDERS="CUDAExecutionProvider"

COPY handler.py /app/handler.py
RUN printf "from facefusion import core\nif __name__ == '__main__':\n    core.cli()" > /app/run.py

CMD [ "python3", "-u", "handler.py" ]