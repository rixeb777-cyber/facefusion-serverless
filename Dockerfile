FROM runpod/base:0.4.0-cuda11.8.0

WORKDIR /app

# 1. Системные зависимости
RUN apt-get update && apt-get install -y ffmpeg libsm6 libxext6 libgl1-mesa-glx git curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Клонируем проект
RUN git clone --depth 1 https://github.com/facefusion/facefusion.git .

# 3. Установка библиотек
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir runpod requests opencv-python onnxruntime-gpu scipy numba scikit-learn gdown && \
    python3 -m pip install --no-cache-dir -r requirements.txt --ignore-installed || true

# 4. РАСКЛАДЫВАЕМ МОДЕЛЬ ПО НУЖНЫМ АДРЕСАМ (v180)
# Создаем скрытую папку в /root и кладем туда модель
RUN mkdir -p /root/.facefusion/models && \
    curl -L -o /root/.facefusion/models/inswapper_128.onnx https://github.com/facefusion/facefusion-assets/releases/download/models/inswapper_128.onnx

# 5. Создаем run.py
RUN printf "from facefusion import core\nif __name__ == '__main__':\n    core.cli()" > /app/run.py

# 6. Возвращаем оригинальный рабочий handler.py
COPY handler.py /app/handler.py
RUN chmod +x /app/run.py

ENV PYTHONPATH="/app"
# Принудительно ставим домашнюю директорию
ENV HOME="/root"

CMD [ "python3", "-u", "handler.py" ]
