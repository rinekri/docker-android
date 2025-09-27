FROM ubuntu:24.04

ARG PYTHON_VERSION=2.7.5

ENV DEBIAN_FRONTEND noninteractive

ENV ANDROID_HOME      /opt/android-sdk-linux
ENV ANDROID_SDK_HOME  ${ANDROID_HOME}
ENV ANDROID_SDK_ROOT  ${ANDROID_HOME}
ENV ANDROID_SDK       ${ANDROID_HOME}
ENV ANDROID_NDK       /opt/android-ndk-linux
ENV ANDROID_NDK_ROOT  ${ANDROID_NDK}

ENV PATH "${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin"
ENV PATH "${PATH}:${ANDROID_HOME}/cmdline-tools/tools/bin"
ENV PATH "${PATH}:${ANDROID_HOME}/tools/bin"
ENV PATH "${PATH}:${ANDROID_HOME}/build-tools/35.0.0"
ENV PATH "${PATH}:${ANDROID_HOME}/platform-tools"
ENV PATH "${PATH}:${ANDROID_HOME}/emulator"
ENV PATH "${PATH}:${ANDROID_HOME}/bin"

RUN dpkg --add-architecture i386

RUN sed -i -re 's/([a-z]{2}\.)?archive.ubuntu.com|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu focal-security main universe" | tee -a /etc/apt/sources.list

RUN apt-get update -yqq && \
    apt-get install -y sudo wget gpg software-properties-common

RUN wget -O - https://apt.corretto.aws/corretto.key | gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | tee /etc/apt/sources.list.d/corretto.list

RUN add-apt-repository ppa:ubuntu-toolchain-r/test -y

RUN apt-get update -yqq && \
    apt-get install -y sudo openjdk-17-jdk java-23-amazon-corretto-jdk curl expect git git-lfs \
        libc6:i386 libncurses5:i386 libstdc++6:i386 zlib1g:i386 wget unzip vim jq net-tools ccache make openssl \
        gcc-14 g++-14 && \
    apt-get clean

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 \
                        --slave /usr/bin/g++ g++ /usr/bin/g++-14


RUN sudo update-java-alternatives --set java-23-amazon-corretto

RUN groupadd android && useradd -d /opt/android-sdk-linux -g android android

COPY tools /opt/tools
COPY licenses /opt/licenses

WORKDIR /tmp/

# Build Python from source
RUN wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz \
  && tar --extract -f Python-$PYTHON_VERSION.tgz \
  && cd ./Python-$PYTHON_VERSION/ \
  && ./configure --enable-optimizations --prefix=/usr/local \
  && make && make install \
  && cd ../ \
  && rm -r ./Python-$PYTHON_VERSION*

RUN python --version && g++ -v

WORKDIR /opt/android-sdk-linux

RUN /opt/tools/entrypoint.sh built-in

RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "tools"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "cmdline-tools;latest"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "build-tools;35.0.0"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "build-tools;36.0.0"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "platform-tools"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "platforms;android-35"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "platforms;android-36"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "system-images;android-35;google_apis;x86_64"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "system-images;android-36;google_apis;x86_64"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "cmake;4.1.1"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "ndk;29.0.14033849"

CMD /opt/tools/entrypoint.sh built-in
