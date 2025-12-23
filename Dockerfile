FROM docker.io/ipeddocker/iped:4.2.2_7

# --- Environment setup ---
ENV LD_LIBRARY_PATH=/usr/local/lib/python3.9/dist-packages/nvidia/cublas/lib:/usr/local/lib/python3.9/dist-packages/nvidia/cudnn/lib:$LD_LIBRARY_PATH \
    CUDNN_INCLUDE_PATH=/usr/local/lib/python3.9/dist-packages/nvidia/cudnn/include \
    CUDNN_LIBRARY_PATH=/usr/local/lib/python3.9/dist-packages/nvidia/cudnn/lib

# --- System packages ---
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip git ffmpeg cmake pkg-config imagemagick graphicsmagick wget \
        libopenblas-dev liblapack-dev \
        libavdevice-dev libavfilter-dev libavformat-dev \
        libavcodec-dev libswresample-dev libswscale-dev libavutil-dev \
        libpng-dev libjpeg-dev libwebp-dev libx11-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    pip3 install --upgrade pip

# --- CUDA & cuDNN ---
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        cuda-toolkit-12-4 \
        libcudnn9-cuda-12 libcudnn9-dev-cuda-12 && \
    rm -f cuda-keyring_1.1-1_all.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Python packages ---
RUN pip3 install \
        faster-whisper gputil \
        nvidia-cublas-cu12 nvidia-cudnn-cu12==9.*

# --- Preload models ---
RUN python3 -c "\
from faster_whisper import WhisperModel; \
[WhisperModel(model, compute_type='int8') for model in ['large-v3']]"

# --- Build dlib with CUDA ---
RUN pip3 uninstall dlib -y && \
    mkdir -p /opt/SP/packages && cd /opt/SP/packages && \
    git clone https://github.com/davisking/dlib.git && cd dlib && \
    git submodule update --init && \
    mkdir build && cd build && \
    cmake -D DLIB_USE_CUDA=1 -D USE_AVX_INSTRUCTIONS=1 ../ && \
    cmake --build . --config Release -- -j$(nproc) && \
    cd ../ && python3 setup.py install && \
    cd /opt/SP/packages && rm -rf dlib

# --- Add IPED plugins ---
COPY plugins/ /opt/IPED/plugins/

LABEL org.opencontainers.image.authors="AlexInABox"
LABEL org.opencontainers.image.licenses="AGPL-3.0"
LABEL org.opencontainers.image.url="https://github.com/AlexInABox/IPED-cuda"
LABEL org.opencontainers.image.source="https://github.com/AlexInABox/IPED-cuda"