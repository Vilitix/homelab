FROM docker:27-cli

RUN apk add --no-cache bash git docker-cli-compose

WORKDIR /home/arthur/homelab/agent
CMD ["/bin/sh", "-c", "sleep 300; while true; do /home/arthur/homelab/agent/openpaper-update.sh >> /home/arthur/homelab/agent/openpaper-update.log 2>&1; sleep 86400; done"]
