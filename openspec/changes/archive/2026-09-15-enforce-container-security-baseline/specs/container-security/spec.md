## ADDED Requirements

### Requirement: Complete vulnerability evidence
The image workflow SHALL produce a downloadable HIGH/CRITICAL vulnerability report for every amd64 and arm64 build, and accepted findings SHALL remain visible in that report.

#### Scenario: Accepted finding remains visible
- **WHEN** a built image contains a CRITICAL finding covered by an active exception
- **THEN** the complete report records the suppressed finding while the blocking decision succeeds

#### Scenario: HIGH finding is report-only
- **WHEN** a built image contains a HIGH finding but no unaccepted CRITICAL finding
- **THEN** the workflow uploads the report and does not fail solely because of the HIGH finding

### Requirement: Unaccepted CRITICAL findings block delivery
The image workflow SHALL fail validation when either supported architecture contains a CRITICAL finding that is not covered by an active package-scoped exception.

#### Scenario: Pull request introduces an unaccepted CRITICAL finding
- **WHEN** an amd64 or arm64 validation image contains an unaccepted CRITICAL finding
- **THEN** that platform job fails and the image cannot satisfy the delivery checks

### Requirement: Governed vulnerability exceptions
Every vulnerability exception SHALL identify the CVE and affected package, state its trusted-lab applicability and reachability rationale, name the responsible owner and tracking issue, and expire no more than 90 days after acceptance.

#### Scenario: Exception expires
- **WHEN** the exception expiration date has passed
- **THEN** Trivy treats the finding as unaccepted and the CRITICAL gate fails
