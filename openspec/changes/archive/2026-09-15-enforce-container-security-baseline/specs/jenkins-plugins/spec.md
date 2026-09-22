## MODIFIED Requirements

### Requirement: Plugin list declared in version control
The system SHALL maintain `plugins.txt` with an explicit tested version for every required Jenkins plugin and install that exact set with `jenkins-plugin-cli` during the image build.

#### Scenario: Pinned plugins install at build time
- **WHEN** the Docker image is built from an unchanged `plugins.txt`
- **THEN** every named plugin is installed at its committed version without resolving an unpinned latest release

## ADDED Requirements

### Requirement: Matrix authorization plugin installed
The system SHALL include a pinned `matrix-auth` plugin because the startup security initializer configures a `GlobalMatrixAuthorizationStrategy` for the NITA administrator and internal job calls.

#### Scenario: Security initialization resolves matrix authorization
- **WHEN** Jenkins starts with a new empty home directory
- **THEN** the matrix authorization classes are available and the initializer installs the configured role permissions without a Groovy compilation error
