FROM docker.io/nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

ENV IPED_VERSION=4.3.1
ENV DEBIAN_FRONTEND=noninteractive
ENV SAL_USE_VCLPLUGIN=gtk
ENV JAVA_HOME=/usr/lib/jvm/bellsoft-java11-full-amd64/
ENV PATH=$JAVA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib/:/usr/lib/:/usr/local/lib/python3.10/dist-packages/jep/
ENV MAVEN_OPTS="-Djava.library.path=/usr/local/lib/python3.10/dist-packages/jep -Dfile.encoding=UTF-8"

# =============================================================================
# Stage 1: Core System & Repos
# =============================================================================

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    locales \
    software-properties-common \
    ca-certificates \
    wget \
    curl \
    gnupg \
    git \
    git-lfs \
    unzip \
    # Build tools
    autoconf \
    automake \
    autopoint \
    libtool \
    pkg-config \
    gawk \
    ant \
    ant-optional \
    maven \
    cmake \
    build-essential \
    # Python headers
    python3-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 1.1 Configure Locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 1.2 Add BellSoft JDK Repo
RUN mkdir -p /etc/apt/keyrings && \
    wget -q -O - https://download.bell-sw.com/pki/GPG-KEY-bellsoft | \
    gpg --dearmor > /etc/apt/keyrings/bellsoft.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/bellsoft.gpg] https://apt.bell-sw.com/ stable main" \
    > /etc/apt/sources.list.d/bellsoft.list

# =============================================================================
# Stage 2: Install Libraries via APT (Hybrid Stability Layer)
# =============================================================================

RUN add-apt-repository universe && apt-get update && apt-get install -y \
    bellsoft-java11-full \
    # Build Dependencies
    libssl-dev \
    libcppunit-dev \
    libsqlite3-dev \
    zlib1g-dev \
    libfuse-dev \
    libutf8proc-dev \
    uuid-dev \
    byacc \
    flex \
    bison \
    gettext \
    # Forensic Libs (System versions for stability)
    libscca-utils \
    libevtx-utils \
    libevt-utils \
    libmsiecf-utils \
    pff-tools \
    libpff-dev \
    libesedb-utils \
    libvhdi-dev \
    libvmdk-dev \
    # Tools
    tesseract-ocr tesseract-ocr-osd tesseract-ocr-por tesseract-ocr-eng tesseract-ocr-deu tesseract-ocr-frk tesseract-ocr-ita \
    imagemagick \
    mplayer \
    ffmpeg \
    mpv \
    libreoffice-java-common \
    libreoffice-gtk2 \
    libparse-win32registry-perl \
    graphviz \
    rifiuti2 \
    swig \
    # Dlib Dependencies
    libx11-dev \
    libopenblas-dev liblapack-dev \
    libavdevice-dev libavfilter-dev libavformat-dev \
    libavcodec-dev libswresample-dev libswscale-dev \
    libavutil-dev \
    libgif-dev libjpeg-dev libopenexr-dev libpng-dev libwebp-dev libavif-dev \
    libbrotli-dev && \
    # Setup Mplayer config
    mplayer && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# Stage 3: Build Source Libraries (Critical for TSK Patch)
# =============================================================================

# 3.1 Build libbfio (Dependency for libewf)
RUN git clone https://github.com/libyal/libbfio.git /libbfio
WORKDIR /libbfio
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local && \
    make all install && \
    ldconfig && \
    cd / && rm -rf /libbfio

# 3.2 Build libewf (Needed for TSK patch to work correctly)
RUN git clone https://github.com/libyal/libewf.git /libewf
WORKDIR /libewf
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local --enable-wide-character-type && \
    make all install && \
    ldconfig && \
    cd / && rm -rf /libewf

# 3.3 Build libagdb (Matches your working build)
RUN git clone https://github.com/libyal/libagdb.git /libagdb
WORKDIR /libagdb
RUN git checkout 667a782 && \
    ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local && \
    make all install && \
    ldconfig && \
    cd / && rm -rf /libagdb

