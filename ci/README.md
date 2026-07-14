# Building images manually

Stable and beta images build automatically every hour. Use the manual jobs below when you
need a **specific version** or want to **backport an older major**.

## How to run

In GitLab go to **CI/CD → Pipelines → Run pipeline** (branch `main`), add the variable for
the job you want, and click **Run pipeline**.

Set only **one** of `VERSION` or `MAJOR` per run.

## Build a specific version

Set `VERSION` to the full BYOND version:

| Variable | Value |
| --- | --- |
| `VERSION` | `516.1659` |

Pushes `registry.neureka.dev/byond/byond:516.1659` and `:516`.

If that version already exists it fails on purpose — add `FORCE_OVERWRITE=true` to rebuild it.

## Backport an older major

Set `MAJOR` to the BYOND major version:

| Variable | Value |
| --- | --- |
| `MAJOR` | `515` |

It finds the newest published build for that major, then pushes `:<full>` (e.g. `:515.1647`)
and `:515`. Versions that already exist are skipped.

To build an exact older build instead of the newest, also set `BACKPORT_MINOR`:

| Variable | Value |
| --- | --- |
| `MAJOR` | `515` |
| `BACKPORT_MINOR` | `1600` |

## Variables

| Variable | Job | Description | Example |
| --- | --- | --- | --- |
| `VERSION` | build a specific version | Full `major.minor` version to build. | `516.1659` |
| `MAJOR` | backport a major | Major version to build (newest minor is auto-detected). | `515` |
| `BACKPORT_MINOR` | backport a major | Pin an exact minor instead of auto-detecting. | `1600` |
| `FORCE_OVERWRITE` | either | Rebuild and overwrite a tag that already exists. | `true` |

> Note: these jobs never move the `latest` or `beta` tags — only the hourly release does that.
