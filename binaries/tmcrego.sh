#!/bin/bash
export $(cat /root/.env | xargs)
export KUBECTL_VSPHERE_PASSWORD=$TKG_VSPHERE_CLUSTER_PASSWORD
printf "\n\n\n***********Starting TMC Registration on $TKG_SUPERVISOR_ENDPOINT ...*************\n"

if [ -z "$BASTION_HOST" ]
then
    printf "\n\n\n***********Login into Supervisor cluster...*************\n"
    rm /root/.kube/config
    rm -R /root/.kube/cache
    kubectl vsphere login --insecure-skip-tls-verify --server $TKG_SUPERVISOR_ENDPOINT --vsphere-username $TKG_VSPHERE_CLUSTER_USERNAME
    kubectl config use-context $TKG_SUPERVISOR_ENDPOINT
else
    printf "\n\n\n***********Creating Tunnel through bastion $BASTION_USERNAME@$BASTION_HOST ...*************\n"
    ssh-keyscan $BASTION_HOST > /root/.ssh/known_hosts
    ssh -i /root/.ssh/id_rsa -4 -fNT -L 443:$TKG_SUPERVISOR_ENDPOINT:443 $BASTION_USERNAME@$BASTION_HOST
    ssh -i /root/.ssh/id_rsa -4 -fNT -L 6443:$TKG_SUPERVISOR_ENDPOINT:6443 $BASTION_USERNAME@$BASTION_HOST

    printf "\n\n\n***********Login into Supervisor cluster...*************\n"
    rm /root/.kube/config
    rm -R /root/.kube/cache
    kubectl vsphere login --insecure-skip-tls-verify --server kubernetes --vsphere-username administrator@vsphere.local
    sed -i 's/kubernetes/'$TKG_SUPERVISOR_ENDPOINT'/g' ~/.kube/config
    kubectl config use-context $TKG_SUPERVISOR_ENDPOINT
    sed -i '0,/'$TKG_SUPERVISOR_ENDPOINT'/s//kubernetes/' ~/.kube/config
fi

if [ -z "$COMPLETE" ]
then
    printf "\n\n\n***********Getting TMC SVC Name...*************\n"
    TMCSVCNAME="$(kubectl get ns -o=jsonpath='{range .items..metadata}{.name}{"\n"}{end}' | grep svc-tmc)"
    echo "tmc svc name: $TMCSVCNAME"

    printf "\n\n\n***********Adjusting Registration yaml with link and tmc svc name...*************\n"
    sed -ri 's/^(\s*)(namespace\s*:\s*tmcsvc\s*$)/\1namespace: '$TMCSVCNAME'/' /tmp/tmc-registration.yaml
    awk -v old="tmcregistrationlink" -v new="$TMC_REGISTRATION_LINK" 's=index($0,old){$0=substr($0,1,s-1) new substr($0,s+length(old))} 1' /tmp/tmc-registration.yaml > /tmp/t.yaml && mv /tmp/t.yaml /tmp/tmc-registration.yaml

    printf "\n\n\n***********Applying registration yaml...*************\n"
    kubectl create -f /tmp/tmc-registration.yaml

    printf "\n\n\n***********Giving it 3 mins...*************\n"
    sleep 3m

    printf "\n\n\n***********Checking status...*************\n"
    kubectl -n $TMCSVCNAME describe agentinstall tmc-agent-installer-config

    printf "\n\n\nWhen the status: line at the bottom of the output changes from INSTALLATION_IN_PROGRESS to INSTALLED, the installation is complete.\n"
    printf "\nIf the status comes out to be IN_PROGRESS here then run the below command to check progress again few mins later:\n"
    printf "\n\nkubectl -n $TMCSVCNAME describe agentinstall tmc-agent-installer-config\n"
    printf "\n\nCOMPLETE. Thank you.\n"

    printf "\nCOMPLETE=YES" >> /root/.env
else
    printf "\n\n\nTMC Registration is already marked as complete. (If this is not desired please change COMPLETE=\"\" or remove COMPLETE in the .env for new registration)\n"
    printf "\n\n\nGoing straight to shell access.\n"
fi

/bin/bash