# 3.4 Build libjxl (JPEG XL)
RUN git clone https://github.com/libjxl/libjxl.git --recursive --shallow-submodules /libjxl
WORKDIR /libjxl
RUN mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF .. && \
    cmake --build . && \
    cmake --install . && \
    ldconfig && \
    cd / && rm -rf /libjxl

# =============================================================================
# Stage 4: Build Patched Sleuthkit & Dlib
# =============================================================================

# 4.1 Sleuthkit with IPED Patch
# We expect ewf.cpp.patch to be in the same folder as Dockerfile
RUN git clone -b 4.12.0_iped_patch https://github.com/sepinf-inc/sleuthkit.git /sleuthkit
COPY ewf.cpp.patch /sleuthkit
WORKDIR /sleuthkit
RUN patch tsk/img/ewf.cpp < ewf.cpp.patch
RUN ./bootstrap && \
    ./configure --prefix=/usr/ --enable-java && \
    make && \
    make install && \
    mkdir -p /usr/share/java && \
    cp bindings/java/dist/sleuthkit-4.12.0.jar /usr/share/java/sleuthkit-4.12.0.jar && \
    ldconfig && \
    cd / && rm -rf /sleuthkit

# 4.2 Python Environment
RUN pip3 install --upgrade pip
RUN pip3 install \
    packaging \
    faster-whisper \
    gputil \
    numpy==1.26.4 \
    jep==4.0.3 \
    face_recognition \
    pillow \
    tensorflow==2.10 \
    opencv-python==4.11.0.86 \
    transformers \
    torch \
    bs4

# 4.3 Build Dlib with CUDA
RUN pip3 uninstall dlib -y && \
    mkdir -p /opt/SP/packages && cd /opt/SP/packages && \
    git clone https://github.com/davisking/dlib.git && cd dlib && \
    git submodule update --init && \
    mkdir build && cd build && \
    cmake -D DLIB_USE_CUDA=1 -D USE_AVX_INSTRUCTIONS=1 ../ && \
    cmake --build . --config Release -- -j$(nproc) && \
    cd ../ && python3 setup.py install && \
    cd / && rm -rf /opt/SP/packages/dlib

# Preload Whisper models
RUN python3 -c "from faster_whisper import WhisperModel; [WhisperModel(model, compute_type='int8') for model in ['large-v3']]"

# =============================================================================
# Stage 5: Build IPED (WITH TESTS)
# =============================================================================

WORKDIR /opt

# Initialize Git LFS
RUN git lfs install

# Clone IPED
RUN git clone https://github.com/sepinf-inc/IPED.git \
    && cd IPED \
    && git checkout ${IPED_VERSION} \
    && git lfs pull

WORKDIR /opt/IPED

# Build with Maven - Tests ENABLED
RUN mvn clean install

RUN mv target/release/iped-${IPED_VERSION} /opt/iped
RUN mkdir -p /opt/plugins && mv target/release/plugins/* /opt/plugins/

# =============================================================================
# Stage 6: Final Setup
# =============================================================================

# Install JPEG2000 plugin
RUN curl -L https://mvnrepository.com/artifact/com.github.jai-imageio/jai-imageio-jpeg2000/1.4.0 -o /tmp/jai-imageio-jpeg2000-1.4.0.jar && \
    cp /tmp/jai-imageio-jpeg2000-1.4.0.jar /opt/plugins/ && \
    rm /tmp/jai-imageio-jpeg2000-1.4.0.jar

# Remove conflicting TSK JAR
RUN rm -v /opt/iped/lib/sleuthkit-4.12.0.p1.jar

RUN ls -la /opt/plugins

WORKDIR /opt/iped
CMD ["/bin/bash"]

LABEL org.opencontainers.image.authors="AlexInABox"
LABEL org.opencontainers.image.licenses="AGPL-3.0"