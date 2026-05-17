# Contributing

## Branch model

- `main` — released, signed images. Protected; PR-only.
- `dev` — integration branch. PRs target `dev`; `dev` → `main` cuts a release.

## Workflow

1. Branch from `dev`: `git checkout -b feat/my-change dev`.
2. Commit with conventional-commit prefixes (`feat:`, `fix:`, `chore:`, `ci:`).
3. Open a PR into `dev`. CI must pass (hadolint, shellcheck, yamllint,
   actionlint, build, smoke test, Trivy).
4. Squash-merge.

## Local development

```sh
docker buildx build --load -t ubuntu-desktop:dev .
IMAGE=ubuntu-desktop:dev ./tests/smoke.sh
```

To test a slim variant:

```sh
docker buildx build --load \
  --build-arg VARIANT=slim \
  --build-arg INCLUDE_BROWSER=false \
  --build-arg INCLUDE_MEDIA=false \
  --build-arg INCLUDE_VSCODE=false \
  -t ubuntu-desktop:dev-slim .
```

## Releases

Tag `main` with `vMAJOR.MINOR.PATCH`. The `release` workflow builds
multi-arch (`amd64`, `arm64`), pushes to GHCR and Docker Hub, generates SBOM
+ provenance, and signs digests with cosign (keyless OIDC).
