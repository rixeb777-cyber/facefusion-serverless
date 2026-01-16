FROM runpod/base:0.4.0-cuda11.8.0

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    python3-pip \
    ffmpeg \
    libsm6 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем базовые библиотеки сразу
RUN pip install --no-cache-dir requests runpod

# Скачиваем код FaceFusion как ZIP (обход ошибки git clone)
WORKDIR /app
RUN curl -L https://github.com/facefusion/facefusion/archive/refs/heads/master.zip -o master.zip && \
    unzip master.zip && \
    cp -r facefusion-master/* . && \
    rm -rf facefusion-master master.zip

# Установка зависимостей FaceFusion
RUN pip install --no-cache-dir -r requirements.txt

# Копируем твой handler.py
COPY handler.py /app/handler.py

CMD [ "python3", "-u", "handler.py" ]
