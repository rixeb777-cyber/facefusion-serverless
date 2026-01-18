FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Системные зависимости
RUN apt-get update && apt-get install -y ffmpeg libsm6 libxext6 curl unzip && rm -rf /var/lib/apt/lists/*

# 2. Скачивание и УМНАЯ распаковка
RUN curl -L https://github.com/facefusion/facefusion/archive/refs/heads/master.zip -o master.zip && \
    unzip master.zip && \
    # Ищем, в какой папке лежит run.py и переносим всё содержимое этой папки в /app
    TARGET_DIR=$(find . -name "run.py" -exec dirname {} \;) && \
    cp -rp $TARGET_DIR/. . && \
    rm -rf facefusion-master master.zip

# 3. Установка Python библиотек
RUN pip install --upgrade pip
RUN pip install requests runpod onnxruntime-gpu insightface opencv-python numpy tqdm psutil scipy

# 4. Копируем твой handler
COPY handler.py /app/handler.py

# 5. Теперь файл 100% на месте
RUN chmod +x /app/run.py

CMD [ "python3", "-u", "handler.py" ]
