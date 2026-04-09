# apereo-cas-docker

Images [Apereo CAS](https://apereo.github.io/cas) pour environnements de dev/test, publiées sur GHCR par [EsupPortail](https://github.com/EsupPortail).

| Image | Description |
|---|---|
| `ghcr.io/esupportail/apereo-cas-ldap` | CAS + authentification LDAP |
| `ghcr.io/esupportail/apereo-cas-ldap-mfa` | CAS + LDAP + MFA |

## Quick start

```bash
docker compose -f docker-compose-example.yml up
```

CAS disponible sur `http://localhost:8080/cas`.

## Publier une nouvelle version

1. Mettre à jour `version.properties` :
   ```properties
   cas.version=7.x.x
   ```

2. Committer, tagger et pousser :
   ```bash
   git add version.properties
   git commit -m "chore: bump CAS to 7.x.x"
   git tag v7.x.x
   git push origin main --tags
   ```

Le workflow CI construit et publie automatiquement les deux images sur GHCR.

## Build local

```bash
# Build uniquement
./build.sh

# Build + push
docker login ghcr.io
./build.sh --push
```
