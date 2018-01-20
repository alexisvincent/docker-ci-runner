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

# Install java, holy shit though this is a mess. Please someone fix java with glibc on alpine.
# Copied from https://github.com/frol/docker-alpine-oraclejdk8/blob/full/Dockerfile
ENV JAVA_VERSION=8 \
    JAVA_UPDATE=161 \
    JAVA_BUILD=12 \
    JAVA_PATH=2f38c3b165be4555a1fa6e98c45e0808 \
    JAVA_HOME="/usr/lib/jvm/default-jvm"

RUN apk add --no-cache --virtual=build-dependencies wget ca-certificates unzip && \
    cd "/tmp" && \
    wget --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
        "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION}u${JAVA_UPDATE}-b${JAVA_BUILD}/${JAVA_PATH}/jdk-${JAVA_VERSION}u${JAVA_UPDATE}-linux-x64.tar.gz" && \
    tar -xzf "jdk-${JAVA_VERSION}u${JAVA_UPDATE}-linux-x64.tar.gz" && \
    mkdir -p "/usr/lib/jvm" && \
    mv "/tmp/jdk1.${JAVA_VERSION}.0_${JAVA_UPDATE}" "/usr/lib/jvm/java-${JAVA_VERSION}-oracle" && \
    ln -s "java-${JAVA_VERSION}-oracle" "$JAVA_HOME" && \
    ln -s "$JAVA_HOME/bin/"* "/usr/bin/" && \
    rm -rf "$JAVA_HOME/"*src.zip && \
    wget --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
        "http://download.oracle.com/otn-pub/java/jce/${JAVA_VERSION}/jce_policy-${JAVA_VERSION}.zip" && \
    unzip -jo -d "${JAVA_HOME}/jre/lib/security" "jce_policy-${JAVA_VERSION}.zip" && \
    rm "${JAVA_HOME}/jre/lib/security/README.txt" && \
    apk del build-dependencies && \
    rm "/tmp/"*

# Sigil for env templating
RUN curl -L "https://github.com/gliderlabs/sigil/releases/download/v0.4.0/sigil_0.4.0_$(uname -sm|tr \  _).tgz" | tar -zxC /usr/local/bin

# - Install clojure cli -----------------------------------------------------------------------------------------------
RUN curl -sSL https://download.clojure.org/install/linux-install-1.9.0.302.sh -O clojure-install.sh && \
    bash ./clojure-install.sh && \
		rm ./clojure-install.sh && \
		clojure -e "(println \"downloaded deps...\")"

# Set boot configuration args
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
		boot -u

# Install gcloud and kubectl cli utilities
ENV GCLOUD_SDK_VERSION=184.0.0
ENV GCLOUD_SDK_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz

RUN mkdir /opt && \
	cd /opt && \
	curl -q ${GCLOUD_SDK_URL} | tar zxf - && \
	echo Y | /opt/google-cloud-sdk/install.sh && \
	/opt/google-cloud-sdk/bin/gcloud --quiet components update kubectl --version=${GCLOUD_SDK_VERSION}
ENV PATH "/opt/google-cloud-sdk/bin:$PATH"
