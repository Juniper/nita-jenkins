## 1. Init script

- [x] 1.1 Remove the `Item.BUILD` and `Item.CANCEL` grants for `anonymous` from `basic-security.groovy`; keep `Item.READ`
- [x] 1.2 Replace `instance.setCrumbIssuer(null)` with `new DefaultCrumbIssuer(true)` and import `hudson.security.csrf.DefaultCrumbIssuer`
- [x] 1.3 Update the comment block to state the new posture (anonymous read-only; CSRF on, client IP excluded for proxy compatibility)
- [x] 1.4 Replace `HudsonPrivateSecurityRealm` with `ReverseProxySecurityRealm` (header mode, `X-Forwarded-User` / `X-Forwarded-Groups`); add `reverse-proxy-auth-plugin` to `plugins.txt`
- [x] 1.5 `ProjectMatrixAuthorizationStrategy`: service identity and group `admin` → Administer; group `power_user` → Overall/Read, Job/Read, Job/Build, Job/Cancel; group `authenticated` → Overall/Read only; anonymous → nothing. Per-job grants (owner, `team-<id>`) are written by the webapp
- [x] 1.6 Dockerfile seeds the init script as `/usr/share/jenkins/ref/init.groovy.d/basic-security.groovy.override` so existing homes re-copy it on every start
- [x] 1.7 `nita-cmd jenkins version` / `jobs ls` use the REST API with `X-Forwarded-User` (password CLI auth no longer exists)

## 2. Documentation

- [x] 2.1 Add a release note to `README.md`: anonymous build/cancel removed, CSRF protection enabled, what this means for operators who used *Build Now* without logging in

## 3. Verification

- [x] 3.1 Build the image and start it with an empty `jenkins_home`; confirm the init script logs no Groovy errors
- [x] 3.2 `curl -X POST http://localhost:8080/jenkins/job/<job>/build` with no credentials → 403
- [x] 3.3 `curl -u $JENKINS_USER:$JENKINS_PASS http://localhost:8080/jenkins/crumbIssuer/api/json` → 200 with a crumb
- [x] 3.4 `curl http://localhost:8080/jenkins/job/<job>/api/json` with no credentials → 200 (anonymous read retained)
- [ ] 3.5 With the webapp compose stack: entrypoint bootstrap (`configure_jenkins.py`, `add_jenkins_job.py`) succeeds; `POST /api/v1/networks/{id}/trigger/{action_id}/` → 202 and the build runs; SSE console streams; Robot summary renders
- [x] 3.6 Restart a container with a pre-existing `jenkins_home` and confirm the strategy and issuer converge to the new values
- [x] 3.8 Live on Kubernetes: `whoAmI` reflects `X-Forwarded-User`/`X-Forwarded-Groups`; forwarded user's build records `UserIdCause`; role `user` cannot reach `/manage/`; `admin:admin` Basic auth → 401
- [x] 3.9 Live on Kubernetes (project matrix): role `user` sees only own/team jobs (others 404), team member read-only (build 403), owner build 201, power user/admin see all, anonymous root 403, management jobs 404 for role `user`
- [x] 3.7 `openspec validate revoke-anonymous-build-and-enable-csrf --strict` passes
