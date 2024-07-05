FROM aaronsmithtv/hbuild:20.0.751-base

# user defined at runtime of container
ENV HOUDINI_USERNAME=""
ENV HOUDINI_PASSWORD=""
ENV SIDEFX_CLIENT=""
ENV SIDEFX_SECRET=""

RUN apt-get update && apt-get install --no-install-recommends -y \
    python3.9-dev \
    python3-distutils \
    python3-pip \
    jq \
 && rm -rf /var/lib/apt/lists/*
RUN ln -s /usr/bin/python3 /usr/bin/python

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir /work
WORKDIR /work
ENTRYPOINT ["/entrypoint.sh"]
CMD ["python"]
