FROM ubuntu:20.04

ENV TZ=Europe/Copenhagen
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ARG kernelVersion="5"
ARG majorRevision="10"
ARG minorRevision="87"
ARG patchNumber="59"
ARG older="older/"
#ARG older=""
ARG uploadDate="2021-11-08"
ARG fileDate="2021-10-30"
ARG architecture="armhf"

#
# Don't change stuff below unless something is broken
#
ARG kernelBranch="rpi-${kernelVersion}.${majorRevision}.y"
ARG patchVersion="${kernelVersion}.${majorRevision}.${minorRevision}-rt${patchNumber}"
ARG patchVersionLocation="echo ../${patchVersion}"
ARG patchURL="https://mirrors.edge.kernel.org/pub/linux/kernel/projects/rt/${kernelVersion}.${majorRevision}/${older}patch-${patchVersion}.patch.gz"
ARG imageFile="${fileDate}-raspios-bullseye-${architecture}-lite.zip"
ARG imageURL="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_${architecture}-${uploadDate}/${imageFile}"

RUN apt-get update
RUN apt-get install -y git make gcc bison flex libssl-dev bc ncurses-dev kmod
RUN apt-get install -y crossbuild-essential-${architecture}
RUN apt-get install -y wget zip unzip fdisk nano curl xz-utils

WORKDIR /rpi-kernel
RUN git clone https://github.com/raspberrypi/linux.git -b ${kernelBranch} --depth=1
RUN wget ${patchURL}

ENV KERNEL=kernel8
ENV ARCH=${architecture}
ENV CROSS_COMPILE=aarch64-linux-gnu-

RUN gzip -cd ${patchVersionLocation} | patch -p1 --verbose
RUN make bcm2711_defconfig
RUN ./scripts/config --disable CONFIG_VIRTUALIZATION
RUN ./scripts/config --enable CONFIG_PREEMPT_RT
RUN ./scripts/config --disable CONFIG_RCU_EXPERT
RUN ./scripts/config --enable CONFIG_RCU_BOOST
RUN ./scripts/config --set-val CONFIG_RCU_BOOST_DELAY 500

RUN make Image modules dtbs

WORKDIR /raspios
RUN apt -y install
RUN wget ${imageURL}
RUN unzip ${imageFile} && rm ${imageFile}
RUN mkdir /raspios/mnt && mkdir /raspios/mnt/disk && mkdir /raspios/mnt/boot
ADD build.sh ./
ADD config.txt ./
