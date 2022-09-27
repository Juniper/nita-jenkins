# Docker Image Build
To build the webapp docker image you can simply run the *build_container.sh* also found on the root folder of this repo:
```bash
./build_container.sh
```
## Installation requirements
If you're not using this aplication from a .deb/.rpm package installation please follow the next steps to ensure that you have a porper environment set up

### Generate a selfsigned certificate for jenkins
You may need to install aditional packages to be able to generate a selfsigned certificate for Jenkins.

#### Debian Based System
If you are on a Debian based system be sure to install the *default-jre-headless* package
```bash
sudo apt install default-jre-headless -y
```

#### Centos Based System
If you are on a Centos based system be sure to install the *java-11-openjdk-headless* package
```bash
sudo yum install -y default-jre-headless
```

#### Generate the certificate
```bash
mkdir -p certificates
keytool -genkey -keyalg RSA -alias selfsigned -keystore certificates/jenkins_keystore.jks -keypass nita123 -storepass nita123 -keysize 4096 -dname "cn=, ou=, o=, l=, st=, c="
```

### Create NITA Project folder
```
mkdir -p /var/nita_project
```

### Create NITA Docker Network
```bash
docker network create -d bridge nita-network
```

### Deploy NITA using Docker Compose
To launch this container you can use the supplied *docker_compose.yaml* file, simply run:
```bash
docker-compose -p nitajenkins up -d
```
