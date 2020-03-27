#!/bin/bash
setfacl -m user:1000:r ${HOME}/.Xauthority
docker build -t xeyes -f Dockerfile.xeyes .
exec docker run \
    -it \
    --rm \
    --name xeyes \
    --net=host \
    -e DISPLAY \
    -v ${HOME}/.Xauthority:/home/user/.Xauthority \
    xeyes \
    "$@"
