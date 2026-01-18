FROM runpod/base:0.4.0-cuda11.8.0

# 1. Системные зависимости
RUN apt-get update && apt-get install -y \
    python3-pip ffmpeg libsm6 libxext6 curl unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Скачиваем FaceFusion напрямую в /app
RUN curl -L https://github.com/facefusion/facefusion/archive/refs/heads/master.zip -o master.zip && \
    unzip master.zip && \
    cp -r facefusion-master/* . && \
    rm -rf facefusion-master master.zip

# 3. Установка зависимостей (Добавляем gdown для моделей)
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install requests runpod onnxruntime-gpu numpy opencv-python insightface psutil tqdm scipy

# 4. Копируем твой handler прямо к файлу run.py
COPY handler.py /app/handler.py

CMD [ "python3", "-u", "handler.py" ]

