FROM debian:11-slim

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
RUN pip3 install future

COPY --from=aaronsmithtv/hbuild:19.5.716-base /opt/houdini/build/houdini/python3.9libs /opt/houdini/build/houdini/python3.9libs
COPY --from=aaronsmithtv/hbuild:19.5.716-base /opt/houdini/build/houdini/sbin/sesictrl /opt/houdini/build/houdini/sbin/sesictrl
COPY --from=aaronsmithtv/hbuild:19.5.716-base /opt/houdini/build/bin/hserver /opt/houdini/build/bin/hserver
COPY --from=aaronsmithtv/hbuild:19.5.716-base /opt/houdini/build/dsolib /opt/houdini/build/dsolib
COPY --from=aaronsmithtv/hbuild:19.5.716-base /opt/houdini/build/houdini/scripts/dophints.cmd /opt/houdini/build/houdini/scripts/dophints.cmd
ENV PATH="${PATH}:/opt/houdini/build/houdini/sbin:/opt/houdini/build/bin"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir /work
WORKDIR /work

ENTRYPOINT ["/entrypoint.sh"]
CMD ["python"]
