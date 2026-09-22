# Container Image Specification

## Purpose
Defines how the nita-jenkins Docker image is built, what base image it uses,
which tools are installed, and how the image is tagged and health-checked.
## Requirements
### Requirement: Base image
The system SHALL use the pinned `jenkins/jenkins:2.568.2-jdk21` image as both the Python builder base and final Jenkins runtime base.

#### Scenario: Image uses the tested Java 21 LTS release
- **WHEN** the nita-jenkins Dockerfile is built
- **THEN** both stages derive from `jenkins/jenkins:2.568.2-jdk21`

### Requirement: Setup wizard disabled
The system SHALL disable the Jenkins setup wizard on first boot.

#### Scenario: No interactive setup on first start
- GIVEN the container starts for the first time
- WHEN Jenkins completes its startup sequence
- THEN Jenkins proceeds directly to the main UI without prompting for initial configuration

### Requirement: CSP header relaxed for same-origin
The system SHALL set the Content-Security-Policy to `allow-same-origin` to support embedded build reports.

#### Scenario: Same-origin resources load in build views
- GIVEN a build page that embeds a report from the same origin
- WHEN the page is loaded in a browser
- THEN the browser does not block the content due to CSP restrictions

### Requirement: Architecture-aware kubectl installation
The system SHALL install a pinned `kubectl` release selected with BuildKit `TARGETARCH`, verify it using the committed checksum for `amd64` or `arm64`, and reject unsupported architectures.

#### Scenario: Verified amd64 kubectl
- **WHEN** `TARGETARCH` is `amd64`
- **THEN** the amd64 binary is installed at `/usr/local/bin/kubectl` only after its SHA-256 checksum succeeds

#### Scenario: Verified arm64 kubectl
- **WHEN** `TARGETARCH` is `arm64`
- **THEN** the arm64 binary is installed at `/usr/local/bin/kubectl` only after its SHA-256 checksum succeeds

#### Scenario: Unsupported kubectl architecture
- **WHEN** `TARGETARCH` is neither `amd64` nor `arm64`
- **THEN** the image build fails without installing an unverified binary

### Requirement: System packages installed
The final image SHALL contain only the operating-system packages required by NITA Jenkins jobs: `apache2-suexec-custom`, `ca-certificates`, `curl`, `git`, `openssh-client`, `python3`, and `sshpass`; compiler, development-header, editor, wget, and Git LFS packages SHALL NOT remain in the runtime.

#### Scenario: Required runtime tools are available
- **WHEN** a Jenkins job runs in the final image
- **THEN** Git, curl, Python, SSH, and sshpass are available on `PATH`

#### Scenario: Build-only tools are excluded
- **WHEN** the final runtime filesystem is inspected
- **THEN** the Python compiler toolchain and Git LFS executable are absent

### Requirement: Python scripts deployed to PATH
The system SHALL copy `write_yaml_files.py`, `robot.py`, and `create_ansible_job_k8s.py` to `/usr/local/bin` and make them executable.

#### Scenario: Scripts callable from Jenkins pipeline
- GIVEN the built container image
- WHEN a Jenkins pipeline step calls `write_yaml_files.py` without a path prefix
- THEN the script is found and executed

### Requirement: Image version tag sourced from VERSION.txt
The system SHALL be tagged using the version string from `VERSION.txt` when built via `build_container.sh`.

#### Scenario: Reproducible image tag
- GIVEN `VERSION.txt` contains `23.12`
- WHEN `build_container.sh` is executed
- THEN the resulting image is tagged `juniper/nita-jenkins:23.12`

### Requirement: Jenkins volumes declared
The system SHALL declare two volumes: `/usr/share/jenkins/ref/plugins` and `/var/jenkins_home`.

#### Scenario: Persistent state survives container restart
- GIVEN a named volume mounted at `/var/jenkins_home`
- WHEN the container is stopped and a new one started with the same volume
- THEN Jenkins jobs, configuration, and installed plugins are preserved

### Requirement: Health check on HTTPS
The system SHALL include a Docker HEALTHCHECK that performs a request to the prefixed Jenkins path (`/jenkins/login`) and exits non-zero if the response is not received.

#### Scenario: Container reports healthy when Jenkins is up
- GIVEN Jenkins is fully started and serving under the `/jenkins` prefix
- WHEN the Docker health check requests `/jenkins/login`
- THEN a successful response is received and `docker inspect` reports the container status as `healthy`

#### Scenario: Container reports unhealthy when the prefix is unreachable
- GIVEN Jenkins is not serving under the `/jenkins` prefix
- WHEN the Docker health check requests `/jenkins/login`
- THEN no successful response is received and the health check exits non-zero

