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

FROM jenkins/jenkins:lts-jdk11

ENV JAVA_OPTS='-Djenkins.install.runSetupWizard=false -Dhudson.model.DirectoryBrowserSupport.CSP=allow-same-origin'
ENV JENKINS_USER admin
ENV JENKINS_PASS admin

COPY requirements.txt /tmp/requirements.txt
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY basic-security.groovy /var/jenkins_home/init.groovy.d/
COPY write_yaml_files.py /usr/local/bin

RUN install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

USER root

RUN chown -R jenkins:jenkins /var/jenkins_home/init.groovy.d/
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yqq apt-utils git-core curl libssl-dev build-essential libssl-dev libffi-dev python3-dev python3-yaml python3-pip \
    sshpass apache2-suexec-custom wget vim && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/cache/apt/* && \
    rm -rf /var/lib/apt/lists/*

RUN ( curl https://get.docker.com | sh ) && \
    pip3 install -r /tmp/requirements.txt && \
    rm -rf /tmp/requirements.txt && \
    usermod -aG docker jenkins

RUN touch /var/run/docker.sock && chmod 777 /var/run/docker.sock

USER jenkins

VOLUME /usr/share/jenkins/ref/plugins
VOLUME /var/jenkins_home

HEALTHCHECK --interval=1m --timeout=3s CMD curl -k -s -w "%{http_code}" https://localhost:8443 -o /dev/null || exit 1

LABEL net.juniper.framework="NITA"
