#!/bin/bash
# ********************************************************
#
# Project: nita-jenkins
# Version: 20.10
#
# Copyright (c) Juniper Networks, Inc., 2020. All rights reserved.
#
# Notice and Disclaimer: This code is licensed to you under the Apache 2.0 License (the "License"). You may not use this code except in compliance with the License. This code is not an official Juniper product. You can obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0.html
#
# SPDX-License-Identifier: Apache-2.0
#
# Third-Party Code: This code may depend on other components under separate copyright notice and license terms. Your use of the source code for those components is subject to the terms and conditions of the respective license as noted in the Third-Party source code file.
#
# ********************************************************
#
# Documentation
#  tar -cf archive.tar foo bar  # Create archive.tar from files foo and bar.
#  --absolute-names             # Do nott strip leading '/'s from file names
#  --preserve-permissions       # Extract information about file permissions
#  -r, --append                 # Append files to the end of an archive

# VARIABLES
######################

TODAY=`date +%F`
TAR_FILE="/var/jenkins_home/jenkins_backup.tar"
PLUGINS_TAR_FILE="/var/jenkins_home/jenkins_plugins_backup.tar"
LOG_FILE="/var/jenkins_home/jenkins_backup.log"
LIST_FILE="/var/jenkins_home/jenkins_backup.list"
PLUGINS_LOG_FILE="/var/jenkins_home/jenkins_plugins_backup.log"
PLUGINS_LIST_FILE="/var/jenkins_home/jenkins_plugins_backup.list"

# Settings
find /var/jenkins_home/ -maxdepth 1 -name '*.xml' > $LOG_FILE
# Jobs
find /var/jenkins_home/jobs/ -maxdepth 2 -name '*.xml' >> $LOG_FILE
# Nodes
find /var/jenkins_home/nodes/ -maxdepth 1 >> $LOG_FILE
# Plugins
/usr/local/openjdk-8/bin/java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -noCertificateCheck -s https://admin:admin@jenkins:8443/ list-plugins | awk '{print $1":"$NF}' | sort > $PLUGINS_LIST_FILE
find /var/jenkins_home/plugins/ -maxdepth 1 -name '*.jpi' > $PLUGINS_LOG_FILE
# Secrets
find /var/jenkins_home/secrets/ -maxdepth 1 -name '*.xml' >> $LOG_FILE
# Users
find /var/jenkins_home/users/ -maxdepth 2 -name '*.xml' >> $LOG_FILE

# Sort list of backup files
sort -o $LIST_FILE $LOG_FILE
rm -f $LOG_FILE

# Append files to tar file
for file in `cat $LIST_FILE`; do tar --absolute-names --preserve-permissions -rf $TAR_FILE $file ; done
# Append list file to tar file as well
tar --absolute-names --preserve-permissions -rf $TAR_FILE $LIST_FILE
tar --absolute-names --preserve-permissions -rf $TAR_FILE $PLUGINS_LIST_FILE

# Append plugin files to plugin tar file
for plugin in `cat $PLUGINS_LOG_FILE`; do tar --absolute-names --preserve-permissions -rf $PLUGINS_TAR_FILE $plugin ; done
# Append list file to tar file as well
tar --absolute-names --preserve-permissions -rf $PLUGINS_TAR_FILE $PLUGINS_LIST_FILE
