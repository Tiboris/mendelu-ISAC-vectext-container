#!/bin/bash
setfacl -m user:1000:r ${HOME}/.Xauthority
# docker build -t xeyes -f Dockerfile.xeyes .
exec docker run \
    -it \
    --rm \
    --name vectext-x \
    --net=host \
    -e DISPLAY \
    -v ${HOME}/.Xauthority:/home/user/.Xauthority \
    vectextx \
    "$@"
