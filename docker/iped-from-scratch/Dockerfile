FROM docker.io/nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SAL_USE_VCLPLUGIN=gtk
ENV JAVA_HOME=/usr/lib/jvm/bellsoft-java11-full-amd64/
ENV TZ=Europe/Berlin
ENV LD_LIBRARY_PATH=/usr/lib/:/usr/local/lib/python3.9/dist-packages/jep/

# =============================================================================
# Stage 1: Configure repositories and install all packages at once
# =============================================================================

RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    wget \
    gnupg \
    git \
    software-properties-common \
    autoconf \
    automake \
    autopoint \
    libtool \
    pkg-config \
    gawk \
    ant \
    maven \
    cmake && \
    update-ca-certificates && \
    add-apt-repository universe && \
    # Add BellSoft repository for Liberica JDK 11
    mkdir -p /etc/apt/keyrings && \
    wget -q -O - https://download.bell-sw.com/pki/GPG-KEY-bellsoft | \
    gpg --dearmor > /etc/apt/keyrings/bellsoft.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/bellsoft.gpg] https://apt.bell-sw.com/ stable main" \
    > /etc/apt/sources.list.d/bellsoft.list && \
    apt-get update && \
    apt-get install -y bellsoft-java11-full && \
    apt-get install -y \
    # Sleuthkit build dependencies
    libssl-dev \
    libafflib-dev \
    libvslvm-dev \
    libcppunit-dev \
    libsqlite3-dev \
    # Forensic libraries
    libewf-dev \
    libvmdk-dev \
    libvhdi-dev \
    libpff-dev \
    libesedb-dev \
    libesedb-utils \
    libmsiecf-dev \
    libmsiecf-utils \
    libscca-dev \
    libscca-utils \
    # Runtime libraries
    libewf2 \
    libvmdk1 \
    libvmdk-utils \
    libvslvm-utils \
    # Tools for IPED
    tesseract-ocr tesseract-ocr-osd tesseract-ocr-por tesseract-ocr-eng tesseract-ocr-deu tesseract-ocr-frk tesseract-ocr-ita \
    imagemagick \
    mplayer \
    libreoffice-java-common \
    libreoffice-gtk2 \
    libparse-win32registry-perl \
    graphviz \
    libevt-utils \
    libevtx-utils \
    afflib-tools \
    rifiuti2 \
    pff-tools && \
    # "Python nation! Rise up!"
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python3.9 python3.9-dev python3.9-distutils python3-pip python3.9-dev \
    swig \
    # For dlib
    libx11-dev \
    libopenblas-dev liblapack-dev \
    libavdevice-dev libavfilter-dev libavformat-dev \
    libavcodec-dev libswresample-dev libswscale-dev \
    libavutil-dev \
    libgif-dev libjpeg-dev libopenexr-dev libpng-dev libwebp-dev libavif-dev \
    libbrotli-dev 

# Set python3.9 as default python3 and python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1 

RUN pip3 install --upgrade pip

RUN pip3 install \
    packaging \
    faster-whisper \
    gputil \
    numpy==1.26.4 \
    jep==4.2.0 \
    pillow \
    tensorflow==2.10 \
    face_recognition \
    opencv-python==4.11.0.86 \
    transformers \
    torch \
    huggingsound \
    bs4

# =============================================================================
# Stage 2: Build and install libbfio
# =============================================================================

RUN git clone https://github.com/libyal/libbfio.git /libbfio
WORKDIR /libbfio
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make all install && \
    ldconfig

# =============================================================================
# Stage 3: Build and install libagdb
# =============================================================================

RUN git clone https://github.com/libyal/libagdb.git /libagdb
WORKDIR /libagdb
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make all install && \
    ldconfig

# =============================================================================
# Stage 4: Build and install libpff
# =============================================================================

RUN git clone https://github.com/libyal/libpff.git /libpff
WORKDIR /libpff
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make all install && \
    ldconfig

# =============================================================================
# Stage 5: Build and install libjxl from source
# =============================================================================

RUN git clone https://github.com/libjxl/libjxl.git --recursive --shallow-submodules /libjxl
WORKDIR /libjxl
RUN mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF ../ && \
    cmake --build . -- && \
    cmake --install . && \
    ldconfig

# =============================================================================
# Stage 6: Build and install dlib with CUDA
# =============================================================================

RUN git clone https://github.com/davisking/dlib.git /dlib 
WORKDIR /dlib
RUN pip3 uninstall dlib -y && \
    git submodule update --init && \
    mkdir build && cd build && \
    cmake -D DLIB_USE_CUDA=1 -D USE_AVX_INSTRUCTIONS=1 ../ && \
    cmake --build . --config Release -- -j$(nproc) && \
    cd ../ && python3 setup.py install && \
    ldconfig

# =============================================================================
# Stage 7: Build and install Sleuthkit (IPED patched version)
# =============================================================================

RUN git clone -b 4.12.0_iped_patch https://github.com/sepinf-inc/sleuthkit.git /sleuthkit
WORKDIR /sleuthkit
RUN ./bootstrap && \
    ./configure && \
    make && \
    make install && \
    mkdir -p /usr/share/java && \
    cp bindings/java/dist/sleuthkit-4.12.0.jar /usr/share/java/sleuthkit-4.12.0.jar && \
    ldconfig

# =============================================================================
# Stage 8: Build and install IPED
# =============================================================================

RUN git clone --branch 4.2.2 https://github.com/sepinf-inc/IPED.git /IPED
WORKDIR /IPED
RUN mvn clean install

# =============================================================================
# Cleanup: Remove package cache and build directories
# =============================================================================

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /libbfio /libagdb /sleuthkit