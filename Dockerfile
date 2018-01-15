FROM docker:latest
LABEL MAINTAINER="Alexis Vincent <mail@alexisvincent.io>"

# If using with kubernetes executor in gitlab ci, add to your container
# ENV DOCKER_HOST=tcp://localhost:2375
ENV DOCKER_DRIVER=overlay
ENV LANG C.UTF-8

ENV GCLOUD_SDK_VERSION=184.0.0
ENV GCLOUD_SDK_URL=https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz

# - INSTALL JAVA --------------------------------------------------------------------------------------------------
RUN set -x \
	&& apk update \
	&& apk add --no-cache \
	openjdk8 \
	curl \
	python \
	bash

# Sigil for env templating
RUN curl -L "https://github.com/gliderlabs/sigil/releases/download/v0.4.0/sigil_0.4.0_$(uname -sm|tr \  _).tgz" | tar -zxC /usr/local/bin

# - INSTALL CLOJURE -----------------------------------------------------------------------------------------------
RUN curl -sSL https://download.clojure.org/install/linux-install-1.9.0.302.sh | bash \
 && clojure -e "(println \"downloaded deps...\")"

# Install gcloud and kubectl cli utilities
RUN mkdir /opt && \
	cd /opt && \
	curl -q ${GCLOUD_SDK_URL} | tar zxf - && \
	echo Y | /opt/google-cloud-sdk/install.sh && \
	/opt/google-cloud-sdk/bin/gcloud --quiet components update kubectl --version=${GCLOUD_SDK_VERSION}
ENV PATH "/opt/google-cloud-sdk/bin:$PATH"


RUN set -x \
&& apk update \
&& apk add --no-cache \
git \
make
