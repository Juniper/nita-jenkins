#!groovy

/* ********************************************************

Project: nita-jenkins

Copyright (c) Juniper Networks, Inc., 2021. All rights reserved.

Notice and Disclaimer: This code is licensed to you under the Apache 2.0 License (the "License"). You may not use this code except in compliance with the License. This code is not an official Juniper product. You can obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0.html

SPDX-License-Identifier: Apache-2.0

Third-Party Code: This code may depend on other components under separate copyright notice and license terms. Your use of the source code for those components is subject to the terms and conditions of the respective license as noted in the Third-Party source code file.

******************************************************** */

import hudson.security.*
import jenkins.model.*

def env = System.getenv()
def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
def users = hudsonRealm.getAllUsers()
users_s = users.collect { it.toString() }

// Create the admin user account if it doesn't already exist.
if ("{{ jenkins_admin_username }}" in users_s) {
    println "Admin user already exists - updating password"

    def user = hudson.model.User.get(env.JENKINS_USER);
    def password = hudson.security.HudsonPrivateSecurityRealm.Details.fromPlainPassword(env.JENKINS_PASS)
    user.addProperty(password)
    user.save()
}
else {
    println "--> creating local admin user"

    hudsonRealm.createAccount(env.JENKINS_USER, env.JENKINS_PASS)
    instance.setSecurityRealm(hudsonRealm)

    def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
    instance.setAuthorizationStrategy(strategy)
    instance.save()
}
