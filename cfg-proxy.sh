#!/bin/bash

npm config set proxy "$HTTP_PROXY" \
npm config set https-proxy "$HTTPS_PROXY"

export NO_PROXY=localhost

(cd /home/gitpod/.m2; ln -s settings-proxy.xml settings.xml)