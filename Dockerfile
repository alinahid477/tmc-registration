FROM debian:buster-slim

# culr (optional) for downloading/browsing stuff
# openssh-client (required) for creating ssh tunnel
# psmisc (optional) I needed it to test port binding after ssh tunnel (eg: netstat -ntlp | grep 6443)
# nano (required) buster-slim doesn't even have less. so I needed an editor to view/edit file (eg: /etc/hosts) 

RUN apt-get update && apt-get install -y \
	apt-transport-https \
	ca-certificates \
	curl \
    openssh-client \
	psmisc \
	nano \
	less \
	net-tools \
	&& curl -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
	&& chmod +x /usr/local/bin/kubectl

RUN curl -o /usr/local/bin/jq -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
  	chmod +x /usr/local/bin/jq

COPY .ssh/id_rsa /root/.ssh/
# COPY .ssh/known_hosts /root/.ssh/
RUN chmod 600 /root/.ssh/id_rsa

COPY binaries/tmcrego.sh /usr/local/
COPY binaries/kubectl-vsphere /usr/local/bin/ 
COPY tmc-registration.yaml /tmp/
RUN chmod +x /usr/local/bin/kubectl-vsphere && chmod +x /usr/local/tmcrego.sh
# RUN /usr/local/tmcrego.sh
# add the kubernetes workload cluster's alertnate subject DNS
# usually all TKG clusters have 'kubernetes' as one of the subject DNS
# this alternalte subject dns will later be used in ~/.kube/config
ENTRYPOINT [ "/usr/local/tmcrego.sh"]