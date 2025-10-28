FROM alpine:latest

RUN apk add --no-cache \
    mysql-client \
    rclone \
    bash \
    gzip

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ENTRYPOINT ["/entrypoint.sh"]
