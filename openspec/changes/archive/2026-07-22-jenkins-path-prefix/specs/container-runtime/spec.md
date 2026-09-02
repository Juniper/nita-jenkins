## MODIFIED Requirements

### Requirement: HTTPS configured via JENKINS_OPTS
The system SHALL configure Jenkins via `JENKINS_OPTS` using the mounted keystore with password `nita123`, HTTPS on port 8443, and HTTP on port 8080, and SHALL additionally serve its entire UI and API under the `/jenkins` context path using `--prefix=/jenkins`.

#### Scenario: Jenkins starts with HTTPS enabled
- GIVEN the container starts with the keystore mounted
- WHEN Jenkins reads `JENKINS_OPTS`
- THEN it serves on `--httpsPort=8443` with the mounted keystore and password `nita123`

#### Scenario: Jenkins serves under the /jenkins prefix
- GIVEN the container starts with `--prefix=/jenkins` in `JENKINS_OPTS`
- WHEN a client requests `/jenkins/login`
- THEN the Jenkins login page is returned
- AND a request to the bare root `/login` is not served by Jenkins

#### Scenario: Jenkins generates prefixed URLs
- GIVEN Jenkins is running with `--prefix=/jenkins`
- WHEN Jenkins renders a page or issues a redirect
- THEN the emitted asset, form-action, and redirect URLs are rooted at `/jenkins/`

## ADDED Requirements

### Requirement: External root URL via JENKINS_URL
The system SHALL accept a `JENKINS_URL` environment variable specifying the external root URL (including the `/jenkins/` prefix) that Jenkins advertises when running behind a TLS-terminating reverse proxy.

#### Scenario: External root URL provided
- GIVEN the container starts with `JENKINS_URL=https://<host>/jenkins/`
- WHEN Jenkins generates an absolute self-URL
- THEN the URL uses the `https://<host>/jenkins/` origin rather than the internal `http://jenkins:8080` origin
