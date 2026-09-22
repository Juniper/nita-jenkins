## MODIFIED Requirements

### Requirement: Python dependencies declared in requirements.txt
The system SHALL declare every direct Python dependency at an exact tested version in `requirements.txt`, install that set into `/opt/nita-venv` in a builder stage, verify it with `pip check`, and expose the copied virtual environment on runtime `PATH`.

#### Scenario: Locked Python environment is installed
- **WHEN** the Docker image is built from an unchanged `requirements.txt`
- **THEN** the same direct dependency versions are installed into `/opt/nita-venv` and `pip check` succeeds

#### Scenario: Helper uses the virtual environment
- **WHEN** a Jenkins job invokes a packaged Python helper
- **THEN** its interpreter and imports resolve from `/opt/nita-venv` without system-wide pip installation
