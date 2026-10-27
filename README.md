# Guac-Forge

A Docker image for [Apache Guacamole](https://guacamole.apache.org/), the clientless remote desktop gateway. It supports VNC, RDP, and SSH over HTML5 from a single self-contained container: the Guacamole web client, the `guacd` server, and a PostgreSQL database.

> **Status:** early-stage fork and learning project. Expect frequent small changes while I work on CI, version bumps, and reliability fixes. See the [Roadmap](#roadmap).

## Lineage and attribution

Guac-Forge is a fork of [jwetzell/docker-guacamole](https://github.com/jwetzell/docker-guacamole), which is itself a continuation of [oznu/docker-guacamole](https://github.com/oznu/docker-guacamole). Thanks to both authors for the original work. Their history is preserved in this repository.

Guac-Forge is an independent project. It is not affiliated with, endorsed by, or sponsored by the Apache Software Foundation. Apache Guacamole, Guacamole, Apache, and the Apache feather logo are trademarks of the Apache Software Foundation.

## Usage

```shell
docker run \
  -p 8080:8080 \
  -v </path/to/config>:/config \
  <registry>/<your-user>/guac-forge:<tag>
```

Until the first Guac-Forge release is published, [build from source](#build-from-source).

The image is multi-platform and runs on amd64 and ARM hosts, including Raspberry Pi boards, using the same command on every platform. It also runs on Docker Desktop for Mac and Windows and on Synology DSM.

## Parameters

Each parameter has two halves separated by a colon: the left side is the host, the right side is the container.

* `-p 8080:8080` - Binds the service to port 8080 on the Docker host. **Required.**
* `-v /config` - Location of the config and database. **Required.**
* `-e EXTENSIONS` - Comma-separated list of Guacamole extensions to enable. See below.

## Enabling extensions

Enable extensions with the `EXTENSIONS` variable, as a comma-separated list with no spaces:

```shell
docker run \
  -p 8080:8080 \
  -v </path/to/config>:/config \
  -e "EXTENSIONS=auth-ldap,auth-duo" \
  <registry>/<your-user>/guac-forge:<tag>
```

Available extensions:

* `auth-ban` - [Blocking brute-force attacks](https://guacamole.apache.org/doc/gug/auth-ban.html)
* `auth-duo` - [Duo two-factor authentication](https://guacamole.apache.org/doc/gug/duo-auth.html)
* `auth-header` - [HTTP header authentication](https://guacamole.apache.org/doc/gug/header-auth.html)
* `auth-json` - [Encrypted JSON authentication](https://guacamole.apache.org/doc/gug/json-auth.html)
* `auth-ldap` - [LDAP authentication](https://guacamole.apache.org/doc/gug/ldap-auth.html)
* `auth-quickconnect` - [Ad-hoc connections](https://guacamole.apache.org/doc/gug/adhoc-connections.html)
* `auth-restrict` - [Login / connection restrictions](https://guacamole.apache.org/doc/gug/auth-restrict.html)
* `auth-sso-cas` - [CAS authentication](https://guacamole.apache.org/doc/gug/cas-auth.html)
* `auth-sso-openid` - [OpenID authentication](https://guacamole.apache.org/doc/gug/openid-auth.html)
* `auth-sso-saml` - [SAML authentication](https://guacamole.apache.org/doc/gug/saml-auth.html)
* `auth-totp` - [TOTP two-factor authentication](https://guacamole.apache.org/doc/gug/totp-auth.html)
* `history-recording-storage` - [Session recording playback](https://guacamole.apache.org/doc/gug/recording-playback.html)
* `vault` - [Retrieving secrets from a vault](https://guacamole.apache.org/doc/gug/vault.html)

Only enable the extensions you need. An extension that is misconfigured in `guacamole.properties` can prevent the system from loading. See the [official documentation](https://guacamole.apache.org/doc/gug/) for details.

## Default user

The default username is `guacadmin` with the password `guacadmin`. **Change this password immediately after your first login**, especially if the container is reachable from outside your local network.

## Docker Compose

```yaml
services:
  guacamole:
    image: <registry>/<your-user>/guac-forge:<tag>
    container_name: guacamole
    volumes:
      - postgres:/config
    ports:
      - 8080:8080
volumes:
  postgres:
    driver: local
```

### Windows-based Docker hosts

Bind-mounted volumes behave differently under Docker for Windows, and you may hit PostgreSQL file-permission problems. Using a named volume with the `local` driver, as in the example above, avoids this and keeps your config across upgrades and container recreation. Stop the container gracefully, or data may be lost.

## Build from source

```shell
git clone https://github.com/<your-user>/guac-forge.git
cd guac-forge
docker build --pull -t guac-forge:dev .
docker run -p 8080:8080 -v "$(pwd)/config:/config" guac-forge:dev
```

## Roadmap

Planned work, roughly in order:

- [ ] Publish the first tagged image from CI (multi-arch build)
- [ ] Add a container healthcheck
- [ ] Investigate the "pg_isready not found" error some users reported when upgrading from older images
- [ ] Track current Apache Guacamole, Tomcat, and base-image releases
- [ ] Add image vulnerability scanning to CI
- [ ] Investigate the Duo extension's deprecated "Traditional Prompt" issue (the fix likely belongs upstream in Apache Guacamole)
- [ ] Document a split compose setup (separate Postgres, `guacd`, and web app)

## Contributing

Issues and pull requests are welcome, including small documentation fixes.

**AI-assisted contributions are welcome.** The bar is the same as for any other change: it must be correct, tested, and something you can explain.

* You are the author of whatever you submit. "The tool wrote it" is not an answer to a review question.
* Please mention in the PR description if AI tools helped, and what you did to verify the result.
* Keep changes small and focused, and open an issue first for anything large.

## License

See [LICENSE](LICENSE). This project inherits the license of the upstream repositories it was forked from.
