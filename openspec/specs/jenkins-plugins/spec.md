# Jenkins Plugins Specification

## Purpose
Defines the Jenkins plugin set required by nita-jenkins, how plugins are installed
at image build time, and the volume used to cache them.
## Requirements
### Requirement: Plugin list declared in version control
The system SHALL maintain `plugins.txt` with an explicit tested version for every required Jenkins plugin and install that exact set with `jenkins-plugin-cli` during the image build.

#### Scenario: Pinned plugins install at build time
- **WHEN** the Docker image is built from an unchanged `plugins.txt`
- **THEN** every named plugin is installed at its committed version without resolving an unpinned latest release

### Requirement: Robot Framework plugin installed
The system SHALL include the `robot` plugin to display Robot Framework test results in the Jenkins UI.

#### Scenario: Robot results visible in Jenkins job view
- GIVEN the `robot` plugin is installed
- WHEN a job produces Robot Framework output
- THEN Jenkins renders a test results graph and pass/fail summary on the job page

### Requirement: AnsiColor plugin installed
The system SHALL include the `ansicolor` plugin to render ANSI colour codes in console output.

#### Scenario: Coloured console output in pipeline logs
- GIVEN the `ansicolor` plugin is installed
- WHEN a pipeline step emits ANSI colour escape codes
- THEN the Jenkins console output renders colours instead of raw escape sequences

### Requirement: Plugin volume declared for caching
The system SHALL declare `/usr/share/jenkins/ref/plugins` as a Docker volume so plugin JPI files can be cached across container recreations.

#### Scenario: Plugin volume is mountable
- GIVEN a named volume is mounted at `/usr/share/jenkins/ref/plugins`
- WHEN the container is started
- THEN installed plugin JPI files persist on that volume

### Requirement: Matrix authorization plugin installed
The system SHALL include a pinned `matrix-auth` plugin because the startup security initializer configures a `GlobalMatrixAuthorizationStrategy` for the NITA administrator and internal job calls.

#### Scenario: Security initialization resolves matrix authorization
- **WHEN** Jenkins starts with a new empty home directory
- **THEN** the matrix authorization classes are available and the initializer installs the configured role permissions without a Groovy compilation error
