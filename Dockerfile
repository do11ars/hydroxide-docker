# builder
FROM golang:1-alpine AS builder
RUN apk --update upgrade \
&& apk --no-cache --no-progress add git make gcc musl-dev bash \
&& rm -rf /var/cache/apk/*

# build hydroxide
ENV GOPATH /go
RUN git -C ./src/ clone https://github.com/emersion/hydroxide/
RUN cd /go/src/hydroxide/cmd/hydroxide && go build . && go install . && cd

# Alpine

FROM alpine:3

ENV XDG_CONFIG_HOME /
EXPOSE 80

RUN apk --update upgrade \
    && apk --no-cache add ca-certificates wget netcat-openbsd bash bind-tools openrc supervisor socat \
    && rm -rf /var/cache/apk/*

RUN addgroup -S hydroxide && adduser -h /hydroxide -S hydroxide -G hydroxide
RUN chown -R hydroxide:hydroxide /hydroxide
COPY install-tailscale.sh /tmp
COPY run-tailscale.sh /hydroxide
RUN chmod +x /tmp/install-tailscale.sh && /tmp/install-tailscale.sh && rm -rf /tmp/*

COPY --chown=hydroxide:hydroxide --from=builder /go/bin/hydroxide /usr/bin/hydroxide

RUN mkdir -p /var/log/supervisor

COPY <<EOF /etc/supervisord.conf
[supervisord]
nodaemon=true
user=root

[program:hydroxide]
command=hydroxide -smtp-host 0.0.0.0 -imap-host 0.0.0.0 -disable-carddav serve
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

WORKDIR /hydroxide
ARG AUTH_JSON
COPY <<EOF auth.json
${AUTH_JSON}
EOF

CMD ["./run-tailscale.sh"]
