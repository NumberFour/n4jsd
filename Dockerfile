# https://github.com/nodejs/docker-node/blob/45fa3ebe94598758b9c9e4a382236fc7e879e2e6/10/alpine/Dockerfile
FROM node:10-alpine

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8
# For latest openjdk8 versions for Alpine, see: https://pkgs.alpinelinux.org/packages?name=openjdk8&branch=edge

ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

RUN set -x \
    && apk update \
    && apk add --no-cache --repository https://ftp.halifax.rwth-aachen.de/alpine/v3.8/community/ openjdk8 \
    && apk add --no-cache bash git openssl wget tzdata

ENV TZ Europe/Berlin

LABEL version="1.0.0" \
    description="Image based on node:10-alpine with pre-installed openjdk-8." \
    maintainer="Dev-Tools Team <staff-devtools@numberfour.eu>" \
    eu.numberfour.dockerimage.name="n4jsd-publish" \
    eu.numberfour.dockerimage.github="numberfour/n4jsd"

CMD ["ls", "-la"]
