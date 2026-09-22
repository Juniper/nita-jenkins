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

FROM jenkins/jenkins:2.568.2-jdk21 AS python-builder

USER root
RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential libffi-dev libssl-dev python3-dev python3-venv \
 && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN python3 -m venv /opt/nita-venv \
 && /opt/nita-venv/bin/pip install --no-cache-dir --upgrade pip \
 && /opt/nita-venv/bin/pip install --no-cache-dir -r /tmp/requirements.txt \
 && /opt/nita-venv/bin/pip check

FROM jenkins/jenkins:2.568.2-jdk21

ARG TARGETARCH
ARG KUBECTL_VERSION=v1.36.3
ARG KUBECTL_SHA256_AMD64=ebbd080e7c2e275093b55915722043257eb24004363e20acb3c4d71919f88336
ARG KUBECTL_SHA256_ARM64=3d86f24401c41ae5a46ac50eef8865fe891d3647d324a0836f6c63757a126e62

ENV JAVA_OPTS='-Djenkins.install.runSetupWizard=false -Dhudson.model.DirectoryBrowserSupport.CSP=allow-same-origin'
ENV JENKINS_USER=admin
ENV JENKINS_PASS=admin
ENV PATH="/opt/nita-venv/bin:$PATH"

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY basic-security.groovy /var/jenkins_home/init.groovy.d/
COPY write_yaml_files.py robot.py create_ansible_job_k8s.py /usr/local/bin/
COPY --from=python-builder /opt/nita-venv /opt/nita-venv

RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

USER root

RUN chmod 755 /usr/local/bin/write_yaml_files.py \
              /usr/local/bin/robot.py \
              /usr/local/bin/create_ansible_job_k8s.py \
 && chown -R jenkins:jenkins /var/jenkins_home/init.groovy.d/ \
 && apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
 && DEBIAN_FRONTEND=noninteractive apt-get purge -y git-lfs \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      apache2-suexec-custom ca-certificates curl git openssh-client python3 sshpass \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -f /usr/local/bin/git-lfs \
 && rm -rf /var/lib/apt/lists/*

RUN case "${TARGETARCH}" in \
      amd64) kubectl_sha256="${KUBECTL_SHA256_AMD64}" ;; \
      arm64) kubectl_sha256="${KUBECTL_SHA256_ARM64}" ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
 && curl --fail --location --silent --show-error \
      --output /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
 && echo "${kubectl_sha256}  /usr/local/bin/kubectl" | sha256sum --check --strict \
 && chmod 755 /usr/local/bin/kubectl

USER jenkins

VOLUME /usr/share/jenkins/ref/plugins
VOLUME /var/jenkins_home

HEALTHCHECK --interval=1m --timeout=3s CMD curl --fail --silent --show-error http://localhost:8080/jenkins/login -o /dev/null || exit 1

LABEL net.juniper.framework="NITA"
LABEL org.opencontainers.image.source="https://github.com/Juniper/nita-jenkins"
