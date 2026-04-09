# apereo-cas-docker

[Apereo CAS](https://apereo.github.io/cas) images for dev/test environments, published to GHCR by [EsupPortail](https://github.com/EsupPortail).

| Image | Description |
|---|---|
| `ghcr.io/esupportail/apereo-cas-ldap` | CAS + LDAP authentication |
| `ghcr.io/esupportail/apereo-cas-ldap-mfa` | CAS + LDAP + MFA |

## Quick start

```bash
docker compose -f docker-compose-example.yml up
```

CAS available at `http://localhost:8080/cas`.

Credentials:
- `admin` / `pass`
- `joe` / `pass`
- `jack` / `pass`

## Release a new version

1. Update `version.properties`:
   ```properties
   cas.version=7.x.x
   ```

2. Commit, tag and push:
   ```bash
   git add version.properties
   git commit -m "chore: bump CAS to 7.x.x"
   git tag v7.x.x
   git push origin main --tags
   ```

The CI workflow will automatically build and push both images to GHCR.

## Local build

```bash
# Build only
./build.sh

# Build and push
docker login ghcr.io
./build.sh --push
```
