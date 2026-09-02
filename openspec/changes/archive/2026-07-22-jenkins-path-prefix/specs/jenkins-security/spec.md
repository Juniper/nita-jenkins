## ADDED Requirements

### Requirement: Jenkins root URL configured for reverse-proxy prefix
The `basic-security.groovy` init script SHALL set the Jenkins location root URL from the `JENKINS_URL` environment variable when it is present, so Jenkins advertises the correct external origin (including the `/jenkins/` prefix) while running behind a TLS-terminating reverse proxy.

#### Scenario: Root URL set from environment
- GIVEN the container starts with `JENKINS_URL=https://<host>/jenkins/`
- WHEN the init script runs
- THEN `JenkinsLocationConfiguration.get().getUrl()` returns `https://<host>/jenkins/`

#### Scenario: Root URL unset when variable absent
- GIVEN the container starts without `JENKINS_URL`
- WHEN the init script runs
- THEN the init script does not fail and leaves the Jenkins location URL at its existing value
