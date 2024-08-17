# BYOND

A docker image for building and hosting games made in the BYOND Engine.

## Tags

### Latest

The latest stable version of BYOND.

### Version

A specific version of BYOND.

## DreamDaemon (Host)

Example usage to host your projects.

### Docker Run

```docker
docker run --detach \
  --name game \
  --volume /opt/game:/opt/game \
  --publish 1337:1337 \
  --restart unless-stopped \
  code.neureka.dev/byond/byond:latest DreamDaemon /opt/game/game.dmb -ports 1337
```

### Docker Compose

#### docker-compose.yml

```docker
services:
  byond:
    image: code.neureka.dev/byond/byond:latest
    container_name: "game"
    command: "DreamDaemon /opt/game/game.dmb -ports 1337"
    volumes:
      - /opt/game:/opt/game
    ports:
      - 1337:1337
    restart: unless-stopped
```

## DreamMaker (Build)

Example usage to build your projects.

### Docker Run

```docker
docker run --rm \
  --volume /opt/game:/opt/game \
  code.neureka.dev/byond/byond:latest DreamMaker /opt/game/game.dme
```
