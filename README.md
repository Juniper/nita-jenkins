[branch]: https://github.com/Juniper/nita/tree/23.12
[readme]: https://github.com/Juniper/nita/blob/23.12/README.md

# NITA Jenkins 23.12

Welcome to NITA, an open source platform for automating the building and testing of complex networks.

# Release Notes
The major change in this version is that all components now run within pods under the control of Kubernetes, rather than as Docker containers. Consequently we have updated the way that Ansible runs because it is now controlled by Kubernetes instead of Docker. 

Please refer to the [README][readme] for more details.

# Installing

The simplest way to install nita-jenkins is by installing nita, which can be done by running the ``install.sh`` script located and in the parent [nita repo][branch] as described [here][readme].

# Copyright

Copyright 2024, Juniper Networks, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
