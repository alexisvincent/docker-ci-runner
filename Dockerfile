FROM docker:latest
LABEL MAINTAINER="Alexis Vincent <mail@alexisvincent.io>"

# If using with kubernetes executor in gitlab ci, add to your container
# ENV DOCKER_HOST=tcp://localhost:2375
ENV DOCKER_DRIVER=overlay
ENV LANG C.UTF-8

# - install basic tools --------------------------------------------------------------------------------------------------
RUN set -x \
	&& apk update \
	&& apk add --no-cache \
	curl \
	git \
	make \
	python \
	bash

# Install Java https://github.com/anapsix/docker-alpine-java/blob/java9/9/0b0/jdk9/standard/Dockerfile
ENV JAVA_VERSION_MAJOR=9 \
    JAVA_VERSION_MINOR=0 \
    JAVA_VERSION_BUILD=0 \
    JAVA_PACKAGE=jdk9 \
    JAVA_JCE=standard \
    JAVA_HOME=/opt/jdk \
    PATH=${PATH}:/opt/jdk/bin \
    LANG=C.UTF-8

RUN set -ex && \
    apk upgrade --update && \
    apk add --no-cache bash ca-certificates curl && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
    mkdir -p /opt/jdk && \
    curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" http://download.java.net/java/jdk9-alpine/archive/181/binaries/jdk-9-ea+181_linux-x64-musl_bin.tar.gz -o /tmp/jdk.tar.gz && \
    JAVA_PACKAGE_SHA256=$(curl -sSL http://download.java.net/java/jdk9-alpine/archive/181/binaries/jdk-9-ea+181_linux-x64-musl_bin.sha256 | awk '{print $NF}') && \
    echo "${JAVA_PACKAGE_SHA256}  /tmp/jdk.tar.gz" > /tmp/jdk.tar.gz.sha256 && \
    sha256sum -c /tmp/jdk.tar.gz.sha256 && \
    tar zxvf /tmp/jdk.tar.gz -C /opt/jdk --strip-components=1 && \
    rm /tmp/jdk.tar.gz

# Sigil for env templating
RUN curl -L "https://github.com/gliderlabs/sigil/releases/download/v0.4.0/sigil_0.4.0_$(uname -sm|tr \  _).tgz" | tar -zxC /usr/local/bin

# - Install clojure cli -----------------------------------------------------------------------------------------------
RUN curl -sSL https://download.clojure.org/install/linux-install-1.9.0.302.sh -o clojure-install.sh && \
    bash ./clojure-install.sh && \
		rm ./clojure-install.sh && \
		clojure -e "(println \"downloaded deps...\")"

# Set boot configuration args
ENV BOOT_VERSION=2.7.2
ENV BOOT_AS_ROOT=yes
ENV BOOT_CLOJURE_VERSION=1.9.0
ENV BOOT_JVM_OPTIONS=" \
	-client \
	-XX:+TieredCompilation \
	-XX:TieredStopAtLevel=1 \
	-Xmx2g \
	-XX:+CMSClassUnloadingEnabled \
	-Xverify:none"

COPY tools.clj /usr/local/bin/tools

# Install boot && initialize cache
RUN cd /usr/local/bin && \
    curl -fsSLo boot https://github.com/boot-clj/boot-bin/releases/download/latest/boot.sh && \
		chmod 755 boot && \
		tools

# Install gcloud and kubectl cli utilities
ENV GCLOUD_SDK_VERSION=184.0.0
ENV GCLOUD_SDK_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz

RUN mkdir -p /opt && \
	cd /opt && \
	curl -q ${GCLOUD_SDK_URL} | tar zxf - && \
	echo Y | /opt/google-cloud-sdk/install.sh && \
	/opt/google-cloud-sdk/bin/gcloud --quiet components update kubectl --version=${GCLOUD_SDK_VERSION}
ENV PATH "/opt/google-cloud-sdk/bin:$PATH"
