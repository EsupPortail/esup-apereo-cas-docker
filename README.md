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
├── docker-example/             # Example configuration files for CAS and the LDAP test server
├── build.sh                    # Script to build the CAS images locally or in CI
└── .github/
	└── workflows/
		├── build-and-push.yml  # CI: build & push on every tag
		└── validate-build.yml  # CI: validates build.sh on pushes / PRs
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
cas.version=7.3.6
```

Bump this file and push a new tag to trigger a CI build.

## Build images locally

The repository provides a single entry point to build both images from the official CAS starter:

```bash
./build.sh
```

This produces the following images locally, tagged with the version found in `version.properties`:

- `ghcr.io/esupportail/apereo-cas-ldap:<cas.version>`
- `ghcr.io/esupportail/apereo-cas-ldap-mfa:<cas.version>`

To push them to GHCR after authenticating with Docker:

```bash
docker login ghcr.io
./build.sh --push
```

## CI / Release workflow

Images are built and pushed automatically by GitHub Actions on every pushed tag matching `v*.*.*`.

To release a new version:
```bash
# 1. Update the version
echo "cas.version=7.3.6" > version.properties
git add version.properties
git commit -m "chore: bump CAS to 7.3.6"

# 2. Tag and push — this triggers the CI build
git tag v7.3.6
git push origin main --tags
```

The release workflow validates that the Git tag matches `cas.version`, then builds both `apereo-cas-ldap` and `apereo-cas-ldap-mfa` and pushes them to [GHCR](https://ghcr.io) under the repository owner namespace.

## Previously on Docker Hub

These images were previously published on Docker Hub:

- https://hub.docker.com/r/esupportail/apereo-cas-ldap
- https://hub.docker.com/r/esupportail/apereo-cas-ldap-mfa