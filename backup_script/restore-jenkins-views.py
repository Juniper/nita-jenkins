#!/usr/bin/env python3
""" ********************************************************

Project: nita-jenkins

Copyright (c) Juniper Networks, Inc., 2020. All rights reserved.

Notice and Disclaimer: This code is licensed to you under the Apache 2.0 License (the "License"). You may not use this code except in compliance with the License. This code is not an official Juniper product. You can obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0.html

SPDX-License-Identifier: Apache-2.0

Third-Party Code: This code may depend on other components under separate copyright notice and license terms. Your use of the source code for those components is subject to the terms and conditions of the respective license as noted in the Third-Party source code file.

******************************************************** """
import xml.etree.ElementTree as ET
import os

URL = 'https://127.0.0.1:8443/'
#URL = 'http://127.0.0.1:8080/'
JENKINS_CONFIG_XML = '/var/jenkins_home/config.xml'

config = ET.parse(JENKINS_CONFIG_XML).getroot()

views = config.find('views')
listViews = views.findall('listView')

for lv in listViews:
    #print(ET.tostring(lv, encoding='utf8').decode('utf8'))
    #print(lv.get('name'))
    for elem in lv.iter():
        if elem.tag == 'name':
            view = elem.text
        if elem.tag == 'jobNames':
            # print('View: ', view)
            # [print('Job: ', job.text) for job in elem.findall('string')]
            for job in elem.findall('string'):
                # Jenkins CLI Command >>>> java -jar jenkins-cli.jar -s $JENKINS_URL add-job-to-view $VIEW $JOB
                command = 'java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s ' + URL + ' add-job-to-view ' + view + ' ' + job.text + ' > /dev/null 2>&1'
                # print(" >>>> command: " + command)
                os.system(command)
