FROM pandoc/extra

RUN apk update && \
    apk add --no-cache \
    texlive-full && \
    rm -rf /var/cache/apk/*
