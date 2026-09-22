## MODIFIED Requirements

### Requirement: Base image
The system SHALL use the pinned `jenkins/jenkins:2.568.2-jdk21` image as both the Python builder base and final Jenkins runtime base.

#### Scenario: Image uses the tested Java 21 LTS release
- **WHEN** the nita-jenkins Dockerfile is built
- **THEN** both stages derive from `jenkins/jenkins:2.568.2-jdk21`

### Requirement: Architecture-aware kubectl installation
The system SHALL install a pinned `kubectl` release selected with BuildKit `TARGETARCH`, verify it using the committed checksum for `amd64` or `arm64`, and reject unsupported architectures.

#### Scenario: Verified amd64 kubectl
- **WHEN** `TARGETARCH` is `amd64`
- **THEN** the amd64 binary is installed at `/usr/local/bin/kubectl` only after its SHA-256 checksum succeeds

#### Scenario: Verified arm64 kubectl
- **WHEN** `TARGETARCH` is `arm64`
- **THEN** the arm64 binary is installed at `/usr/local/bin/kubectl` only after its SHA-256 checksum succeeds

#### Scenario: Unsupported kubectl architecture
- **WHEN** `TARGETARCH` is neither `amd64` nor `arm64`
- **THEN** the image build fails without installing an unverified binary

### Requirement: System packages installed
The final image SHALL contain only the operating-system packages required by NITA Jenkins jobs: `apache2-suexec-custom`, `ca-certificates`, `curl`, `git`, `openssh-client`, `python3`, and `sshpass`; compiler, development-header, editor, wget, and Git LFS packages SHALL NOT remain in the runtime.

#### Scenario: Required runtime tools are available
- **WHEN** a Jenkins job runs in the final image
- **THEN** Git, curl, Python, SSH, and sshpass are available on `PATH`

#### Scenario: Build-only tools are excluded
- **WHEN** the final runtime filesystem is inspected
- **THEN** the Python compiler toolchain and Git LFS executable are absent
