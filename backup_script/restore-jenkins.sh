#!/bin/bash
# ********************************************************
#
# Project: nita-jenkins
#
# Copyright (c) Juniper Networks, Inc., 2021. All rights reserved.
#
# Notice and Disclaimer: This code is licensed to you under the Apache 2.0 License (the "License"). You may not use this code except in compliance with the License. This code is not an official Juniper product. You can obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0.html
#
# SPDX-License-Identifier: Apache-2.0
#
# Third-Party Code: This code may depend on other components under separate copyright notice and license terms. Your use of the source code for those components is subject to the terms and conditions of the respective license as noted in the Third-Party source code file.
#
# ********************************************************
#
# README
#
# Following are the steps to restore a backup of Jenkins
# Enter the date of the backup (yyyy-mm-dd):
#
# Documentation
#  tar -xf archive.tar          # Create archive.tar from files foo and bar.
#  -C, --directory=DIR          # Change to directory DIR
#  --strip-components=NUMBER    # Remove any NUMBER of leading directories (e.g. /var/jenkins_home/)
#

if [ -z "$1" ]
  then
    echo "Please supply the backup archive to restore"
    exit 1
fi

# Colors
CBLACK='\033[0;30m'        # Black
CRED='\033[0;31m'          # Red
CGREEN='\033[0;32m'        # Green
CYELLOW='\033[0;33m'       # Yellow

# Variables
TAR_FILE="/var/jenkins_home/jenkins_backup.tar"
PLUGINS_TAR_FILE="/var/jenkins_home/jenkins_plugins_backup.tar"
CONTAINER_NAME="nitajenkins_jenkins_1"
CURRENT_DIR=`pwd`
NOW=`date +%F_%H-%M-%S`
TEMPORARY_FOLDER="/tmp/jenkins_restore_${NOW}/"

echo ""
echo -e "${CYELLOW} >>> Extracting backup archive.${NC}"
echo ""
mkdir -p ${TEMPORARY_FOLDER}
(
  cd ${TEMPORARY_FOLDER}
  tar -xzvf ${1}
)

if [ -d ${TEMPORARY_FOLDER} ]; then
  # Copying script
  echo ""
  echo -e "${CYELLOW} >>> Copying script to Jenkins container.${NC}"
  echo ""
  docker cp restore-jenkins-views.py ${CONTAINER_NAME}:/var/jenkins_home/

  # Copying restore files
  (
    cd ${TEMPORARY_FOLDER}
    echo ""
    echo -e "${CYELLOW} >>> Copying restore files (*.tar) to Jenkins container.${NC}"
    echo ""
    docker cp jenkins_backup.tar ${CONTAINER_NAME}:/var/jenkins_home/
    docker cp jenkins_plugins_backup.tar ${CONTAINER_NAME}:/var/jenkins_home
  )

  # Changing script ownership
  echo ""
  echo -e "${CYELLOW} >>> Changing script ownership (jenkins:jenkins)${NC}"
  echo ""
  docker exec -u root ${CONTAINER_NAME} chown jenkins:jenkins /var/jenkins_home/restore-jenkins-views.py

  # Restore configuration
  echo ""
  echo -e "${CYELLOW} >>> Restoring configuration${NC}"
  echo ""
  docker exec ${CONTAINER_NAME} tar -xf $TAR_FILE --directory /var/jenkins_home/ --strip-components=2
  status=$?
  echo ""
  if [ $status -eq 0 ]; then
    echo -e "${CYELLOW} >>> Restoring configuration was successful${NC}"
  else
    echo -e "${CRED} >>> Error restoring configuration${NC}\n"
    exit 2
  fi
  echo ""

  # Restore plugins
  echo ""
  echo -e "${CYELLOW} >>> Restoring plugins${NC}"
  echo ""
  docker exec ${CONTAINER_NAME} tar -xf $PLUGINS_TAR_FILE --directory /var/jenkins_home/ --strip-components=2
  status=$?
  echo ""
  if [ $status -eq 0 ]; then
    echo -e "${CYELLOW} >>> Restoring plugins was successful${NC}"
  else
    echo -e "${CRED} >>> Error restoring plugins${NC}\n"
    exit 2
  fi
  echo ""

  # Restore views
  echo ""
  echo -e "${CYELLOW} >>> Restoring views${NC}"
  echo ""
  docker exec ${CONTAINER_NAME} /var/jenkins_home/restore-jenkins-views.py

  # Clean environment
  echo ""
  echo -e "${CYELLOW} >>> Cleaning environment${NC}"
  echo ""
  rm -rf ${TEMPORARY_FOLDER}
  docker exec ${CONTAINER_NAME} rm -rf restore-jenkins-views.py
  docker exec ${CONTAINER_NAME} rm -rf $TAR_FILE
  docker exec ${CONTAINER_NAME} rm -rf $PLUGINS_TAR_FILE

  echo ""
  echo -e "${CYELLOW} >>> Restore completed!${NC}"
  echo ""

  echo ""
  echo -e "${CYELLOW} #############################${NC}"
  echo ""
  echo -e "${CRED} >>> Restarting Jenkins!${NC}"
  echo ""
  /usr/local/bin/nita_jenkins_restart
  echo ""
  echo -e "${CYELLOW} #############################${NC}"
  echo ""

else
  echo ""
  echo -e "${CYELLOW} >>> Could not restore from the archive provided${NC}"
  echo ""
fi
