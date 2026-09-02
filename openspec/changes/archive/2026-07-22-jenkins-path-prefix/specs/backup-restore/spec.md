## ADDED Requirements

### Requirement: Backup and restore endpoints include the /jenkins path prefix
The backup and restore scripts SHALL target the Jenkins server endpoint with the `/jenkins` path prefix when listing plugins, invoking the CLI, or calling the Jenkins HTTP API.

#### Scenario: Backup plugin listing uses the prefixed endpoint
- GIVEN `backup-jenkins-in.sh` lists installed plugins via `jenkins-cli.jar`
- WHEN it constructs the Jenkins endpoint URL
- THEN the URL includes the `/jenkins` path prefix

#### Scenario: Restore views script uses the prefixed base URL
- GIVEN `restore-jenkins-views.py` calls the Jenkins HTTP API
- WHEN it constructs the base URL
- THEN the base URL includes the `/jenkins` path prefix
