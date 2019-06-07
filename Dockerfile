FROM node:10-alpine

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8
# For latest openjdk11 versions for Alpine, see: https://pkgs.alpinelinux.org/packages?name=openjdk11&branch=edge

RUN set -x \
    && apk update \
    && apk add --no-cache --repository https://ftp.halifax.rwth-aachen.de/alpine/edge/community/ openjdk11 \
    && apk add --no-cache bash git openssl wget tzdata

ENV TZ Europe/Berlin

LABEL version="1.0.0" \
    description="Image based on node:10-alpine with pre-installed openjdk." \
    maintainer="Dev-Tools Team <staff-devtools@numberfour.eu>" \
    eu.numberfour.dockerimage.name="n4jsd-publish" \
    eu.numberfour.dockerimage.github="numberfour/n4jsd"

CMD ["ls", "-la"]
