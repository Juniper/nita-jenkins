## ADDED Requirements

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
