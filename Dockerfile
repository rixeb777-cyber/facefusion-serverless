FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. СИСТЕМНЫЕ ЗАВИСИМОСТИ
# Добавляем libglib2.0-0, который часто нужен для CV2 даже в headless режиме
RUN apt-get update && apt-get install -y \
    ffmpeg libsm6 libxext6 libgl1-mesa-glx git curl libgomp1 \
    gfortran libopenblas-dev liblapack-dev libglib2.0-0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. КЛОНИРОВАНИЕ
RUN git clone --depth 1 https://github.com/facefusion/facefusion.git .

# 3. УСТАНОВКА БИБЛИОТЕК (МЕТОД "КУВАЛДА")
RUN python3 -m pip install --upgrade pip

# Шаг А: Даем FaceFusion поставить свои зависимости (пусть ставит что хочет)
RUN python3 -m pip install --no-cache-dir -r requirements.txt || true

# Шаг Б: НАСИЛЬНО ПЕРЕЗАПИСЫВАЕМ НА РАБОЧИЕ ВЕРСИИ
# Используем --force-reinstall, чтобы Docker не спорил
# Важно: opencv-python-headless (для работы без монитора)
RUN python3 -m pip install --force-reinstall --no-cache-dir \
    numpy==1.24.3 \
    scipy==1.10.1 \
    opencv-python-headless==4.8.0.74 \
    onnxruntime-gpu==1.15.1 \
    runpod requests gdown

# 4. МОДЕЛИ (v3.0.0)
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/inswapper_128.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/inswapper_128_fp16.onnx && \
    curl -L -o /root/.facefusion/models/yoloface_8n.onnx https://github.com/facefusion/facefusion-assets/releases/download/models-3.0.0/yoloface_8n.onnx

# 5. СКРИПТ
RUN printf "from facefusion import core\nif __name__ == '__main__':\n    core.cli()" > /app/run.py

COPY handler.py /app/handler.py
ENV PYTHONPATH="/app"
ENV HOME="/root"

CMD [ "python3", "-u", "handler.py" ]
