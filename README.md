# apereo-cas-docker

Docker images for [Apereo CAS](https://apereo.github.io/cas) — built and maintained by [EsupPortail](https://github.com/EsupPortail) for testing and development purposes.

Two image flavours are published to the GitHub Container Registry:

| Image | Description |
|---|---|
| `ghcr.io/esupportail/apereo-cas-ldap` | CAS with LDAP authentication |
| `ghcr.io/esupportail/apereo-cas-ldap-mfa` | CAS with LDAP authentication + MFA |

> **Scope:** These images are intended for **dev/test environments only** and are not hardened for production use.

---

## Repository layout
```
.
├── README.md
├── version.properties          # CAS version tracked here
├── docker-compose-example.yml  # Example of docker-compose to use docker images : ready-to-run stack (CAS + OpenLDAP)
├── docker-compose-example      # Example of configuration files for docker cas configuration and docker ldap server
├── build.sh                    # Script to build and push images to GHCR
└── workflows/                  # GitHub Actions workflows
└── build-and-push.yml          # CI: build & push on every tag
```

## Quick start

The provided `docker-compose-example.yml` spins up a full CAS stack with a pre-configured OpenLDAP directory.

```bash
git clone https://github.com/EsupPortail/apereo-cas-docker.git
cd apereo-cas-docker
docker compose -f docker-compose-example.yml up
```

CAS will be available at `http://localhost:8080/cas`.  
Default test credentials are defined in the compose file.

## CAS version

The CAS version used to build the images is tracked in [`version.properties`](version.properties):

```properties
cas.version=8.x.x
```

Bump this file and push a new tag to trigger a CI build.

## CI / Release workflow

Images are built and pushed automatically by GitHub Actions on every pushed tag matching `v*.*.*`.

To release a new version:
```bash
# 1. Update the version
echo "cas.version=8.x.x" > version.properties
git add version.properties
git commit -m "chore: bump CAS to 8.x.x"

# 2. Tag and push — this triggers the CI build
git tag v8.x.x
git push origin main --tags
```

The workflow builds both `apereo-cas-ldap` and `apereo-cas-ldap-mfa` and pushes them to [GHCR](https://ghcr.io) under the `EsupPortail` namespace.

## Previously on Docker Hub

These images were previously published on Docker Hub:

- https://hub.docker.com/r/esupportail/apereo-cas-ldap
- https://hub.docker.com/r/esupportail/apereo-cas-ldap-mfa