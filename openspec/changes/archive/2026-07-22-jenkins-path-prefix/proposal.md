## Why

Today Jenkins and the `nita-webapp` are two separate entry points: users reach the
webapp on one host/port and Jenkins on `:8443` with its own TLS keystore. The webapp
already tries to surface Jenkins under a single origin at `/jenkins/`, but does so with
a fragile nginx `sub_filter` hack that rewrites `href="/"`/`src="/"` "on a best-effort
basis" because Jenkins serves all its URLs from the server root. That approach leaks on
JavaScript-built URLs, form actions, Ajax calls, and redirects.

Running Jenkins natively under the `--prefix=/jenkins` context path makes Jenkins emit
correct `/jenkins/...` URLs itself, lets the reverse proxy pass traffic through cleanly
(no rewriting), scopes the Jenkins session cookie to `/jenkins` so it never collides
with the webapp cookie at `/`, and consolidates everything behind the single nginx TLS
terminator — retiring Jenkins' own `:8443` HTTPS listener and keystore.

## What Changes

- **`docker-compose.yaml` / `JENKINS_OPTS`**: add `--prefix=/jenkins` so Jenkins serves
  its entire UI and API under the `/jenkins` context path
- **`basic-security.groovy`**: set `JenkinsLocationConfiguration` root URL (from a new
  `JENKINS_URL` environment variable) so Jenkins generates correct external self-URLs
  (`https://<host>/jenkins/`) behind the proxy
- **`Dockerfile` HEALTHCHECK**: probe the prefixed path (`/jenkins/login`) instead of the
  bare root
- **`cli_scripts/*`**: append `/jenkins` to the Jenkins CLI `-s` endpoint so `jenkins-cli.jar`
  reaches the prefixed server
- **`backup_script/*`**: append `/jenkins` to the Jenkins endpoints used by backup/restore

Cross-repo companion changes (tracked in `nita-webapp`, see design.md — not in this change):
nginx `proxy_pass` cleanup (delete `sub_filter`), backend `JENKINS_SERVER_URL` gains the
`/jenkins` suffix, and the k8s deployment drops the `:8443` exposure in favour of
plain-HTTP-behind-nginx.

## Capabilities

### New Capabilities

<!-- None — this change adds a URL path prefix to existing capabilities -->

### Modified Capabilities

- `container-runtime`: `JENKINS_OPTS` gains `--prefix=/jenkins`; a new `JENKINS_URL`
  environment variable configures the external root URL
- `container-image`: HEALTHCHECK probes the `/jenkins` path prefix
- `jenkins-security`: init script sets the Jenkins root URL for reverse-proxy operation
- `cli-commands`: Jenkins CLI endpoint includes the `/jenkins` path prefix
- `backup-restore`: backup/restore endpoints include the `/jenkins` path prefix

## Impact

- Jenkins UI and REST API move from `/` to `/jenkins/...`; any hardcoded root-path caller
  must add the prefix
- Callers on the internal port (webapp Django backend) must target
  `http://jenkins:8080/jenkins` instead of `http://jenkins:8080`
- The `nita-webapp` nginx `/jenkins/` location can drop all `sub_filter`/`proxy_redirect`
  rewriting once Jenkins is prefixed
- Must be deployed in coordination with the `nita-webapp` changes: if Jenkins gets the
  prefix before nginx/backend are updated (or vice-versa), `/jenkins/` requests 404 and
  the backend cannot reach jobs
