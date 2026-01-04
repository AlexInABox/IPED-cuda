FROM docker.io/nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

# 1. Install basic tools and CA certificates
RUN apt-get update && apt-get install -y \
    ca-certificates \
    wget \
    gnupg \
    git \
    maven && \
    update-ca-certificates

# 2. Add BellSoft GPG key
RUN mkdir -p /etc/apt/keyrings && \
    wget -q -O - https://download.bell-sw.com/pki/GPG-KEY-bellsoft | \
        gpg --dearmor > /etc/apt/keyrings/bellsoft.gpg

# 3. Add BellSoft repository
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/bellsoft.gpg] https://apt.bell-sw.com/ stable main" \
    > /etc/apt/sources.list.d/bellsoft.list

# 4. Update and install BellSoft Java
RUN apt-get update && apt-get install -y bellsoft-java11-full && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
RUN git clone --branch 4.2.2 https://github.com/sepinf-inc/IPED.git

WORKDIR /IPED

RUN mvn clean install


# Now sleuthkit
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update && apt-get install -y autoconf automake libtool pkg-config git autoconf automake autopoint pkg-config && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Dependencies for sleuthkit
RUN apt-get update && apt-get install -y \
    libewf-dev \
    libvmdk-dev \
    libvhdi-dev \
    tesseract-ocr \
    imagemagick \
    mplayer \
    libreoffice-java-common \
    libreoffice-gtk3 \
    libpff-dev \
    libesedb-dev \
    libparse-win32registry-perl \
    libmsiecf-dev \
    libscca-dev \
    graphviz \
    libevt-utils \
    libevtx-utils \
    rifiuti2 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install libbfio
RUN git clone https://github.com/libyal/libbfio.git /libbfio
WORKDIR /libbfio
RUN ./synclibs.sh
RUN ./autogen.sh
RUN ./configure --prefix=/usr
RUN make all install
RUN ldconfig

# Compile libagdb
RUN git clone https://github.com/libyal/libagdb.git /libagdb

WORKDIR /libagdb

RUN ./synclibs.sh
RUN ./autogen.sh
RUN ./configure --prefix=/usr --with-libbfio=/usr
RUN make all install
RUN ldconfig

# Compile sleuthkit
RUN git clone -b 4.12.0_iped_patch https://github.com/sepinf-inc/sleuthkit.git /sleuthkit

WORKDIR /sleuthkit

RUN ./bootstrap && \
    ./configure && \
    make && \
    make install