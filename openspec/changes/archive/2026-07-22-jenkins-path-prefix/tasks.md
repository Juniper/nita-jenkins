## 1. Serve Jenkins under the /jenkins prefix

- [x] 1.1 In `docker-compose.yaml`, add `--prefix=/jenkins` to the `JENKINS_OPTS` value
- [x] 1.2 In `docker-compose.yaml`, add a `JENKINS_URL` environment variable (external root URL, e.g. `https://<host>/jenkins/`)

## 2. Configure the Jenkins root URL

- [x] 2.1 In `basic-security.groovy`, import `jenkins.model.JenkinsLocationConfiguration`
- [x] 2.2 In `basic-security.groovy`, when `env.JENKINS_URL` is set, set `JenkinsLocationConfiguration.get().setUrl(env.JENKINS_URL)` and save it, before `instance.save()`

## 3. Update the health check

- [x] 3.1 In `Dockerfile`, change the HEALTHCHECK to probe the prefixed path (`/jenkins/login`) on the internal HTTP port

## 4. Update CLI scripts to the prefixed endpoint

- [x] 4.1 In every `cli_scripts/*` command that invokes `jenkins-cli.jar -s`, append `/jenkins` to the Jenkins endpoint URL
- [x] 4.2 Confirm no `cli_scripts/*` command still targets the bare root Jenkins endpoint

## 5. Update backup/restore scripts to the prefixed endpoint

- [x] 5.1 In `backup_script/backup-jenkins-in.sh`, append `/jenkins` to the Jenkins CLI endpoint URL
- [x] 5.2 In `backup_script/restore-jenkins-views.py`, append `/jenkins` to the Jenkins base URL
- [x] 5.3 Confirm no `backup_script/*` file still targets the bare root Jenkins endpoint

## 6. Verify correctness

- [x] 6.1 Grep this repo for `:8080`/`:8443` root-path Jenkins usage and confirm every caller now includes `/jenkins`
- [ ] 6.2 Build the image with `./build_container.sh` and confirm it succeeds
- [x] 6.3 Run the container and confirm `/jenkins/login` renders the Jenkins UI and the HEALTHCHECK passes

## 7. Cross-repo companion (nita-webapp)

The webapp-side work now lives in its own change: `nita-webapp` → `jenkins-path-prefix`
(capabilities `jenkins-reverse-proxy` + `jenkins-trigger-security`). Execute it there.

- [x] 7.1 Implement and apply the `nita-webapp` `jenkins-path-prefix` change (nginx pass-through, `JENKINS_SERVER_URL` += `/jenkins`, k8s plain-HTTP/drop `:8443`)
- [x] 7.2 Deploy this Jenkins image change and the `nita-webapp` change together, then verify the UI and job triggering/streaming end-to-end
