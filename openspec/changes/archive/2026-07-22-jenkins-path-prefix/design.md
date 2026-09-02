## Context

`nita-jenkins` ships a Jenkins image plus CLI wrappers, backup/restore scripts, and job
generators. In production it is deployed in Kubernetes alongside `nita-webapp`, which
fronts everything with an nginx reverse proxy that terminates a single TLS certificate.

Two facts from the current code drive this change:

1. **Jenkins serves from the server root.** `JENKINS_OPTS` sets `--httpPort=8080
   --httpsPort=8443` with no context path. Every Jenkins-generated URL is root-relative.
2. **The webapp already wants Jenkins at `/jenkins/`.** The nginx config proxies
   `location /jenkins/` to `http://jenkins:8080/` and then uses `sub_filter` to rewrite
   `href="/"`/`src="/"` to `/jenkins/` "on a best-effort basis" (its own comment). The
   frontend deep-links to `/jenkins/job/<name>/` already. The Django backend talks to
   Jenkins at `http://<host>:<port>` on the internal port 8080.

The `sub_filter` approach is inherently leaky — it cannot rewrite URLs built in
JavaScript, `action=` form targets, Ajax endpoints, or `Location:` redirect headers.

## Goals / Non-Goals

**Goals:**
- Jenkins serves its entire UI and API natively under the `/jenkins` context path
- Jenkins generates correct external self-URLs (`https://<host>/jenkins/...`) behind the proxy
- This repo's own callers (CLI scripts, backup scripts, healthcheck) target the prefixed path
- Enable the `nita-webapp` nginx config to proxy `/jenkins/` cleanly with no URL rewriting
- Consolidate on a single external entry point and TLS certificate (nginx), retiring the
  standalone `:8443` HTTPS listener in the unified deployment

**Non-Goals:**
- Changing Jenkins authentication or authorisation (the anonymous-internal-access model stays)
- Modifying the `nita-webapp` repo in this change (its nginx/backend edits are coordinated
  separately — captured here only so the cutover is understood)
- Introducing in-cluster mTLS or a service mesh

## Decisions

### Use Jenkins' native `--prefix` rather than proxy-side URL rewriting
**Decision:** Add `--prefix=/jenkins` to `JENKINS_OPTS`.

**Rationale:** `--prefix` is the Jenkins-supported way to run under a context path. Jenkins
then emits `/jenkins/...` URLs for every asset, form action, Ajax call, and redirect, so the
reverse proxy can pass traffic straight through. This deletes the fragile `sub_filter` block
in the webapp nginx config and removes an entire class of "some Jenkins page half-loads"
bugs. It also scopes the Jenkins `JSESSIONID` cookie to the `/jenkins` path, so it never
collides with the webapp session cookie at `/`.

**Alternatives considered:**
- *Strip the prefix at nginx and rewrite responses* (current approach) — leaky by nature;
  Jenkins docs explicitly recommend against it.
- *Host Jenkins on a separate subdomain* (`jenkins.<host>`) — needs a second cert and DNS
  entry; loses the single-origin cookie/SSO benefit the team wants.

### `--prefix` is global to the Jenkins process — unify internal and external paths
**Decision:** Both the external UI and the internal service port (8080, used by the webapp
backend) serve under `/jenkins`. Internal callers move to `http://jenkins:8080/jenkins`.

**Rationale:** `--prefix` applies to the whole Winstone/Jetty server, not per-listener, so a
split "root internally, `/jenkins` externally" model is not possible without the proxy hack
we are removing. Making every caller use `/jenkins` is simpler and consistent, and the base
URL change is trivial for both `python-jenkins` and `jenkins-cli.jar` (both just take a base
URL).

### Terminate TLS only at nginx; Jenkins serves plain HTTP behind it
**Decision:** In the unified (k8s) deployment, Jenkins serves plain HTTP on 8080 behind
nginx; the `:8443` listener and the JKS keystore are retired there. The image keeps HTTPS
capability so standalone `docker-compose` use is unaffected if a keystore is provided.

**Rationale:** The only untrusted hop is browser→nginx, which stays HTTPS. The nginx→Jenkins
hop is inside the cluster's private network, already fenced by the existing NetworkPolicy,
and the webapp backend already speaks plain HTTP to Jenkins on 8080. Dropping Jenkins-side
TLS removes the keystore file, the `nita123` keystore password embedded in `JENKINS_OPTS`,
the `-noCertificateCheck` flags in scripts, and cert-rotation overhead. In-cluster
encryption, if ever required, belongs to a service mesh, not per-application TLS.

### Configure the Jenkins root URL from a `JENKINS_URL` environment variable
**Decision:** `basic-security.groovy` sets `JenkinsLocationConfiguration.url` from a new
`JENKINS_URL` env var (e.g. `https://<host>/jenkins/`), defaulting to unset when absent.

**Rationale:** Behind a proxy that terminates TLS, Jenkins receives plain HTTP and would
otherwise advertise `http://jenkins:8080/...` in redirects, notification emails, and the
"Jenkins URL" field. Setting the root URL explicitly ensures generated links point at the
real external origin. nginx already forwards `X-Forwarded-Proto`, so scheme detection for
per-request URLs works; the location config covers the absolute-URL cases.

## Risks / Trade-offs

- **[Risk] Cross-repo cutover ordering** — if Jenkins gets `--prefix` before the webapp
  nginx/backend are updated (or vice-versa), `/jenkins/` returns 404 and the backend cannot
  reach jobs → Mitigated by shipping the Jenkins image change and the `nita-webapp` nginx +
  `JENKINS_SERVER_URL` change together, exactly as the archived `anonymous-internal-access`
  change coordinated its rollout.
- **[Risk] Missed hardcoded root-path callers** — any script still hitting `jenkins:8443/`
  (root) will break → Mitigated by auditing `cli_scripts/*` and `backup_script/*` in this
  change and grepping both repos for `:8080`/`:8443` root-path usage.
- **[Trade-off] Plain HTTP inside the cluster** — traffic between nginx and Jenkins is
  unencrypted → Accepted; standard for edge-terminated TLS and already true of the existing
  webapp→Jenkins calls; NetworkPolicy restricts who can reach port 8080.

## Migration Plan

1. Add `--prefix=/jenkins` to `JENKINS_OPTS` in `docker-compose.yaml`; add `JENKINS_URL`
2. Set the Jenkins root URL from `JENKINS_URL` in `basic-security.groovy`
3. Update the `Dockerfile` HEALTHCHECK to probe `/jenkins/login`
4. Append `/jenkins` to the Jenkins endpoint in every `cli_scripts/*` and `backup_script/*`
   caller
5. Rebuild the image (`./build_container.sh`)
6. **In `nita-webapp` (coordinated):** change nginx `proxy_pass` to
   `http://jenkins:8080/jenkins/` and delete the `sub_filter`/`proxy_redirect` lines;
   append `/jenkins` to `JENKINS_SERVER_URL`; drop the `:8443`/keystore exposure in the k8s
   manifests (plain HTTP behind nginx)
7. Deploy both together; verify `https://<host>/jenkins/login` renders fully and the webapp
   can trigger and stream jobs

**Rollback:** Revert `JENKINS_OPTS`/`JENKINS_URL`, scripts, and the webapp nginx/backend
changes together, and redeploy. No persistent Jenkins state changes.

## Open Questions

- None. `JENKINS_URL` is deployment-provided (not baked into the image): each environment
  supplies its own external origin via the `JENKINS_URL` environment variable, so no fixed
  host/scheme is hardcoded. The companion `nita-webapp` `jenkins-path-prefix` change owns the
  proxy and internal base-URL edits.
