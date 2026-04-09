
# Build the CAS overlay with LDAP support only
mkdir cas && cd cas
curl -o overlay.zip https://getcas.apereo.org/starter.zip -d type=cas-overlay -d dependencies=support-ldap -d casVersion=x.y.z
unzip overlay.zip
docker compose build
docker image  tag docker.io/library/cas-cas esupportail/apereo-cas-ldap:x.y.z
docker push esupportail/apereo-cas-ldap:x.y.z

# Build the CAS overlay with both LDAP and MFA support
mkdir cas && cd cas
curl -o overlay.zip https://getcas.apereo.org/starter.zip -d type=cas-overlay -d dependencies=support-ldap,support-simple-mfa,groovy -d casVersion=x.y.z
unzip overlay.zip
docker compose build
docker image  tag docker.io/library/cas-cas esupportail/apereo-cas-ldap-mfa:x.y.z
docker push esupportail/apereo-cas-ldap-mfa:x.y.z

