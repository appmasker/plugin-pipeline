# plugin-pipeline
A dockerfile for assembling custom Caddy builds


## Build tar file

```bash
tar -czf plugin-pipeline.tgz plugin-pipeline
```

## Run Build locally
```bash
docker build . -f plugin-pipeline/Dockerfile -t appmasker/plugin-pipeline:debug
```
### Optional flags
```bash
--no-cache --progress=plain
```

### Build args
```bash
--build-arg ACCESS_TOKEN_USR=nothing --build-arg ACCESS_TOKEN_PWD=nothing --build-arg APPMASKER_ACCESS_TOKEN=$GITHUB_APPMASKER_TOKEN --build-arg PLUGIN_REPOS=github.com/abiosoft/caddy-exec,github.com/caddyserver/ntlm-transport
```

## Execute shell locally
Note that docker uses a Ubuntu shell that isn't fully compatible with bash!
```bash
./plugin-pipeline/build-caddy.sh $GITHUB_APPMASKER_TOKEN nothing nothing github.com/abiosoft/caddy-exec,github.com/caddyserver/ntlm-transport
```