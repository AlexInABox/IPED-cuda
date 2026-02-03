FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib/python3.10/dist-packages/jep:$LD_LIBRARY_PATH
ENV MAVEN_OPTS="-Djava.library.path=/usr/local/lib/python3.10/dist-packages/jep -Dfile.encoding=UTF-8"

# Enable universe first
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository universe

# 1. Install Base system + Build Tools + GIT LFS + LOCALES
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    maven \
    git \
    git-lfs \
    locales \
    autoconf \
    automake \
    autopoint \
    libtool \
    pkg-config \
    imagemagick \
    python3-dev \
    python3-pip \
    gsfonts \
    perl \
    && rm -rf /var/lib/apt/lists/*

# 2. Configure Locale to UTF-8 (Crucial for parsing tests)
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 3. Install External forensic tools (exact versions matching CI)
RUN apt-get update && apt-get install -y \
    libscca-utils \
    rifiuti2 \
    libevtx-utils \
    libevt-utils \
    libmsiecf-utils=20181227-2build1 \
    pff-tools=20180714-3build1 \
    libpff1 \
    libpff-dev \
    libesedb-utils=20181229-3.1build2 \
    tesseract-ocr \
    tesseract-ocr-por \
    && rm -rf /var/lib/apt/lists/*

# 4. Perl + Python deps
RUN perl -MCPAN -e 'install Parse::Win32Registry' \
    && pip install --no-cache-dir jep==4.0.3

# 5. Build and install libagdb
RUN git clone https://github.com/libyal/libagdb.git /libagdb \
    && cd /libagdb \
    && git checkout 667a782 \
    && ./synclibs.sh \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install \
    && ldconfig

# 6. Clone IPED and pull LFS data
WORKDIR /opt
RUN git clone https://github.com/sepinf-inc/IPED.git \
    && cd IPED \
    && git checkout 4.3.0 \
    && git lfs install \
    && git lfs pull

# 7. Build IPED
WORKDIR /opt/IPED
# Note: You can add -DskipTests to save time/avoid environment flakiness if you just want the jar
RUN mvn -B package --file pom.xml