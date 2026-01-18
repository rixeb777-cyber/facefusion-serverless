FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Системные зависимости
RUN apt-get update && apt-get install -y ffmpeg libsm6 libxext6 curl unzip && rm -rf /var/lib/apt/lists/*

# 2. Скачивание и принудительный перенос файлов в корень /app
RUN curl -L https://github.com/facefusion/facefusion/archive/refs/heads/master.zip -o master.zip && \
    unzip master.zip && \
    cp -rp facefusion-master/. . && \
    rm -rf facefusion-master master.zip

# 3. Установка Python библиотек
RUN pip install --upgrade pip
RUN pip install requests runpod onnxruntime-gpu insightface opencv-python numpy tqdm psutil scipy

# 4. Копируем handler (он перезапишет дефолтный, если он там был)
COPY handler.py /app/handler.py

# 5. Проверка наличия файла и выдача прав
RUN ls -la /app && chmod +x /app/run.py

CMD [ "python3", "-u", "handler.py" ]
