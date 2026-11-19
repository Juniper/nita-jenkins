#!groovy

/* ********************************************************

Project: nita-jenkins

Copyright (c) Juniper Networks, Inc., 2021. All rights reserved.

Notice and Disclaimer: This code is licensed to you under the Apache 2.0 License (the "License"). You may not use this code except in compliance with the License. This code is not an official Juniper product. You can obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0.html

SPDX-License-Identifier: Apache-2.0

Third-Party Code: This code may depend on other components under separate copyright notice and license terms. Your use of the source code for those components is subject to the terms and conditions of the respective license as noted in the Third-Party source code file.

******************************************************** */

import hudson.security.*
import hudson.security.csrf.DefaultCrumbIssuer
import jenkins.model.*
import jenkins.model.JenkinsLocationConfiguration
import org.jenkinsci.plugins.matrixauth.PermissionEntry
import org.jenkinsci.plugins.reverse_proxy_auth.ReverseProxySecurityRealm

def env = System.getenv()
def instance = Jenkins.getInstance()
def serviceUser = env.JENKINS_USER ?: 'admin'

// Identity is asserted by the NITA proxy/webapp through X-Forwarded-User /
// X-Forwarded-Groups (the webapp role plus one team-<id> group per team).
// Jenkins holds no local passwords; Basic auth is only honoured with an API token.
println "--> configuring header-based (reverse proxy) security realm"
instance.setSecurityRealm(new ReverseProxySecurityRealm(
    'X-Forwarded-User', null, null, 'X-Forwarded-Groups', '|', null, null,
    null, null, false, null, null, null, null, null, null, null, null, null,
    false, null, null))

// Project-based matrix mirroring the webapp model. Globally:
//   - the service identity (JENKINS_USER) and webapp admins administer
//   - power users may read/build/cancel every job
//   - every other authenticated user only gets Overall/Read; per-network jobs
//     grant their owner (read/build/cancel) and team (read) individually
//   - anonymous gets nothing (Jenkins is only reachable through the gated proxy)
// Management jobs carry no per-job grants, so only admins/power users can drive them.
def strategy = new ProjectMatrixAuthorizationStrategy()
strategy.add(Jenkins.ADMINISTER, PermissionEntry.user(serviceUser))
strategy.add(Jenkins.ADMINISTER, PermissionEntry.group('admin'))
[Jenkins.READ, hudson.model.Item.READ, hudson.model.Item.BUILD, hudson.model.Item.CANCEL].each {
    strategy.add(it, PermissionEntry.group('power_user'))
}
strategy.add(Jenkins.READ, PermissionEntry.group('authenticated'))
instance.setAuthorizationStrategy(strategy)

// Keep CSRF protection enabled; exclude client IP so crumbs work behind proxies.
instance.setCrumbIssuer(new DefaultCrumbIssuer(true))

// Configure the external root URL so Jenkins advertises correct self-URLs
// (including the /jenkins prefix) when running behind a TLS-terminating proxy.
if (env.JENKINS_URL) {
    def locationConfig = JenkinsLocationConfiguration.get()
    locationConfig.setUrl(env.JENKINS_URL)
    locationConfig.save()
}

instance.save()
