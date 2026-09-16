FROM ubuntu:26.04
LABEL org.opencontainers.image.source="https://github.com/neurekadev/byond"
LABEL org.opencontainers.image.description="A docker image for building and hosting games made in the BYOND engine."

ARG APP_VERSION
ARG BYOND_MAJOR
ARG BYOND_MINOR
ARG PUID
ARG PGID
# BYOND's archive CDN sits behind Cloudflare, which serves automated-looking
# requests from datacenter IPs (e.g. GitHub Actions runners) a browser
# verification challenge (HTTP 403). Plain HTTP with a browser User-Agent is
# served the archive; ci/build.sh passes this same value so the Docker build
# download and its availability probe behave identically.
ARG BYOND_UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"

ENV APP_VERSION="${APP_VERSION}" \
    PUID="${PUID}" \
    PGID="${PGID}" \
    BYOND_MODE="host" \
    BYOND_PORT="1337" \
    BYOND_TRUSTED="false"

WORKDIR /app

# BYOND's archive CDN serves the Linux archive used by this image over plain
# HTTP only when the request carries a browser User-Agent; see the BYOND_UA
# comment above.
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl make unzip util-linux libc6:i386 libcurl4t64:i386 libgcc-s1:i386 libstdc++6:i386 \
 && curl --fail --location --user-agent "${BYOND_UA}" "http://www.byond.com/download/build/${BYOND_MAJOR}/${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" -o /tmp/byond.zip \
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
