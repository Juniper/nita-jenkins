## Why

The Jenkins image still uses a frozen Java 17 runtime, carries build-only packages, and reports container vulnerabilities without preventing an unreviewed CRITICAL finding from being delivered. The cross-repository NITA security baseline now needs a repository-local Jenkins contract that remains compatible with the recently introduced `/jenkins` context path.

## What Changes

- Move the image to a pinned Jenkins Java 21 LTS release and build Python dependencies in a separate stage.
- Pin the Jenkins plugins and direct Python dependencies used by NITA jobs.
- Minimize runtime packages while retaining the Git, SSH, Python, and job helpers required by the trusted-lab workflows.
- Pin and checksum the architecture-specific `kubectl` download.
- Produce complete HIGH/CRITICAL Trivy reports and block unaccepted CRITICAL findings before image publication.
- Preserve the `/jenkins` context path, health check, executable helper scripts, and existing NITA job behavior.

## Capabilities

### New Capabilities

- `container-security`: Defines vulnerability evidence, blocking behavior, and governed time-limited exceptions for the Jenkins image.

### Modified Capabilities

- `container-image`: Changes the supported Jenkins/JDK baseline, Python dependency installation, runtime package set, plugin inputs, and verified `kubectl` installation while retaining the prefixed health contract.
- `python-toolchain`: Installs pinned Python dependencies into a copied virtual environment instead of the system interpreter.
- `jenkins-plugins`: Requires explicit plugin versions so image rebuilds do not silently resolve a different plugin set.

## Impact

This change affects the Jenkins Dockerfile, plugin and Python dependency inputs, helper-script execution, and the multi-architecture image workflow. It changes no application API or NITA environment-variable interface. The cross-repository design authority remains the archived `enforce-container-security-baseline` change in `Juniper/nita` issue #75 and the corresponding `tbelz/nita` security branch.
