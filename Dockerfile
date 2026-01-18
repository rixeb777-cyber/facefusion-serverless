FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Системные либы
RUN apt-get update && apt-get install -y ffmpeg libsm6 libxext6 git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем репозиторий
RUN git clone --depth 1 https://github.com/facefusion/facefusion.git /tmp/ff

# 3. ПЕРЕНОСИМ ВСЁ ИЗ ПОДПАПОК В КОРЕНЬ /app
# Судя по логам, нам нужно вытащить всё на свет
RUN cp -rp /tmp/ff/. . && rm -rf /tmp/ff

# 4. Установка зависимостей
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir runpod requests

# 5. Копируем твой обработчик (он заменит тот, что пришел из git)
COPY handler.py /app/handler.py

# 6. ПРОВЕРКА (теперь точно сработает!)
RUN chmod +x /app/run.py

CMD [ "python3", "-u", "handler.py" ]
