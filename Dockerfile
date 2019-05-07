FROM selenium/standalone-chrome-debug

USER root

RUN apt-get update \
    && apt-get install -yq git openbox openjdk-11-jre-headless maven \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

# add 'gitpod' user and permit "sudo -u seluser". 'seluser' is the standard user from selenium.
RUN addgroup --gid 33333 gitpod \
 && useradd --no-log-init --create-home --home-dir /home/gitpod --shell /bin/bash --uid 33333 --gid 33333 gitpod \
 && echo "gitpod ALL=(seluser) NOPASSWD: ALL" >> /etc/sudoers \
 && mkdir "/home/gitpod/.m2" \
 && printf '<settings>\n  <localRepository>/workspace/m2-repository/</localRepository>\n</settings>\n' > /home/gitpod/.m2/settings.xml

# Install Novnc and register it with Supervisord.
RUN git clone https://github.com/novnc/noVNC.git /opt/novnc \
    && git clone https://github.com/novnc/websockify /opt/novnc/utils/websockify
COPY novnc-index.html /opt/novnc/index.html
COPY novnc.conf /etc/supervisor/conf.d/
EXPOSE 6080

# Configure Supervisord to launch as daemon.
RUN sed -i -e 's/nodaemon=true/nodaemon=false/g' /etc/supervisord.conf

USER gitpod
ENV HOME=/home/gitpod
ENV VNC_NO_PASSWORD=true

# use .bashrc to launch Supervisord, in case it is not yet runnning
RUN echo "[ ! -e /var/run/supervisor/supervisord.pid ] && /usr/bin/supervisord --configuration /etc/supervisord.conf" >> ~/.bashrc