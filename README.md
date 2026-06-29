# BYOND

Container images for running BYOND games with DreamDaemon and compiling BYOND
projects with DreamMaker.

The default container behavior is configured with environment variables.

## Tags

| Tag | Description | Example |
| --- | --- | --- |
| `latest` | Latest stable BYOND release. | `code.neureka.dev/byond/byond:latest` |
| `beta` | Latest beta BYOND release. | `code.neureka.dev/byond/byond:beta` |
| `<major>` | Latest release for a BYOND major version. | `code.neureka.dev/byond/byond:516` |
| `<major>.<minor>` | Exact BYOND version. | `code.neureka.dev/byond/byond:516.1659` |

## Environment

| Variable | Default | Mode | Description |
| --- | --- | --- | --- |
| `BYOND_MODE` | `host` | all | Runtime mode. Use `host` for DreamDaemon or `compile` for DreamMaker. |
| `BYOND_DMB` | none | `host` | Path to the compiled `.dmb` file inside the container. |
| `BYOND_DME` | none | `compile` | Path to the `.dme` project file inside the container. |
| `BYOND_PORT` | `1337` | `host` | Port passed to `DreamDaemon -ports`. |
| `BYOND_TRUSTED` | `false` | `host` | Set to `true` to add the DreamDaemon `-trusted` flag. Only `true` and `false` are accepted. |
| `PUID` | none | all | Optional user ID for the runtime process. Set with `PGID`. |
| `PGID` | none | all | Optional group ID for the runtime process. Set with `PUID`. |

## Host A Game

Mount your game files at `/app/data`, set `BYOND_DMB`, and publish the same port
as `BYOND_PORT`.

```sh
docker run --detach \
  --name byond \
  --env BYOND_DMB=/app/data/game.dmb \
  --env BYOND_PORT=1337 \
  --env BYOND_TRUSTED=false \
  --volume /opt/game:/app/data \
  --publish 1337:1337 \
  --restart unless-stopped \
  code.neureka.dev/byond/byond:latest
```

## Compose

Create `.env` from `.env.example`, adjust the paths and port, then start the
service.

```sh
docker compose up --detach
```

## Compile Only

Set `BYOND_MODE=compile` and point `BYOND_DME` at the project file. The container
runs DreamMaker once and exits.

```sh
docker run --rm \
  --env BYOND_MODE=compile \
  --env BYOND_DME=/app/data/game.dme \
  --volume /opt/game:/app/data \
  code.neureka.dev/byond/byond:latest
```
