FROM runpod/base:0.4.0-cuda11.8.0

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    python3-pip \
    ffmpeg \
    libsm6 \
    libxext6 \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Обновляем pip и ставим базовые либы для RunPod
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install requests runpod

WORKDIR /app

# Скачиваем FaceFusion
RUN curl -L https://github.com/facefusion/facefusion/archive/refs/heads/master.zip -o master.zip && \
    unzip master.zip && \
    cp -r facefusion-master/* . && \
    rm -rf facefusion-master master.zip

# Установка зависимостей с игнорированием проблемных версий
RUN python3 -m pip install --no-cache-dir -r requirements.txt --prefer-binary

COPY handler.py /app/handler.py

CMD [ "python3", "-u", "handler.py" ]
