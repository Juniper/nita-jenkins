# Backup and Restore Specification

## Purpose
Defines how Jenkins configuration, jobs, plugins, users, and secrets are backed up
to tar archives and restored from them using scripts in `backup_script/`.
## Requirements
### Requirement: Backup destination directory required
The system SHALL require a destination directory path as the first argument to `backup-jenkins.sh` and exit non-zero if it is absent.

#### Scenario: Missing destination argument
- GIVEN `backup-jenkins.sh` is called with no arguments
- WHEN the script runs
- THEN it prints an error and exits with a non-zero status

### Requirement: Backup script copied and executed inside the container
The system SHALL copy `backup-jenkins-in.sh` into the Jenkins container, set ownership to `jenkins:jenkins`, and execute it as the `jenkins` user.

#### Scenario: In-container backup script runs with correct permissions
- GIVEN `backup-jenkins.sh` is called with a destination path
- WHEN the script runs
- THEN `backup-jenkins-in.sh` is copied to `/var/jenkins_home/` and executed inside the container

### Requirement: Configuration, jobs, nodes, secrets, and users backed up
The system SHALL back up Jenkins XML configuration files at `/var/jenkins_home/*.xml`, job definitions at `/var/jenkins_home/jobs/**/*.xml`, nodes, secrets, and user records into a tar archive.

#### Scenario: Backup archive contains Jenkins configuration
- GIVEN the backup completes successfully
- WHEN the archive is inspected
- THEN it contains Jenkins global config, all job XML files, and user account data

### Requirement: Plugin list and plugin JPI files backed up separately
The system SHALL produce a separate plugin tar archive containing all installed `.jpi` files and a text list of installed plugin versions.

#### Scenario: Plugin backup archive produced
- GIVEN the backup completes successfully
- WHEN the archive directory is inspected
- THEN a `jenkins_plugins_backup.tar` archive exists containing all `.jpi` files

### Requirement: Backup archives transferred to host destination directory
The system SHALL copy both archives from the container to the host path supplied as the first argument.

#### Scenario: Archives available on host after backup
- GIVEN the backup script completes
- WHEN the destination directory is inspected
- THEN `jenkins_backup.tar` and `jenkins_plugins_backup.tar` are present

### Requirement: Restore archive path required
The system SHALL require the path to a backup archive as the first argument to `restore-jenkins.sh` and exit non-zero if it is absent.

#### Scenario: Missing archive argument
- GIVEN `restore-jenkins.sh` is called with no arguments
- WHEN the script runs
- THEN it prints an error and exits with a non-zero status

### Requirement: Archive extracted and restored into container
The system SHALL extract the supplied archive to a temporary directory and then copy the contents back into the Jenkins container, preserving permissions.

#### Scenario: Jenkins configuration restored from archive
- GIVEN `restore-jenkins.sh` is called with a valid backup archive path
- WHEN the script runs
- THEN Jenkins XML files and plugin archives are restored to `/var/jenkins_home/` inside the container

### Requirement: CLI backup command delegates to backup script
The `nita-cmd_jenkins_backup` CLI script SHALL resolve the backup script directory from `NITAJENKINSDIR` (defaulting to `/etc/nita-jenkins/backup`) and invoke `backup-jenkins.sh` with the supplied argument.

#### Scenario: CLI backup command invokes backup-jenkins.sh
- GIVEN `nita-cmd_jenkins_backup /tmp/backup-output` is called
- WHEN the script runs
- THEN `backup-jenkins.sh /tmp/backup-output` is executed from the correct directory

### Requirement: CLI restore command resolves absolute path before delegating
The `nita-cmd_jenkins_restore` CLI script SHALL resolve the supplied archive path to an absolute path before invoking `restore-jenkins.sh`.

#### Scenario: Relative archive path resolved correctly
- GIVEN `nita-cmd_jenkins_restore ../backup.tar` is called from a subdirectory
- WHEN the script runs
- THEN `restore-jenkins.sh` receives the absolute path to `backup.tar`

### Requirement: Backup and restore endpoints include the /jenkins path prefix
The backup and restore scripts SHALL target the Jenkins server endpoint with the `/jenkins` path prefix when listing plugins, invoking the CLI, or calling the Jenkins HTTP API.

#### Scenario: Backup plugin listing uses the prefixed endpoint
- GIVEN `backup-jenkins-in.sh` lists installed plugins via `jenkins-cli.jar`
- WHEN it constructs the Jenkins endpoint URL
- THEN the URL includes the `/jenkins` path prefix

#### Scenario: Restore views script uses the prefixed base URL
- GIVEN `restore-jenkins-views.py` calls the Jenkins HTTP API
- WHEN it constructs the base URL
- THEN the base URL includes the `/jenkins` path prefix

