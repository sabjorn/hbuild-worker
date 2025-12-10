FROM aaronsmithtv/hbuild:21.0.559-base


ENV HOUDINI_USERNAME=""
ENV HOUDINI_PASSWORD=""
ENV SIDEFX_CLIENT=""
ENV SIDEFX_SECRET=""
ENV HOUDINI_LICENSE_MODE=""

RUN apt-get update && apt-get install --no-install-recommends -y \
    python3.11-dev \
    python3-distutils \
    python3-pip \
    jq \
    liblzma-dev \
    xz-utils \
 && rm -rf /var/lib/apt/lists/*
RUN ln -s /usr/bin/python3 /usr/bin/python

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# sesictrl in >= v20 is broken -- borrow an older working version
COPY --from=aaronsmithtv/hbuild:19.5.716-base  /opt/houdini/build/houdini/sbin/sesictrl /opt/houdini/build/houdini/sbin/sesictrl

RUN mkdir /work
WORKDIR /work
ENTRYPOINT ["/entrypoint.sh"]
CMD ["python"]
