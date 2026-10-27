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
  ghcr.io/justinkocian/guac-forge:latest
```

`latest` tracks the `master` branch. Releases are also tagged by version (for example `1.2.0` and `1.2`), and every build is tagged with its commit (`sha-<commit>`). You can also [build from source](#build-from-source).

The image is multi-platform and runs on amd64 and ARM hosts, including Raspberry Pi boards, using the same command on every platform. It also runs on Docker Desktop for Mac and Windows and on Synology DSM.

## Parameters

Each parameter has two halves separated by a colon: the left side is the host, the right side is the container.

* `-p 8080:8080` - Binds the service to port 8080 on the Docker host. **Required.**
* `-v /config` - Location of the config and database. **Required.**
* `-e EXTENSIONS` - Comma-separated list of Guacamole extensions to enable. See below.
* `-e TRUSTED_PROXIES` - Reverse proxies allowed to report the real client IP. See [Running behind a reverse proxy](#running-behind-a-reverse-proxy).

## Enabling extensions

Enable extensions with the `EXTENSIONS` variable, as a comma-separated list with no spaces:

```shell
docker run \
  -p 8080:8080 \
  -v </path/to/config>:/config \
  -e "EXTENSIONS=auth-ldap,auth-duo" \
  ghcr.io/justinkocian/guac-forge:latest
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
* `branding` - Custom login page branding. See [Custom branding](#custom-branding)
* `history-recording-storage` - [Session recording playback](https://guacamole.apache.org/doc/gug/recording-playback.html)
* `vault` - [Retrieving secrets from a vault](https://guacamole.apache.org/doc/gug/vault.html)

Only enable the extensions you need. An extension that is misconfigured in `guacamole.properties` can prevent the system from loading. See the [official documentation](https://guacamole.apache.org/doc/gug/) for details.

## Custom branding

The `branding` extension replaces the stock login page with a modern login card and lets you set your own title, logo, and colors. It is off by default. Enable it like any other extension:

```shell
docker run \
  -p 8080:8080 \
  -v </path/to/config>:/config \
  -e "EXTENSIONS=branding" \
  -e "BRANDING_TITLE=Acme Remote Access" \
  ghcr.io/justinkocian/guac-forge:latest
```

The extension is rebuilt every time the container starts, so a restart applies any change. There is no manual zipping or jar building.

### Quick settings

These environment variables cover the common changes:

* `BRANDING_TITLE` - Title on the login card and browser tab.
* `BRANDING_SUBTITLE` - Text below the title. Hidden when unset.
* `BRANDING_SSO_TEXT` - Label for the SSO button, when exactly one SSO provider is enabled.
* `BRANDING_SHOW_LOCAL` - `true` or `false`. Show the username and password form. Defaults to `true`.
* `BRANDING_SHOW_SSO` - `true` or `false`. Show the SSO button. Defaults to `true` only when an `auth-sso-*` extension is enabled.

### Full control

To change the logo, colors, or anything else, copy the default branding files out of the image into your config volume:

```shell
docker cp <container>:/app/branding </path/to/config>/branding
```

Then edit the files in `</path/to/config>/branding` and restart the container. When that folder exists, it is used instead of the built-in default.

* `images/logo.png` - Login logo.
* `css/modern-login.css` - Colors are CSS variables in the `:root` block at the top.
* `js/login-config.js` - The same settings as the environment variables above. The environment variables win when both are set.

If your browser still shows the old look after a restart, do a hard refresh.

The branding extension is adapted from [l4rm4nd/Guacamole-Custom-Login](https://github.com/l4rm4nd/Guacamole-Custom-Login) (GPL-3.0), which builds on the approach of [Zer0CoolX/guacamole-customize-loginscreen-extension](https://github.com/Zer0CoolX/guacamole-customize-loginscreen-extension).

## Running behind a reverse proxy

By default, Guacamole sees the IP of whatever connects to the container. Behind a reverse proxy (nginx, Traefik, Caddy), that is the proxy itself, so every client looks the same. Login history shows one address for everyone. With `auth-ban` enabled, a few failed logins from any one client lock out all users.

Set `TRUSTED_PROXIES` to your proxy's IP, and Guacamole uses the client IP from the proxy's `X-Forwarded-For` header instead:

```yaml
services:
  guacamole:
    image: ghcr.io/justinkocian/guac-forge:latest
    environment:
      - TRUSTED_PROXIES=172.30.0.10
    volumes:
      - postgres:/config
    networks:
      proxy:
        ipv4_address: 172.30.0.5
  nginx:
    image: nginx:alpine
    ports:
      - 443:443
    networks:
      proxy:
        ipv4_address: 172.30.0.10
networks:
  proxy:
    ipam:
      config:
        - subnet: 172.30.0.0/16
volumes:
  postgres:
    driver: local
```

The proxy must send `X-Forwarded-For`. For nginx, use `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;`.

* The value is a comma-separated list of IPs, or CIDR ranges ending in `/8`, `/16`, `/24` or `/32`. Unsupported entries are skipped with a message in the container log.
* **Trust only the proxy's exact IP**, and give the proxy a fixed address as in the example. Any address you list can claim to be any client.
* **Do not trust a whole Docker network while Guacamole's port is published.** Requests to a published port arrive from the network's gateway (for example `172.30.0.1`), which is inside the network's range. Anyone who can reach the port could then fake their IP and get around `auth-ban`. If you must trust a range, do not publish port 8080, so all traffic goes through the proxy.
* Leave `TRUSTED_PROXIES` unset when clients connect to the container directly.

## Default user

The default username is `guacadmin` with the password `guacadmin`. **Change this password immediately after your first login**, especially if the container is reachable from outside your local network.

## Docker Compose

The repository includes a ready-to-use [docker-compose.yml](docker-compose.yml). Download it, edit the `environment` section, and start it:

```shell
curl -LO https://raw.githubusercontent.com/justinKocian/guac-forge/master/docker-compose.yml
docker compose up -d
```

Every option is listed in the file with a comment, including extensions, branding, and `TRUSTED_PROXIES`. Empty values use the defaults.

### Setting guacamole.properties with environment variables

Any [`guacamole.properties` setting](https://guacamole.apache.org/doc/gug/configuring-guacamole.html) can be set as an environment variable instead of editing the file in the config volume. Use uppercase and replace dashes with underscores. For example, `ldap-hostname` becomes `LDAP_HOSTNAME`. Environment variables take precedence over the file. The compose file has commented examples for LDAP, OpenID, TOTP, and `auth-ban`.

To upgrade, run `docker compose pull && docker compose up -d`. Your data stays in the `guac-config` volume.

### Windows-based Docker hosts

Bind-mounted volumes behave differently under Docker for Windows, and you may hit PostgreSQL file-permission problems. The included compose file uses a named volume, which avoids this and keeps your config across upgrades and container recreation. Stop the container gracefully (the compose file allows one minute), or data may be lost.

## Build from source

```shell
git clone https://github.com/justinKocian/guac-forge.git
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
