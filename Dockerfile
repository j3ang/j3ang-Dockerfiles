FROM ubuntu:14.04
# Referenced From https://github.com/kartoza/docker-ssh/blob/master/Dockerfile


# ==============================================
# * @Desc: Install necceassary packages
# ==============================================

RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
RUN apt-get -y update # socat can be used to proxy an external port and make it look like it is local
RUN apt-get -y install ca-certificates socat openssh-server supervisor rpl pwgen


# ==============================================
# * @Desc: Copy up the config file
# ==============================================
RUN mkdir /var/run/sshd
ADD /conf/sshd.conf /etc/supervisor/conf.d/sshd.conf


# ==============================================
# * @Desc: Enable password access
# ==============================================
RUN rpl "PermitRootLogin without-password" "PermitRootLogin yes" /etc/ssh/sshd_config
RUN rpl "#PasswordAuthentication yes" "PasswordAuthentication yes" /etc/ssh/sshd_config


# =========================================
# * @Desc: Enable public keys
# =========================================
# Write pub keys into the docker build context folder to the /root/.ssh/authorized_key file
RUN mkdir /root/.ssh
RUN chmod o-rwx /root/.ssh

RUN touch /root/.ssh/authorized_keys
RUN for f in /pubKeys/*.pub; do (cat $f; echo '') >> /root/.ssh/authorized_keys; done

# Replace docker image sshd_config 
RUN rpl "#PubkeyAuthentication yes" "PubkeyAuthentication yes" /etc/ssh/sshd_config


# =========================================
# * @Desc: Add more setup here
# =========================================
# Run any additional tasks here that are too tedious to put in this dockerfile directly.
ADD /scripts/setup.sh /setup.sh
RUN chmod 0755 /setup.sh
RUN /setup.sh


# =========================================
# * @Desc: Start
# =========================================
# Called on first run of docker - will run supervisor
ADD /scripts/start.sh /start.sh

# Adjust script permissions
RUN chown root:root /start.sh
RUN chmod a+x /start.sh

# Expose Service Ports
EXPOSE 22 
ENTRYPOINT [ "./start.sh" ] 


