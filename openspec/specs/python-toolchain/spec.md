# Python Toolchain Specification

## Purpose
Defines the Python 3 packages installed into the nita-jenkins image, ensuring all
pipeline scripts and automation tools are available at runtime.
## Requirements
### Requirement: Python dependencies declared in requirements.txt
The system SHALL declare every direct Python dependency at an exact tested version in `requirements.txt`, install that set into `/opt/nita-venv` in a builder stage, verify it with `pip check`, and expose the copied virtual environment on runtime `PATH`.

#### Scenario: Locked Python environment is installed
- **WHEN** the Docker image is built from an unchanged `requirements.txt`
- **THEN** the same direct dependency versions are installed into `/opt/nita-venv` and `pip check` succeeds

#### Scenario: Helper uses the virtual environment
- **WHEN** a Jenkins job invokes a packaged Python helper
- **THEN** its interpreter and imports resolve from `/opt/nita-venv` without system-wide pip installation

### Requirement: Network automation libraries available
The system SHALL install `ansible`, `ncclient`, `junos-eznc`, `python-jenkins`, and `jenkinsapi` so Jenkins pipeline scripts can drive network device automation.

#### Scenario: Ansible playbook can be invoked from pipeline
- GIVEN the image is built with the Python toolchain installed
- WHEN a pipeline step calls `ansible-playbook`
- THEN Ansible is found on `PATH` and executes without missing-module errors

### Requirement: Cloud and OpenStack clients available
The system SHALL install `python-openstackclient`, `shade`, and `python-novaclient` to support OpenStack-based lab provisioning jobs.

#### Scenario: OpenStack CLI available in pipeline
- GIVEN the OpenStack clients are installed
- WHEN a pipeline step calls `openstack`
- THEN the command is found and can authenticate against an OpenStack endpoint

### Requirement: YAML and Jinja2 libraries available
The system SHALL install `PyYAML` and `Jinja2` so pipeline scripts can read/write YAML files and render templates.

#### Scenario: write_yaml_files.py runs without import errors
- GIVEN PyYAML is installed
- WHEN `write_yaml_files.py` is executed inside the container
- THEN `import yaml` and `import json` succeed without errors

### Requirement: Linting tools available
The system SHALL install `ansible-lint` and `pylint` so pipeline stages can perform static analysis.

#### Scenario: ansible-lint executable on PATH
- GIVEN `ansible-lint` is installed
- WHEN a pipeline step calls `ansible-lint`
- THEN the tool executes and returns a lint report
