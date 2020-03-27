# VecText

run with:
```bash
docker run -ti --rm -e DISPLAY=:0 -v /tmp/.X11-unix:/tmp/.X11-unix  --name my-vectext vectext
```
or:
```bash
./vextex_run_docker.sh
```

## Build the container
`docker build -t vectext:latest .`
`docker build -t vectext:latest . -f Dockerfile`
