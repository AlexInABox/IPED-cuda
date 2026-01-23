FROM docker.io/nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

ENV IPED_VERSION=4.3.0

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
    curl \
    unzip \
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
    libcppunit-dev \
    libsqlite3-dev \
    # Forensic libraries
    # Runtime libraries
    # Tools for IPED
    tesseract-ocr tesseract-ocr-osd tesseract-ocr-por tesseract-ocr-eng tesseract-ocr-deu tesseract-ocr-frk tesseract-ocr-ita \
    imagemagick \
    mplayer \
    libreoffice-java-common \
    libreoffice-gtk2 \
    libparse-win32registry-perl \
    graphviz \
    rifiuti2 &&\
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
    libbrotli-dev \ 
    # For libewf
    bison \
    flex \
    yasm \
    gettext
# Set python3.9 as default python3 and python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1 



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
# Stage 3: Build and install libvslvm
# =============================================================================

RUN git clone https://github.com/libyal/libvslvm.git /libvslvm
WORKDIR /libvslvm
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make all install && \
    ldconfig

# =============================================================================
# Stage 4: Build and install libvmdk
# =============================================================================

RUN git clone https://github.com/libyal/libvmdk.git /libvmdk
WORKDIR /libvmdk
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make all install && \
    ldconfig

# =============================================================================
# Stage 5: Build and install libvhdi
# =============================================================================

RUN git clone https://github.com/libyal/libvhdi.git /libvhdi
WORKDIR /libvhdi
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make all install && \
    ldconfig

# =============================================================================
# Stage 6: Build and install libewf
# =============================================================================

RUN git clone https://github.com/libyal/libewf.git /libewf
WORKDIR /libewf
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make all install && \
    ldconfig

# =============================================================================
# Stage 7: Build and install afflib
# =============================================================================

RUN git clone -b v3.7.20 https://github.com/sshock/AFFLIBv3.git /AFFLIBv3
WORKDIR /AFFLIBv3
RUN ./bootstrap.sh && \
    ./configure --prefix=/usr && \
    make all install && \
    ldconfig

# =============================================================================
# Stage 8: Build and install libagdb
# =============================================================================

RUN git clone https://github.com/libyal/libagdb.git /libagdb
WORKDIR /libagdb
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make all install && \
    ldconfig

# =============================================================================
# Stage 9: Build and install libevtx
# =============================================================================

RUN git clone https://github.com/libyal/libevtx.git /libevtx
WORKDIR /libevtx
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make all install && \
    ldconfig

# =============================================================================
# Stage 10: Build and install libevt
# =============================================================================

RUN git clone https://github.com/libyal/libevt.git /libevt
WORKDIR /libevt
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make all install && \
    ldconfig

# =============================================================================
# Stage 11: Build and install libscca
# =============================================================================

RUN git clone https://github.com/libyal/libscca.git /libscca
WORKDIR /libscca
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make all install && \
    ldconfig

# =============================================================================
# Stage 12: Build and install libesedb
# =============================================================================

RUN git clone https://github.com/libyal/libesedb.git /libesedb
WORKDIR /libesedb
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make all install && \
    ldconfig

# =============================================================================
# Stage 13: Build and install libpff
# =============================================================================

RUN git clone https://github.com/libyal/libpff.git /libpff
WORKDIR /libpff
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make all install && \
    ldconfig

# =============================================================================
# Stage 14: Build and install libmsiecf
# =============================================================================

RUN git clone https://github.com/libyal/libmsiecf.git /libmsiecf
WORKDIR /libmsiecf
RUN ./synclibs.sh && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make all install && \
    ldconfig

# =============================================================================
# Stage 15: Build and install libjxl (JPEG XL)
# =============================================================================

RUN git clone https://github.com/libjxl/libjxl.git --recursive --shallow-submodules /libjxl
WORKDIR /libjxl
RUN mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF .. && \
    cmake --build . && \
    cmake --install . && \
    ldconfig

# =============================================================================
# Stage 16: Build and install Sleuthkit (IPED patched version)
# =============================================================================

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
    ldconfig

# =============================================================================
# Stage 17: Install Python packages
# =============================================================================

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
    torch>=2.1.0 \
    huggingsound \
    bs4

# =============================================================================
# Stage 18: Build dlib with CUDA support
# =============================================================================

RUN pip3 uninstall dlib -y && \
    mkdir -p /opt/SP/packages && cd /opt/SP/packages && \
    git clone https://github.com/davisking/dlib.git && cd dlib && \
    git submodule update --init && \
    mkdir build && cd build && \
    cmake -D DLIB_USE_CUDA=1 -D USE_AVX_INSTRUCTIONS=1 ../ && \
    cmake --build . --config Release -- -j$(nproc) && \
    cd ../ && python3 setup.py install && \
    cd /opt/SP/packages && rm -rf dlib

# =============================================================================
# Stage 19: Preload models
# =============================================================================
# If you need custom models replace ['large-v3'] with your own comma separated list of models from huggingface
# e.g. ['small', 'medium', 'large-v2'] or ['Flurin17/whisper-large-v3-turbo-swiss-german', 'large-v3']
RUN python3 -c "from faster_whisper import WhisperModel; [WhisperModel(model, compute_type='int8') for model in ['large-v3']]"

# =============================================================================
# Stage 20: Download and install IPED release
# =============================================================================

WORKDIR /opt
RUN curl -L https://github.com/sepinf-inc/IPED/releases/download/${IPED_VERSION}/IPED-${IPED_VERSION}_and_java_plugins.zip --output /tmp/iped.zip && \
    unzip /tmp/iped.zip && \
    ls | grep "iped-" | xargs -I {} sh -c 'ln -s "{}" iped' && \
    rm /tmp/iped.zip

# =============================================================================
# Stage 21: Cleanup
# =============================================================================

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /libbfio /libagdb /sleuthkit

RUN ls -la /opt/iped/

WORKDIR /opt/iped
CMD ["/bin/bash"]

# =============================================================================

LABEL org.opencontainers.image.authors="AlexInABox"
LABEL org.opencontainers.image.licenses="AGPL-3.0"
LABEL org.opencontainers.image.url="https://github.com/AlexInABox/IPED-cuda"
LABEL org.opencontainers.image.source="https://github.com/AlexInABox/IPED-cuda"
