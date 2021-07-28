# TMC Registration


## Pre-Requisites
Docker-ce installed on host computer.

## Preparation

**.ssh**
- Place the 'id_rsa' file for ssh login into bastion host
- Create an empty file called 'known_hosts'

**binaries**
- for vsphere cluster place kubectl-vsphere in this directory

**.env**
Rename the .env.sample to .env file (`mv .env.sample .env`) and fill the below values
- TKG_SUPERVISOR_ENDPOINT=*<host name or ip endpoint of TKG supervisor cluster>*
BASTION_HOST=*<the ip or hostname of the bastion host to get to the supervisor cluster. IF no bastion is needed leave it blank>*
BASTION_USERNAME=*<username for the bastion. IF no bastion is needed leave it blank>*
KUBECTL_VSPHERE_PASSWORD=*<password for administrator@vsphere.local>*
TMC_REGISTRATION_LINK=*<the URL obtained from TMC>*
COMPLETE=*<REMOVE THIS. After completing registration the script will auto add and populate this.>*


## Install and Run
docker build . -t tmcrego
docker run -it --rm -v ${PWD}:/root/ --add-host kubernetes:127.0.0.1 --name tmcrego tmcrego /bin/bash

The build will build the docker container with all necessary dependancies.
The run will execute series of commands to process tmc registration. After the it finishes it will give shell access.


## That's it.



## Essentially the below process is automated in this docker

### SSH into bastion (in the case when running in pvt cloud)
`ssh -i .ssh/id_rsa ubuntu@10.79.142.40`


### login into tkg supervisor cluster (in bastion)
```
kubectl vsphere login --insecure-skip-tls-verify --server 192.168.220.2 --vsphere-username administrator@vsphere.local
kubectl config use-context 192.168.220.2
```
### grab the tmc namespace name (begins with svc-tmc; in bastion)
`kubectl get ns | grep svc-tmc`

### modify tmc-registration.yaml (in local machine/laptop)
- with the svc-tmc-c1006 (or whichever the number is) 
- and the registration url from TMC console.

### copy the tmc-registration.yaml to the bastion for deployment
`scp -i .ssh/id_rsa tmc-registration.yaml ubuntu@10.79.142.40:/home/ubuntu/ali/`

### deploy tmc-registration.yaml (in bastion)
`kubectl create -f tmc-registration.yaml`

### to see progress (in bastion)
`kubectl -n svc-tmc-c1006 describe agentinstall tmc-agent-installer-config`