## Context

NITA publishes the Jenkins image for amd64 and arm64 and uses it in a trusted, single-operator lab. The existing multi-architecture workflow reports vulnerabilities but does not block delivery, while the current image contract still requires JDK 17, system-wide Python packages, and build tools in the runtime. A central cross-repository design is archived on the `tbelz/nita` `codex/container-security-baseline` branch under `openspec/changes/archive/2026-08-05-enforce-container-security-baseline`.

Since that design was prepared, Jenkins gained a `/jenkins` context path and an executable-bit fix for all three helper scripts. This component change must preserve those contracts while applying the security baseline.

## Goals / Non-Goals

**Goals:**

- Use a pinned, supported Jenkins Java 21 LTS image.
- Keep compilers and Python headers out of the runtime image.
- Make plugin, Python, and `kubectl` inputs reproducible.
- Block unaccepted CRITICAL image findings while retaining complete reports.
- Preserve existing job behavior, `/jenkins` routing, and executable helpers on amd64 and arm64.

**Non-Goals:**

- Harden NITA for public or multi-tenant deployment.
- Change Jenkins authentication, Kubernetes RBAC, job APIs, or image environment variables.
- Make HIGH findings blocking in this first baseline.

## Decisions

- Build Python dependencies in a dedicated stage and copy the virtual environment into the final Jenkins image. This retains the required Python commands without shipping compilers and development headers.
- Pin the Jenkins image, direct Python requirements, plugin versions, and `kubectl` version/checksums. Mutable LTS and stable-download resolution were rejected because identical source revisions could otherwise produce different images.
- Retain only the runtime packages exercised by NITA jobs: CA certificates, curl, Git, OpenSSH client, Python, sshpass, and Apache suexec. Git LFS and editor/build packages are removed.
- Use BuildKit `TARGETARCH` to select a checksum-verified `kubectl` binary for amd64 or arm64.
- Run Trivy twice against each exact image: a non-blocking HIGH/CRITICAL JSON report with accepted findings visible, followed by a blocking CRITICAL scan using package-scoped, expiring exceptions.
- Preserve the upstream internal health probe at `/jenkins/login` and the executable mode of all helper scripts when resolving the historical Dockerfile branch conflict.

## Risks / Trade-offs

- A Java 21 or plugin incompatibility could affect startup or persisted Jenkins state. → Run plugin, Java, HTTP-prefix, and NITA Kind integration checks before upstream review.
- Removing packages could break an infrequently used job. → Retain tools referenced by repository scripts and smoke-test the documented Python, Git, SSH, and job-helper paths.
- Debian findings without an available fix may remain. → Permit only documented package-scoped exceptions that remain visible and expire on the original November 3, 2026 date.
- Scanner results can change without source changes. → Rebuild and scan both architectures on the rebased head and block any newly unaccepted CRITICAL finding.

## Migration Plan

Rebase onto current upstream `main`, validate in the personal fork without publishing, then open a normal Juniper pull request. If runtime or integration validation fails, retain the existing upstream image and do not merge the security branch.

## Open Questions

None.
