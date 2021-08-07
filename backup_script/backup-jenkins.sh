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
# Following are the steps to run a backup of Jenkins
#
shopt -s extglob

if [ -z "$1" ]
  then
    echo "Please supply destination folder for the backup archive"
    exit 1
fi

# Colors
CBLACK='\033[0;30m'        # Black
CRED='\033[0;31m'          # Red
CGREEN='\033[0;32m'        # Green
CYELLOW='\033[0;33m'       # Yellow

# Variables
NOW=`date +%F_%H-%M-%S`
PLUGINS_TAR_FILE="jenkins_plugins_backup.tar"
PLUGINS_LIST_FILE="jenkins_plugins_backup.list"
LIST_FILE="jenkins_backup.list"
TAR_FILE="jenkins_backup.tar"
CONTAINER_NAME="nitajenkins_jenkins_1"
CURRENT_DIR=`pwd`
TEMPORARY_FOLDER="/tmp/jenkins_backup_${NOW}/"

echo ""
echo -e "${CYELLOW} >>> Creating backup${NC}"
echo ""
mkdir -p ${TEMPORARY_FOLDER}

echo -e "${CYELLOW} >>> Copying script inside Jenkins container.${NC}"
echo ""
docker cp backup-jenkins-in.sh ${CONTAINER_NAME}:/var/jenkins_home/

echo ""
echo -e "${CYELLOW} >>> Changing script ownership.${NC}"
echo ""
docker exec -u root ${CONTAINER_NAME} chown jenkins:jenkins /var/jenkins_home/backup-jenkins-in.sh

echo ""
echo -e "${CYELLOW} >>> Running script.${NC}"
echo ""
docker exec ${CONTAINER_NAME} /var/jenkins_home/backup-jenkins-in.sh

echo ""
echo -e "${CYELLOW} >>> Taking out from Jenkins container both *.tar files generated.${NC}"
echo ""
docker cp ${CONTAINER_NAME}:/var/jenkins_home/${LIST_FILE} ${TEMPORARY_FOLDER}
docker cp ${CONTAINER_NAME}:/var/jenkins_home/${TAR_FILE} ${TEMPORARY_FOLDER}
docker cp ${CONTAINER_NAME}:/var/jenkins_home/${PLUGINS_LIST_FILE} ${TEMPORARY_FOLDER}
docker cp ${CONTAINER_NAME}:/var/jenkins_home/${PLUGINS_TAR_FILE} ${TEMPORARY_FOLDER}

echo ""
echo -e "${CYELLOW} >>> Creating backup archive.${NC}"
echo ""
(
  cd ${TEMPORARY_FOLDER}
  tar -czvf jenkins_backup_${NOW}.tar.gz ${LIST_FILE} ${TAR_FILE} ${PLUGINS_LIST_FILE} ${PLUGINS_TAR_FILE}
  mv jenkins_backup_${NOW}.tar.gz ${1}
)

# Clean environment
echo ""
echo -e "${CYELLOW} >>> Cleaning environment.${NC}"
echo ""
rm -rf ${TEMPORARY_FOLDER}
docker exec ${CONTAINER_NAME} rm -rf /var/jenkins_home/backup-jenkins-in.sh
docker exec ${CONTAINER_NAME} rm -rf /var/jenkins_home/${TAR_FILE}
docker exec ${CONTAINER_NAME} rm -rf /var/jenkins_home/${LIST_FILE}
docker exec ${CONTAINER_NAME} rm -rf /var/jenkins_home/${PLUGINS_TAR_FILE}
docker exec ${CONTAINER_NAME} rm -rf /var/jenkins_home/${PLUGINS_LIST_FILE}
