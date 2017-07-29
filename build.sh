#!/bin/bash
VERSION="latest"
DOCKER_REPO="elchinoo/pxc"

docker build -f Dockerfile -t $DOCKER_REPO:$VERSION .
