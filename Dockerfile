FROM aaronsmithtv/hbuild:19.5.716-base

RUN apt-get update && apt-get install --no-install-recommends -y \
    python3.9-dev \
    python3-distutils \
 && rm -rf /var/lib/apt/lists/*

ENV HOUDINI_USERNAME=""
ENV HOUDINI_PASSWORD=""
ENV SIDEFX_CLIENT=""
ENV SIDEFX_SECRET=""

ENV HHP=/opt/houdini/build/houdini/python3.9libs
ENV HOUDINI_SCRIPT_LICENSE="hbatch"
ENV HOUDINI_DISABLE_JEMALLOCTEST=1

COPY hou_setup.py /hou_setup.py 
ENV PYTHONSTARTUP=/hou_setup.py

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir /work
WORKDIR /work
ENTRYPOINT ["/entrypoint.sh"]

