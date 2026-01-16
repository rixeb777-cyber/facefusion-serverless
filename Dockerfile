# ... (начало то же самое)
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install requests runpod

# Установка зависимостей FaceFusion без строгих версий
RUN python3 -m pip install --no-cache-dir numpy opencv-python onnx onnxruntime-gpu insightface psutil tqdm scipy
# ... (остальное без изменений)
