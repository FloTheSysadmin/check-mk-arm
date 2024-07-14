FROM arm64v8/ubuntu:24.04

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive LC_ALL=C.UTF-8 LANG=C.UTF-8 PATH="/opt/bin:${PATH}"
RUN mkdir -p /usr/share/man/man1

RUN apt-get update \
    && apt-get install -y \
    wget \
    debhelper \
    gcc-14 \
    g++-14 \
    curl \
    lsb-release \
    sudo \
    nano \
    devscripts \
    build-essential \
    clang-17 \
    clang-format-17 \
    clang-tidy-17 \
    clang-tools-17 \
    clangd-17 \
    cmake \
    curl \
    direnv \
    doxygen \
    figlet \
    gawk \
    git \
    ksh \
    libclang-17-dev \
    libjpeg-dev \
    libkrb5-dev \
    libldap2-dev \
    libmariadb-dev-compat \
    libpango1.0-dev \
    libpcap-dev \
    librrd-dev \
    libsasl2-dev \
    libsqlite3-dev \
    libtool-bin \
    libxml2-dev \
    libreadline-dev \
    libxml2-dev \
    libxslt-dev \
    libpq-dev \
    libreadline-dev \
    lld-17 \
    lldb-17 \
    musl-tools \
    p7zip-full \
    patchelf \
    python3-pip \
    python3-venv \
    shellcheck \
    valgrind \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get upgrade -y 

RUN echo "Package: nodejs" >> /etc/apt/preferences.d/preferences && \
    echo "Pin: origin deb.nodesource.com" >> /etc/apt/preferences.d/preferences && \
    echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/preferences

RUN apt-get remove -y nodejs libnode-dev libnode72
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash -   
RUN apt-get update -y && apt-get install -y nodejs

RUN apt-get autoremove -y

RUN apt-get install -y python3 \
    libpython3.12 \
    libpython3-dev \
    python3-dev \
    #python3-distutils \
    python3-pip \
    python3-venv \
    python3-setuptools \
    python3-sphinx \
    pipenv \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -V
RUN pip3 -V


#RUN python3 -m pip install --upgrade pip
#RUN pip3 install pipenv
#RUN cp /usr/local/bin/pipenv* /usr/bin/
#RUN cp /usr/local/bin/virtualenv* /usr/bin/

RUN cd /tmp && wget -q https://github.com/bazelbuild/bazel/releases/download/7.2.1/bazel-7.2.1-linux-arm64 
RUN mv /tmp/bazel-7.2.1-linux-arm64 /usr/bin/bazel
RUN chmod 755 /usr/bin/bazel


ENV DISTRO="debian" DISTRO_CODE="bookworm"

RUN mkdir -p /opt/build-mk/debs
RUN mkdir -p /opt/build-mk/patches
COPY patches/* /opt/build-mk/patches/
COPY build_check_mk.sh /opt/build-mk/build_check_mk.sh
RUN chmod +x /opt/build-mk/build_check_mk.sh
ENTRYPOINT ["/bin/bash"] # For Debugging later set to build_check_mk.sh
