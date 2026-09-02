## MODIFIED Requirements

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
