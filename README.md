# apereo-cas-docker

[Apereo CAS](https://apereo.github.io/cas) images for dev/test environments, published to GHCR by [EsupPortail](https://github.com/EsupPortail).

| Image                                                                                                                                 | Description |
|---------------------------------------------------------------------------------------------------------------------------------------|---|
| [`ghcr.io/esupportail/apereo-cas-ldap`](https://github.com/EsupPortail/esup-apereo-cas-docker/pkgs/container/apereo-cas-ldap)         | CAS + LDAP authentication |
| [`ghcr.io/esupportail/apereo-cas-ldap-mfa`](https://github.com/EsupPortail/esup-apereo-cas-docker/pkgs/container/apereo-cas-ldap-mfa) | CAS + LDAP + MFA |

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
   cas.version=8.x.x
   ```

2. Commit, tag and push:
   ```bash
   git add version.properties
   git commit -m "chore: bump CAS to 8.x.x"
   git tag v8.x.x
   git push origin main --tags
   ```

The CI workflow automatically builds, checks and pushes both images to GHCR.
Only `version.properties` needs to change for a CAS version update.

The build downloads one base overlay from https://getcas.apereo.org for the requested
CAS version and reuses it for both images. Required dependencies are added explicitly
to its `build.gradle`, independently of the starter's module selection:

- LDAP: `cas-server-support-ldap`.
- LDAP + MFA: LDAP plus `cas-server-support-simple-mfa`,
  `cas-server-support-trusted-mfa-mongo` and `cas-server-core-scripting` (Groovy).

HTTP 429 and transient server errors are retried with a delay. The starter must still
be available; no generated overlay is maintained in this repository. Before publishing,
the script checks both final images for the expected module JARs at the requested CAS
version (including libraries inside a WAR). A missing module aborts publication.
This checks packaging; it does not replace runtime authentication tests.

## Local build

```bash
# Build only
./build.sh

# Build and push on ghcr.io (you need rights on github repository and setup a 'Personal access tokens (classic)' on https://github.com/settings/credentials
docker login ghcr.io
./build.sh --push
```

Requires Bash, curl, unzip and Docker. The generated image must include `sh`, `find`,
and the JDK `jar` tool for archive inspection.

Optional environment variables: `REGISTRY` (default `ghcr.io`), `NAMESPACE` (default
`esupportail`) and `CAS_STARTER_URL` (default `https://getcas.apereo.org/starter.zip`).
