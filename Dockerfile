FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Системные зависимости
RUN apt-get update && apt-get install -y ffmpeg libsm6 libxext6 git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем проект
RUN git clone --depth 1 https://github.com/facefusion/facefusion.git /tmp/ff

# 3. ПЕРЕНОСИМ ВСЁ ИЗ ПОДПАПОК В /app
# Это гарантирует, что run.py окажется в /app/run.py
RUN cp -rp /tmp/ff/. . && rm -rf /tmp/ff

# 4. Установка библиотек
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir runpod requests

# 5. Копируем твой handler.py
COPY handler.py /app/handler.py

# 6. ПРОВЕРКА: Если файла все еще нет, мы его найдем через find
RUN if [ ! -f /app/run.py ]; then \
    echo "🔍 run.py не найден в корне, ищем в подпапках..." && \
    FOUND_PATH=$(find . -name "run.py" | head -n 1) && \
    cp "$FOUND_PATH" /app/run.py; \
    fi

# 7. Теперь chmod точно сработает
RUN chmod +x /app/run.py

CMD [ "python3", "-u", "handler.py" ]
