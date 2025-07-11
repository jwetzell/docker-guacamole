[![Docker Pulls](https://img.shields.io/docker/pulls/jwetzell/guacamole?label=pulls) ![Docker Stars](https://img.shields.io/docker/stars/jwetzell/guacamole?label=stars)](https://hub.docker.com/r/jwetzell/guacamole)

# Docker Guacamole

**THIS REPO IS A CONTINUATION OF [oznu/docker-guacamole](https://github.com/oznu/docker-guacamole).**

A Docker Container for [Apache Guacamole](https://guacamole.apache.org/), a client-less remote desktop gateway. It supports standard protocols like VNC, RDP, and SSH over HTML5.

This image will run on most platforms that support Docker including Docker for Mac, Docker for Windows, Synology DSM and Raspberry Pi 3 boards.

[![IMAGE ALT TEXT](http://img.youtube.com/vi/esgaHNRxdhY/0.jpg)](http://www.youtube.com/watch?v=esgaHNRxdhY "Video Title")

This container runs the guacamole web client, the guacd server and a postgres database.

## Usage

```shell
docker run \
  -p 8080:8080 \
  -v </path/to/config>:/config \
  jwetzell/guacamole:1.6.0-20250711
```

## Raspberry Pi / ARMv7

Now that the image has been converted to a multi-platform image the command for Raspberry Pi's or other ARM devices is the same.

```shell
docker run \
  -p 8080:8080 \
  -v </path/to/config>:/config \
  jwetzell/guacamole:1.6.0-20250711
```

## Parameters

The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the container side.

* `-p 8080:8080` - Binds the service to port 8080 on the Docker host, **required**
* `-v /config` - The config and database location, **required**
* `-e EXTENSIONS` - See below for details.

## Enabling Extensions

Extensions can be enabled using the `-e EXTENSIONS` variable. Multiple extensions can be enabled using a comma separated list without spaces.

For example:

```shell
docker run \
  -p 8080:8080 \
  -v </path/to/config>:/config \
  -e "EXTENSIONS=auth-ldap,auth-duo"
  jwetzell/guacamole:1.6.0-20250711
```

Currently the available extensions are:

* auth-ban - [Blocking brute-force attacks](https://guacamole.apache.org/doc/gug/auth-ban.html)
* auth-duo - [Duo two-factor authentication](https://guacamole.apache.org/doc/gug/duo-auth.html)
* auth-header - [HTTP header authentication](https://guacamole.apache.org/doc/gug/header-auth.html)
* auth-json - [Encrypted JSON Authentication](https://guacamole.apache.org/doc/gug/json-auth.html)
* auth-ldap - [LDAP Authentication](https://guacamole.apache.org/doc/gug/ldap-auth.html)
* auth-quickconnect - [Ad-hoc connections extension](https://guacamole.apache.org/doc/gug/adhoc-connections.html)
* auth-sso-cas - [CAS Authentication](https://guacamole.apache.org/doc/gug/cas-auth.html)
* auth-sso-openid - [OpenID Authentication](https://guacamole.apache.org/doc/gug/openid-auth.html)
* auth-sso-saml - [SAML Authentication](https://guacamole.apache.org/doc/gug/saml-auth.html)
* auth-restrict - [Login / Connection restrictions](https://guacamole.apache.org/doc/gug/auth-restrict.html)
* auth-totp - [TOTP two-factor authentication](https://guacamole.apache.org/doc/gug/totp-auth.html)
* history-recording-storage - [Session Recording Playback](https://guacamole.apache.org/doc/gug/recording-playback.html#)
* vault - [Retrieving secrets from a vault](https://guacamole.apache.org/doc/gug/vault.html)

You should only enable the extensions you require, if an extensions is not configured correctly in the `guacamole.properties` file it may prevent the system from loading. See the [official documentation](https://guacamole.apache.org/doc/gug/) for more details.

## Default User

The default username is `guacadmin` with password `guacadmin`.

## Windows-based Docker Hosts

Mapped volumes behave differently when running Docker for Windows and you may encounter some issues with PostgreSQL file system permissions. To avoid these issues, and still retain your config between container upgrades and recreation, you can use the local volume driver, as shown in the `docker-compose.yml` example below. When using this setup be careful to gracefully stop the container or data may be lost.

```yml
version: "2"
services:
  guacamole:
    image: jwetzell/guacamole:1.6.0-20250711
    container_name: guacamole
    volumes:
      - postgres:/config
    ports:
      - 8080:8080
volumes:
  postgres:
    driver: local
```
