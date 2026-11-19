[branch]: https://github.com/Juniper/nita/tree/26.10
[readme]: https://github.com/Juniper/nita/blob/26.10/README.md

# NITA Jenkins 26.10

Welcome to NITA, an open source platform for automating the building and testing of complex networks.

# Release Notes

Jenkins no longer keeps its own user database. Identity comes from the NITA
proxy/webapp through the `X-Forwarded-User` and `X-Forwarded-Groups` headers
(Reverse Proxy Auth plugin): signing in to the webapp signs you in to Jenkins
and builds started from the webapp are attributed to the real user. Access
mirrors the webapp: admins (group `admin`) administer Jenkins, power users can
read/build/cancel every job, and regular users only see the jobs of networks
they own or that are shared with one of their teams (read/build/cancel, group
`team-<id>`); the per-network grants are written by the
webapp when it creates a network and whenever its team or owner changes.
Anonymous access is disabled. `JENKINS_PASS` is no longer used; HTTP Basic
authentication is only accepted with a Jenkins API token. Jenkins must therefore
stay reachable only through the proxy and webapp.

Anonymous Jenkins access is read-only: unauthenticated users can still
browse jobs and logs, but cannot start or cancel builds. CSRF protection is
enabled, so clients that trigger builds must submit a Jenkins crumb. The NITA
webapp handles this automatically; users who previously used Jenkins'
unauthenticated *Build Now* or cancel controls should use the webapp.

The Jenkins interface is accessible through the NITA webapp proxy.

Please refer to the [README][readme] for more details.

# Installing

The simplest way to install nita-jenkins is by installing nita, which can be done by running the ``install.sh`` script located and in the parent [nita repo][branch] as described [here][readme].

# Copyright

Copyright 2024, Juniper Networks, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
