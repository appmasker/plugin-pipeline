# Caddy Dynamic Builder

### Build
```bash
docker build . --build-arg ENVIRONMENT=local -t appmasker/caddy-managed-base:dynamic-test --progress=plain
```

### Final Build (Production)
```bash
docker buildx build . --build-arg ENVIRONMENT=production -t appmasker/caddy-managed-base:dynamic --progress=plain --platform linux/amd64,linux/arm64 --push
```

### Final Build (Dev)
```bash
docker buildx build . --build-arg ENVIRONMENT=development -t appmasker/caddy-managed-base:dynamic-dev --progress=plain --platform linux/amd64,linux/arm64 --push
```