FROM selenium/standalone-chrome-debug

USER root

RUN apt-get update \
    && apt-get install -yq \
        git \
        openbox \
        openjdk-11-jdk-headless \
        maven \
        # Need for adding ca-certificates to chrome
        libnss3-tools \
        # needed for JavaScript development
        nodejs npm yarn \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/

# add 'gitpod' user and permit "sudo -u seluser". 'seluser' is the standard user from selenium.
RUN addgroup --gid 33333 gitpod \
 && useradd --no-log-init --create-home --home-dir /home/gitpod --shell /bin/bash --uid 33333 --gid 33333 gitpod \
 && echo "gitpod ALL=(seluser) NOPASSWD: ALL" >> /etc/sudoers

# Install Novnc and register it with Supervisord.
RUN git clone https://github.com/novnc/noVNC.git /opt/novnc \
    && git clone https://github.com/novnc/websockify /opt/novnc/utils/websockify
COPY novnc-index.html /opt/novnc/index.html
COPY novnc.conf /etc/supervisor/conf.d/
EXPOSE 6080

# Configure Supervisord to launch as daemon.
RUN sed -i -e 's/nodaemon=true/nodaemon=false/g' /etc/supervisord.conf

# Install fwd-proxy ca certificate for distro
ARG CERT_PATH=/usr/local/share/ca-certificates/fwd-proxy.crt
ARG CERT_NAME="Gitpod - Forward Proxy"
COPY fwd-proxy.crt ${CERT_PATH}
RUN chmod 644 ${CERT_PATH} && update-ca-certificates

USER gitpod
ENV HOME=/home/gitpod
ENV VNC_NO_PASSWORD=true
ENV START_XVFB=true

# Install ca certificate for chrome
ARG NSSDB_PATH=$HOME/.pki/nssdb
RUN mkdir -p $NSSDB_PATH \
    && certutil -d sql:$NSSDB_PATH -N --empty-password \
    && certutil -d sql:$NSSDB_PATH -A -n "${CERT_NAME}" -t "TCu,Cu,Tu" -i "${CERT_PATH}"

# use .bashrc to launch Supervisord, in case it is not yet runnning
COPY --chown=root:root cfg-* /usr/bin/
RUN echo "if [ ! -e /home/gitpod/.m2/settings.xml ]; then if [ -z \"\$HTTP_PROXY\" ]; then . cfg-noproxy.sh; else . cfg-proxy.sh; fi; fi" >> ~/.bashrc
RUN echo "[ ! -e /var/run/supervisor/supervisord.pid ] && /usr/bin/supervisord --configuration /etc/supervisord.conf" >> ~/.bashrc

# the prompt in the Bash Terminal should show 'applitools' and not the current user name
RUN { echo && echo "PS1='\[\e]0;applitools \w\a\]\[\033[01;32m\]applitools\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\] \\\$ '" ; } >> ~/.bashrc

# Maven settings
COPY --chown=gitpod:gitpod m2/ /home/gitpod/.m2/

RUN echo "6" > "/home/gitpod/.imageversion"

