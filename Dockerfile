FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Максимальная очистка и установка системных либ
RUN apt-get update && apt-get install -y ffmpeg libsm6 libxext6 git curl unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем репозиторий
RUN git clone --depth 1 https://github.com/facefusion/facefusion.git /tmp/facefusion-repo

# 3. ПЕРЕНОСИМ ФАЙЛЫ ПРАВИЛЬНО
# Мы копируем содержимое скачанной папки в наш /app
RUN cp -rp /tmp/facefusion-repo/. /app/ && rm -rf /tmp/facefusion-repo

# 4. Установка зависимостей (без кэша, чтобы не забить место)
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir runpod requests

# 5. Копируем твой handler.py
COPY handler.py /app/handler.py

# 6. ПРОВЕРКА И ПРАВА (Если файла нет, билд покажет содержимое папки)
RUN ls -la /app && if [ -f /app/run.py ]; then chmod +x /app/run.py; else echo "ERROR: run.py NOT FOUND" && exit 1; fi

CMD [ "python3", "-u", "handler.py" ]
