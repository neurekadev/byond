FROM i386/ubuntu:20.04
LABEL org.opencontainers.image.source="https://code.neureka.dev/BYOND/BYOND"
LABEL org.opencontainers.image.description="A docker image for building and hosting games made in the BYOND engine."

ARG APP_VERSION
ARG BYOND_MAJOR
ARG BYOND_MINOR
ARG PUID
ARG PGID

ENV APP_VERSION="${APP_VERSION}" \
    PUID="${PUID}" \
    PGID="${PGID}" \
    BYOND_MODE="host" \
    BYOND_PORT="1337" \
    BYOND_TRUSTED="false"

WORKDIR /app

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl gosu libcurl4 libstdc++6 make unzip \
 && curl --fail --location "https://www.byond.com/download/build/${BYOND_MAJOR}/${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" -o /tmp/byond.zip \
 && unzip /tmp/byond.zip -d /tmp \
 && sed -i 's|install:|&\n\tmkdir -p $(MAN_DIR)/man6|' /tmp/byond/Makefile \
 && make -C /tmp/byond install \
 && apt-get purge -y --auto-remove curl make unzip \
 && rm -rf /tmp/byond /tmp/byond.zip /var/lib/apt/lists/* \
 && mkdir -p /app/data

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 1337
VOLUME ["/app/data"]

ENTRYPOINT ["/entrypoint.sh"]
