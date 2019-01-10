FROM ubuntu:18.04

ARG PROJECT
ARG GIT_USER
ARG GIT_PASS
ARG ENVIRONMENT

RUN apt update && apt install -y curl gnupg git wget apt-transport-https apt-utils sudo

RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update && apt-get install -y kubectl

RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk-$(cat /etc/os-release | grep VERSION_CODENAME | cut -d = -f2) main" >> /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN apt update && apt install -y google-cloud-sdk
ADD helm_user.key /helm_user.key
RUN gcloud auth activate-service-account --key-file /helm_user.key
RUN gcloud config set project $PROJECT
ADD startup.sh /startup.sh
RUN sh /startup.sh

RUN curl https://storage.googleapis.com/kubernetes-helm/helm-v2.12.1-linux-amd64.tar.gz --output helm-v2.12.1-linux-amd64.tar.gz
RUN tar -zxvf helm-v2.12.1-linux-amd64.tar.gz
RUN mv linux-amd64/helm /usr/local/bin/helm
RUN helm init --upgrade
RUN helm plugin install https://github.com/futuresimple/helm-secrets
RUN helm plugin install https://github.com/databus23/helm-diff --version master

RUN wget https://github.com/roboll/helmfile/releases/download/v0.41.0/helmfile_linux_amd64
RUN mv helmfile_linux_amd64 /usr/local/bin/helmfile
RUN chmod 755 /usr/local/bin/helmfile

RUN git clone https://$GIT_USER:$GIT_PASS@github.com/DdeDamian/CaylentTask.git

ADD secrets.yaml.dec /CaylentTask/env_vars/dev/secrets.yaml.dec

RUN helmfile -e $ENVIRONMENT -f CaylentTask/ apply
