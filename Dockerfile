FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Системные зависимости для OpenCV и Git
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsm6 \
    libxext6 \
    libgl1-mesa-glx \
    git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем проект (как мы и договаривались)
RUN git clone --depth 1 https://github.com/facefusion/facefusion.git .

# 3. Установка библиотек (Добавляем scipy и другие недостающие части)
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir runpod requests opencv-python onnxruntime-gpu scipy numba scikit-learn && \
    python3 -m pip install --no-cache-dir -r requirements.txt --ignore-installed || true

# 4. Создаем наш пусковой run.py
RUN printf "from facefusion import core\nif __name__ == '__main__':\n    core.cli()" > /app/run.py

# 5. Копируем handler.py и даем права
COPY handler.py /app/handler.py
RUN chmod +x /app/run.py

# Путь для Python
ENV PYTHONPATH="/app"

CMD [ "python3", "-u", "handler.py" ]
