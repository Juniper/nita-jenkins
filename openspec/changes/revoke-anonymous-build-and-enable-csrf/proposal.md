## Why

`basic-security.groovy` grants the `anonymous` principal `Job/Build`,
`Job/Read` and `Job/Cancel`, and disables the CSRF crumb issuer. Both were
introduced so the webapp could trigger jobs without credentials. The webapp no
longer does that: every Django→Jenkins call authenticates with
`JENKINS_SERVER_USER`/`JENKINS_SERVER_PASS` and obtains a crumb before building
(`nita-webapp` capability `jenkins-trigger-security`), and the one remaining
unauthenticated call — the console stream — is fixed in the companion
`nita-webapp/gate-jenkins-behind-webapp-session` change.

What remains is pure exposure. Jenkins is reverse-proxied at `/jenkins/` and,
in the Kubernetes deployment, also published directly on host port 8443. With
the current grants, anyone who can open a TCP connection to either can start or
abort any build with a single unauthenticated `POST`, and no CSRF protection
stands between a logged-in operator's browser and a cross-site request that does
the same.

## What Changes

- **Identity comes from the proxy.** The private user database is replaced by
  the Reverse Proxy Auth realm in header mode: `X-Forwarded-User` is the user,
  `X-Forwarded-Groups` carries the webapp role and one `team-<id>` group per
  team. No passwords live in Jenkins; Basic auth only works with an API token.
- **Authorisation mirrors the webapp.** A project-based matrix grants `admin`
  Administer, `power_user` read/build/cancel on every job and `authenticated`
  Overall/Read only; each per-network job carries its own matrix (owner
  read/build/cancel, team read) written by the webapp. Anonymous has no access;
  management jobs are reachable only by admins/power users.
- **CSRF protection is enabled.** The init script installs a
  `DefaultCrumbIssuer` with `excludeClientIPFromCrumb=true` so crumbs remain
  valid across the reverse proxy hop. Build requests must carry a crumb — which
  the webapp already does via `CrumbRequester`, and the bootstrap scripts
  already fetch one when an issuer is present.
- **Specification is corrected.** The `jenkins-security` capability currently
  *requires* the anonymous grants and *requires* CSRF to be disabled. Those
  requirements are replaced.

Jenkins is only reachable through the webapp-gated proxy and from the webapp
pod (NetworkPolicy), which is the trust precondition of header-based identity.

## Capabilities

### Modified Capabilities

- `jenkins-security`: header-based security realm; project-based matrix that
  mirrors webapp roles, ownership and teams; anonymous has no access; the CSRF
  crumb issuer is enabled and configured for operation behind a reverse proxy.

## Impact

- **Files:** `basic-security.groovy` (two permission lines removed, crumb
  issuer replaced), `openspec/specs/jenkins-security/spec.md` (via archive),
  `README.md` release notes.
- **Image:** no new plugins; `matrix-auth` is already pinned. No change to
  `plugins.txt`, `Dockerfile`, or ports.
- **Clients that must already be compliant (verified):** the webapp's
  `invoke_job` (authenticated + crumb), `ping_jenkins.py` /
  `configure_jenkins.py` / `add_jenkins_job.py` (authenticated, crumb-aware
  with a cookie jar), the in-job `jenkins-cli.jar` calls in
  `network_template_mgr` (authenticated via `-s http://user:pass@…`), and the
  `nita-cmd jenkins …` scripts (authenticated via `-s https://user:pass@…`).
  `jenkins-cli.jar` does not use crumbs.
- **Behavioural change for humans:** a user who can reach the Jenkins UI but is
  not logged into Jenkins can browse jobs and read logs but can no longer press
  *Build Now* or abort a build. In NITA those operations are performed through
  the webapp.
- **Ordering:** deploy this Jenkins hardening first, then
  `nita/close-jenkins-direct-exposure`, then
  `nita-webapp/gate-jenkins-behind-webapp-session`. Existing webapp build
  requests are already authenticated and crumbed, and the console stream relies
  only on anonymous `Job/Read`, which this change keeps. This sequence removes
  anonymous mutation permissions first, closes the direct host-port route
  second, and enables the proxy session gate only after proxy connectivity is
  confirmed.
