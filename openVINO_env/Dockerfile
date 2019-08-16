FROM raspbian/stretch

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    wget \
    libusb-1.0-0-dev:armhf \
    libgtk-3-dev:armhf \
    libavcodec-dev:armhf \
    libavformat-dev:armhf \
    libswscale-dev:armhf \
    libgstreamer1.0-dev:armhf \
    libgstreamer-plugins-base1.0-dev:armhf \
    libpython3-dev:armhf \
    python3-pip

RUN wget https://www.cmake.org/files/v3.14/cmake-3.14.3.tar.gz && \
    tar xf cmake-3.14.3.tar.gz && \
    (cd cmake-3.14.3 && ./bootstrap --parallel=$(nproc --all) && make --jobs=$(nproc --all) && make install) && \
    rm -rf cmake-3.14.3 cmake-3.14.3.tar.gz

ARG DOWNLOAD_LINK=https://download.01.org/opencv/2019/openvinotoolkit/l_openvino_toolkit_raspbi_p_2019.1.094.tgz
ARG INSTALL_DIR=/opt/intel/openvino
ARG TEMP_DIR=/tmp/openvino_installer

RUN mkdir -p $TEMP_DIR && mkdir -p $INSTALL_DIR && cd $TEMP_DIR && \
    wget -c $DOWNLOAD_LINK && \
    tar -xf l_openvino_toolkit_raspbi_p_2019.1.094.tgz --strip 1 -C ${INSTALL_DIR}&& \
    chmod -R 700 ${INSTALL_DIR} 

RUN apt-get install -y lsb-core:armhf
RUN sed -i "s|<INSTALLDIR>|/opt/intel/openvino|" /opt/intel/openvino/bin/setupvars.sh
RUN cd /opt/intel/openvino/deployment_tools/inference_engine/lib/armv7l && \
    cp libinference_engine.so .. && \
    cp libcpu_extension.so .. && \
    cp libHeteroPlugin.so .. && \
    cp libmyriadPlugin.so ..
RUN export InferenceEngine_DIR=/opt/intel/openvino/deployment_tools/inference_engine/lib
RUN cd  $INSTALL_DIR/deployment_tools/inference_engine/samples && ./build_samples.sh