FROM runpod/base:0.4.0-cuda11.8.0

# 1. Системные зависимости
RUN apt-get update && apt-get install -y \
    curl unzip python3-pip ffmpeg libsm6 libxext6 \
    && rm -rf /var/lib/apt/lists/*

# 2. КРИТИЧЕСКИ ВАЖНО: Ставим библиотеки ДО скачивания кода
RUN pip install --no-cache-dir requests runpod

# 3. Скачиваем FaceFusion (v50)
WORKDIR /app
RUN curl -L https://github.com/facefusion/facefusion/archive/refs/heads/master.zip -o master.zip && \
    unzip master.zip && \
    cp -r facefusion-master/* . && \
    rm -rf facefusion-master master.zip

# 4. Остальные зависимости
RUN pip install --no-cache-dir -r requirements.txt

# 5. Твой обработчик
COPY handler.py /app/handler.py

CMD [ "python3", "-u", "handler.py" ]
