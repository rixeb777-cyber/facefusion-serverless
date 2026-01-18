FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Установка системных либ и git
RUN apt-get update && apt-get install -y ffmpeg libsm6 libxext6 git && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем репозиторий FaceFusion напрямую в текущую папку (.)
# Используем --depth 1 чтобы не качать гигабайты истории гитхаба
RUN git clone --depth 1 https://github.com/facefusion/facefusion.git .

# 3. Установка зависимостей без сохранения кэша (экономим место на диске)
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir runpod requests

# 4. Копируем твой handler.py
COPY handler.py /app/handler.py

# 5. ПРОВЕРКА: Если файла нет, билд выдаст список файлов, и мы увидим ошибку сразу
RUN ls -la /app && chmod +x /app/run.py

CMD [ "python3", "-u", "handler.py" ]
