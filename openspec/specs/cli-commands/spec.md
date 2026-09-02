# CLI Commands Specification

## Purpose
Defines the behaviour of all `nita-cmd_jenkins_*` shell scripts in `cli_scripts/`,
which wrap Jenkins operations and dispatch to either `kubectl` or `docker-compose`
depending on the available runtime.
## Requirements
### Requirement: Runtime dispatch — kubectl preferred over docker-compose
All CLI lifecycle commands SHALL prefer `kubectl` when it is available on `PATH`, falling back to `docker-compose`, and exiting with an error if neither is found.

#### Scenario: kubectl available
- GIVEN `kubectl` is on `PATH`
- WHEN a CLI command is invoked
- THEN it uses `kubectl` to perform the operation

#### Scenario: Only docker available
- GIVEN `kubectl` is not on `PATH` but `docker` is
- WHEN a CLI command is invoked
- THEN it uses `docker-compose` to perform the operation

#### Scenario: No runtime available
- GIVEN neither `kubectl` nor `docker` is on `PATH`
- WHEN a CLI command is invoked
- THEN it prints `Error: cannot find required binaries.` and exits non-zero

### Requirement: Container lifecycle — up
`nita-cmd_jenkins_up` SHALL start the Jenkins service (Kubernetes deployment or Docker Compose stack).

#### Scenario: Start with docker-compose
- GIVEN docker is available
- WHEN `nita-cmd_jenkins_up` is invoked
- THEN `docker-compose -p nitajenkins -f <docker-compose.yaml> up -d` is executed

### Requirement: Container lifecycle — down
`nita-cmd_jenkins_down` SHALL stop and remove the Jenkins service.

#### Scenario: Shutdown with docker-compose
- GIVEN the Jenkins compose stack is running
- WHEN `nita-cmd_jenkins_down` is invoked
- THEN the stack is stopped and containers are removed

### Requirement: Container lifecycle — start / stop / restart
`nita-cmd_jenkins_start`, `nita-cmd_jenkins_stop`, and `nita-cmd_jenkins_restart` SHALL start, stop, and restart the Jenkins container respectively without removing it.

#### Scenario: Stop does not destroy the container
- GIVEN the Jenkins container is running
- WHEN `nita-cmd_jenkins_stop` is invoked
- THEN the container is stopped but its named volume and data are retained

### Requirement: Job management — create
`nita-cmd_jenkins_jobs_create` SHALL accept a Jenkins job XML file name (without extension) and create the job via the Jenkins CLI.

#### Scenario: Job created from XML file
- GIVEN `myjob.xml` exists in the current directory
- WHEN `nita-cmd_jenkins_jobs_create myjob` is called
- THEN the job `myjob` is created in Jenkins via `create-job`

### Requirement: Job management — delete, enable, disable, list, get
`nita-cmd_jenkins_jobs_delete`, `nita-cmd_jenkins_jobs_enable`, `nita-cmd_jenkins_jobs_disable`, `nita-cmd_jenkins_jobs_ls`, and `nita-cmd_jenkins_jobs_get` SHALL perform the corresponding Jenkins CLI operations.

#### Scenario: List jobs returns job names
- GIVEN Jenkins is running with configured jobs
- WHEN `nita-cmd_jenkins_jobs_ls` is called
- THEN it outputs the names of all configured Jenkins jobs

### Requirement: Jenkins CLI access commands
`nita-cmd_jenkins_cli_jenkins` and `nita-cmd_jenkins_cli_root` SHALL open an interactive CLI session inside the container as the `jenkins` user or as `root` respectively.

#### Scenario: CLI opens as jenkins user
- GIVEN the Jenkins container is running
- WHEN `nita-cmd_jenkins_cli_jenkins` is called
- THEN an interactive shell session is opened inside the container as the `jenkins` user

### Requirement: Informational commands — ips, ports, labels, logs, status, volumes, version, whoami
Each informational CLI command SHALL query the running container and return the corresponding runtime detail.

#### Scenario: ports shows mapped port
- GIVEN the Jenkins container is running
- WHEN `nita-cmd_jenkins_ports` is invoked
- THEN it outputs the port mappings for the Jenkins container (e.g., `8443/tcp -> 0.0.0.0:8443`)

### Requirement: Plugin introspection commands
`nita-cmd_jenkins_plugins_ls` and `nita-cmd_jenkins_plugins_details` SHALL list installed plugins and show details of a specific plugin respectively.

#### Scenario: Plugin list returned
- GIVEN Jenkins is running with plugins installed
- WHEN `nita-cmd_jenkins_plugins_ls` is invoked
- THEN it outputs a list of installed Jenkins plugin names and versions

### Requirement: SSL verification toggle commands
`nita-cmd_jenkins_set_verify_ssl_true` and `nita-cmd_jenkins_set_verify_ssl_false` SHALL enable or disable SSL certificate verification for Jenkins CLI operations.

#### Scenario: SSL verification disabled for self-signed certificates
- GIVEN a self-signed certificate is in use
- WHEN `nita-cmd_jenkins_set_verify_ssl_false` is invoked
- THEN subsequent Jenkins CLI calls use `-noCertificateCheck`

### Requirement: Debug mode via _CLI_RUNNER_DEBUG
All CLI scripts SHALL honour the `_CLI_RUNNER_DEBUG` environment variable: when set, the resolved command SHALL be printed to stderr before execution.

#### Scenario: Debug output on stderr when flag set
- GIVEN `_CLI_RUNNER_DEBUG=1` is set
- WHEN `nita-cmd_jenkins_up` is called
- THEN the full shell command is printed to stderr before it is run

### Requirement: NITAJENKINSDIR override
All CLI scripts that reference installation paths SHALL honour the `NITAJENKINSDIR` environment variable as a path override, defaulting to `/etc/nita-jenkins` or `/opt/nita/k8s` when it is unset.

#### Scenario: Custom install directory used
- GIVEN `NITAJENKINSDIR=/home/jcluser/nita-jenkins`
- WHEN `nita-cmd_jenkins_up` is called
- THEN the command uses the docker-compose file from that directory

### Requirement: Help files co-located with commands
Each CLI command SHALL have a corresponding `*_help` file that documents its usage.

#### Scenario: Help file present for every command
- GIVEN the `cli_scripts/` directory is inspected
- WHEN its contents are listed
- THEN for every `nita-cmd_jenkins_<action>` file there is a `nita-cmd_jenkins_<action>_help` file

### Requirement: Jenkins CLI endpoint includes the /jenkins path prefix
Every CLI command that invokes `jenkins-cli.jar` (job management, plugin introspection, and informational commands) SHALL target the Jenkins server endpoint with the `/jenkins` path prefix.

#### Scenario: CLI jar targets the prefixed endpoint
- GIVEN a CLI command runs `jenkins-cli.jar -s` against the Jenkins server
- WHEN the endpoint URL is constructed
- THEN it includes the `/jenkins` path prefix (e.g. ends with `.../jenkins/`)

#### Scenario: No CLI command targets the bare root endpoint
- GIVEN the full set of `cli_scripts/*` commands
- WHEN their Jenkins endpoints are inspected
- THEN none targets the Jenkins server at the bare root path

