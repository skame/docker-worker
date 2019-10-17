FROM phusion/baseimage:0.11

LABEL maintainer "KAMEI Satoshi / <skame@nttv6.jp>"

ENV DEBIAN_FRONTEND noninteractive

RUN apt update && apt upgrade -y -o Dpkg::Options::="--force-confold"
RUN apt install -y --no-install-recommends software-properties-common sudo \
	git-core nkf \
	curl wget \
        build-essential

# locale
RUN apt install -y --no-install-recommends language-pack-ja && export LANG=ja_JP.UTF-8 && update-locale LANG=ja_JP.UTF-8
# for ldap
RUN apt install -y --no-install-recommends libpam-ldapd tcsh libnss-ldapd && \
        echo session required                        pam_mkhomedir.so umask=0022 skel=/etc/skel >> /etc/pam.d/common-session && \
        echo session required                        pam_mkhomedir.so umask=0022 skel=/etc/skel >> /etc/pam.d/common-session-noninteractive
# nslcd
RUN rm /etc/nslcd.conf && sed -i 's/compat/compat ldap/' /etc/nsswitch.conf && mkdir /etc/service/nslcd
COPY nslcd-run /etc/service/nslcd/run
COPY nslcd.conf-template /etc/nslcd.conf-template
# for sshd
RUN rm -f /etc/service/sshd/down && /etc/my_init.d/00_regen_ssh_host_keys.sh
#COPY ssh/ /etc/ssh/
#RUN chown root:root /etc/ssh/* && chmod 400 /etc/ssh/*key
RUN sed -ri 's/^session\s+required\s+pam_loginuid.so$/session optional pam_loginuid.so/' /etc/pam.d/sshd && \
    mkdir -p /var/run/sshd && chmod 0755 /var/run/sshd
RUN echo "UsePAM yes" >> /etc/ssh/sshd_config
# docker and utilities
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && apt-key fingerprint 0EBFCD88 && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    edge" && apt update && apt install -y --no-install-recommends docker-ce
RUN curl -s -L https://github.com/docker/compose/releases/latest | \
    grep -E -o '/docker/compose/releases/download/[0-9.]*/docker-compose-Linux-x86_64' | head -1 | \
    (curl -Lo /usr/local/bin/docker-compose http://github.com/"$(cat)") && \
    chmod +x /usr/local/bin/docker-compose && \
    /usr/local/bin/docker-compose --version

# some programming languages
RUN apt install -y --no-install-recommends openjdk-8-jdk python3-dev python3-pip
RUN pip3 install -U pip
RUN pip3 install -U setuptools
RUN pip3 install awscli pyasn

# some useful softwares
RUN apt install -y --no-install-recommends zsh tmux w3m owncloud-client-cmd rsync man telnet redis-tools dnsutils jq bc ash lv unzip mosh netcat
# some network tools
RUN apt install -y --no-install-recommends inetutils-ping inetutils-traceroute iproute2
# emacs
RUN add-apt-repository ppa:kelleyk/emacs && apt update && apt install -y --no-install-recommends emacs26
# add db tools
RUN apt install -y --no-install-recommends mysql-client postgresql-client

RUN apt install -y --no-install-recommends ldap-utils
RUN apt install -y --no-install-recommends weechat

# ruby (for selenium)
#RUN apt install -y --no-install-recommends ruby ruby-dev gem && gem install --no-ri --no-rdoc selenium-webdriver

# Clean up APT when done.
RUN apt clean && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

#BEEEEEEEELINE
RUN mkdir /opt/beeline \
	&& curl -SL https://archive.apache.org/dist/hadoop/core/hadoop-3.2.0/hadoop-3.2.0.tar.gz \
	| tar -xzC /opt/beeline \
	&& curl -SL https://archive.apache.org/dist/hive/hive-3.1.1/apache-hive-3.1.1-bin.tar.gz \
	| tar -xzC /opt/beeline
ENV HADOOP_HOME /opt/beeline/hadoop-3.2.0
ENV HIVE_HOME /opt/beeline/apache-hive-3.1.1-bin
ENV PATH $PATH:$HIVE_HOME/bin

# Presto CLI
RUN curl -s -L https://prestosql.io/docs/current/installation/cli.html | \
    grep -E -o 'https://repo1.maven.org/maven2/io/prestosql/presto-cli/[0-9.]+/presto-cli-[0-9.]+-executable.jar' | \
    (curl -Lo /usr/local/bin/presto "$(cat)") && \
    chmod +x /usr/local/bin/presto && \
    /usr/local/bin/presto --version
# entrykit
RUN curl -Ls https://github.com/progrium/entrykit/releases/ | \
  grep -E -o '/progrium/.*entrykit_[0-9\.]+_Linux_x86_64.tgz' | head -1 | \
  (curl -Lo entrykit.tgz http://github.com/"$(cat)") \
  && tar xzf entrykit.tgz -C /bin \
  && rm entrykit.tgz \
  && chmod +x /bin/entrykit \
  && entrykit --symlink && entrykit -v

# sigli
RUN curl -Ls https://github.com/gliderlabs/sigil/releases | \
  grep -E -o '/gliderlabs/sigil/.*sigil_[0-9\.]+_Linux_x86_64.tgz' | head -1 | \
  (curl -Lo sigil.tgz http://github.com/"$(cat)") \
  && tar xzf sigil.tgz -C /bin \
  && rm sigil.tgz && sigil -v
# go
RUN add-apt-repository ppa:longsleep/golang-backports && \
	apt-get update && apt-get install -y --no-install-recommends golang-go && \
	apt-get clean && rm -rf /var/lib/apt/lists/*
# k8s
RUN curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
RUN curl -s -L https://storage.googleapis.com/kubernetes-release/release/stable.txt | \
    (curl -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/"$(cat)"/bin/linux/amd64/kubectl)
RUN curl -Lo /usr/local/bin/skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
RUN curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest |\
	grep browser_download | grep linux | cut -d '"' -f 4 | xargs curl -O -L && \
	mv kustomize_*_linux_amd64 /usr/local/bin/kustomize
RUN chmod a+x /usr/local/bin/kubectl /usr/local/bin/skaffold /usr/local/bin/kustomize
# gcloud
RUN ls /etc/apt/sources.list.d
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
    echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update -y && apt-get install google-cloud-sdk -y --no-install-recommends && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
# velero
RUN curl -s https://github.com/vmware-tanzu/velero/releases | grep linux-amd64 | head -1 | \
    cut -d '"' -f 2 | (curl -Ls "https://github.com/$(cat)") | \
    tar xvfzO - --wildcards '*/velero' > /usr/local/bin/velero && chmod a+x /usr/local/bin/velero

# some customize scripts
RUN mkdir -p /etc/my_init.d
COPY adduser.sh /etc/my_init.d/adduser.sh
RUN chmod +x /etc/my_init.d/adduser.sh
# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

EXPOSE 22
