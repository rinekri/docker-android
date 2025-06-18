FROM ubuntu:23.04

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
ENV PATH "${PATH}:${ANDROID_HOME}/build-tools/34.0.0"
ENV PATH "${PATH}:${ANDROID_HOME}/platform-tools"
ENV PATH "${PATH}:${ANDROID_HOME}/emulator"
ENV PATH "${PATH}:${ANDROID_HOME}/bin"

RUN dpkg --add-architecture i386
RUN sed -i -re 's/([a-z]{2}\.)?archive.ubuntu.com|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu focal-security main universe" | tee -a /etc/apt/sources.list
RUN apt-get update -yqq && \
    apt-get install -y sudo wget gpg && \
    wget -O - https://apt.corretto.aws/corretto.key | gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | tee /etc/apt/sources.list.d/corretto.list && \
    apt-get update -yqq && \
    apt-get install -y sudo openjdk-17-jdk java-23-amazon-corretto-jdk curl expect git git-lfs libc6:i386 libncurses5:i386 libstdc++6:i386 zlib1g:i386 wget unzip vim jq net-tools ccache g++ && \
    apt-get install -y gcc make openssl && \
    apt-get clean

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

RUN python --version

WORKDIR /opt/android-sdk-linux

RUN /opt/tools/entrypoint.sh built-in

RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "tools"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "cmdline-tools;latest"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "build-tools;34.0.0"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "build-tools;35.0.1"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "build-tools;36.0.0"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "platform-tools"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "platforms;android-34"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "platforms;android-35"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "system-images;android-34;google_apis;x86_64"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "system-images;android-35;google_apis;x86_64"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "cmake;3.22.1"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "cmake;3.18.1"
RUN /opt/android-sdk-linux/cmdline-tools/tools/bin/sdkmanager "ndk;26.2.11394342"

CMD /opt/tools/entrypoint.sh built-in
