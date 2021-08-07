#!/usr/bin/python3
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

import sys
import yaml
import json
from yaml import SafeDumper
import os
import stat

try:
    with open('data.json') as data_file:
        data = json.load(data_file)

    SafeDumper.add_representer(
        type(None),
        lambda dumper, value: dumper.represent_scalar(u'tag:yaml.org,2002:null', '')
    )

    for filename,conf in iter(data.items()):
        if ("group_vars/" in filename or "host_vars/" in filename) and (".yaml" in filename or ".yml" in filename):
            try:
                yaml_content = yaml.safe_dump(conf, default_flow_style=False, explicit_start = True)
                os.makedirs(os.path.dirname(filename), exist_ok=True)
                with open(filename, 'w') as outfile:
                    outfile.write(yaml_content)
                    os.chmod(filename, 0o775)
            except Exception as e:
                print(e)
                print("Yaml is not generated")
        else:
            print("Inavalid File Name Found =====> " + filename)

except Exception as e:
    print(e)
    print("************** No configuration data is received **************************")

