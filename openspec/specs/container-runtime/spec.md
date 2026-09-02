# Container Runtime Specification

## Purpose
Defines how the nita-jenkins container is deployed at runtime via Docker Compose:
port mapping, volume mounts, networking, TLS configuration, and restart behaviour.
## Requirements
### Requirement: HTTPS port exposure
The system SHALL expose Jenkins on host port 8443 mapped to container port 8443.

#### Scenario: Jenkins reachable from host browser
- GIVEN the container is running
- WHEN a browser connects to `https://localhost:8443`
- THEN the Jenkins UI is returned

### Requirement: Docker socket bind-mount
The system SHALL mount the host Docker socket (`/var/run/docker.sock`) into the container so Jenkins jobs can launch sibling containers.

#### Scenario: Jenkins pipeline can run Docker commands
- GIVEN the Docker socket is mounted
- WHEN a pipeline step executes `docker run`
- THEN the command uses the host Docker daemon

### Requirement: Docker binary bind-mount read-only
The system SHALL mount the host `docker` binary at `/usr/bin/docker` as read-only.

#### Scenario: Docker CLI available inside container without installing Docker
- GIVEN the host docker binary is mounted read-only
- WHEN a pipeline step calls `docker`
- THEN the host binary is used without needing Docker installed in the image

### Requirement: Project directory mount
The system SHALL mount `/var/nita_project` from the host at `/project` inside the container with read-write access.

#### Scenario: Pipeline reads and writes project files
- GIVEN the project directory is mounted
- WHEN a Jenkins job writes output to `/project/`
- THEN files appear under `/var/nita_project/` on the host

### Requirement: Jenkins home persistent volume
The system SHALL use a named Docker volume `jenkins_home` for `/var/jenkins_home` to persist Jenkins state across container recreations.

#### Scenario: Jobs survive image upgrade
- GIVEN the `jenkins_home` named volume exists
- WHEN the container is recreated with a new image version
- THEN existing Jenkins jobs and configuration are present

### Requirement: TLS keystore mount
The system SHALL mount a JKS keystore from `./certificates/jenkins_keystore.jks` into the container at `/var/jenkins_home/jenkins_keystore.jks`.

#### Scenario: Jenkins serves valid HTTPS
- GIVEN a valid keystore file is present at `./certificates/jenkins_keystore.jks`
- WHEN the container starts
- THEN Jenkins accepts TLS connections using that certificate

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

### Requirement: NITA network membership
The system SHALL attach the Jenkins container to the pre-existing external Docker network `nita-network`.

#### Scenario: Jenkins can reach other NITA containers by hostname
- GIVEN another NITA service is on `nita-network`
- WHEN Jenkins attempts to connect to it by service hostname
- THEN the connection succeeds

### Requirement: Automatic restart policy
The system SHALL set `restart: always` so Jenkins restarts automatically after host reboots or container crashes.

#### Scenario: Jenkins restarts after host reboot
- GIVEN the host reboots with Docker configured to start on boot
- WHEN Docker starts
- THEN the Jenkins container starts automatically

### Requirement: External root URL via JENKINS_URL
The system SHALL accept a `JENKINS_URL` environment variable specifying the external root URL (including the `/jenkins/` prefix) that Jenkins advertises when running behind a TLS-terminating reverse proxy.

#### Scenario: External root URL provided
- GIVEN the container starts with `JENKINS_URL=https://<host>/jenkins/`
- WHEN Jenkins generates an absolute self-URL
- THEN the URL uses the `https://<host>/jenkins/` origin rather than the internal `http://jenkins:8080` origin

