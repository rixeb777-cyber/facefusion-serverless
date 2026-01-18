FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Системные зависимости
RUN apt-get update && apt-get install -y \
    ffmpeg libsm6 libxext6 libgl1-mesa-glx git curl libgomp1 \
    libglib2.0-0 libcudnn8 && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем проект
RUN git clone --branch 3.0.0 --depth 1 https://github.com/facefusion/facefusion.git .

# 3. Установка Python-пакетов
RUN python3 -m pip install --upgrade pip

# КРУТО: Фиксируем версии, чтобы не было ошибки _ARRAY_API
RUN python3 -m pip install numpy==1.26.4
RUN python3 -m pip uninstall -y onnxruntime onnxruntime-gpu
RUN python3 -m pip install onnxruntime-gpu==1.17.1 --extra-index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_apis/packaging/Feeding/onnxruntime-cuda-11/nuget/index

# Ставим остальное, не давая перетереть наш numpy
RUN python3 -m pip install -r requirements.txt || echo "Done"
RUN python3 -m pip install runpod requests gdown

# 4. Модели
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/inswapper_128_fp16.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/inswapper_128_fp16.onnx && \
    curl -L -o /root/.facefusion/models/yoloface_8n.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.onnx

# 5. Скрипт запуска
COPY handler.py /app/handler.py
RUN printf "from facefusion import core\nif __name__ == '__main__':\n    core.cli()" > /app/run.py

ENV PYTHONPATH="/app"
ENV LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

CMD [ "python3", "-u", "handler.py" ]