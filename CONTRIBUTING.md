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

Releases are fully automated by
[release-please](https://github.com/googleapis/release-please) driven by
conventional commits.

1. Merge conventional-commit PRs into `main` (`feat:`, `fix:`, `refactor:`,
   `feat!:` for breaking, etc.).
2. release-please keeps an open "chore(main): release X.Y.Z" PR in sync,
   bumping [`VERSION`](VERSION) and [`CHANGELOG.md`](CHANGELOG.md) according
   to commit semantics.
3. Merge the Release PR. release-please then creates the `vX.Y.Z` git tag and
   a GitHub release.
4. The `release` workflow fires on the tag, builds multi-arch (`amd64`,
   `arm64`), pushes to GHCR and Docker Hub (`:vX.Y.Z`, `:X.Y`, `:X`, plus
   `:latest` when releasing from default branch), generates SBOM + provenance,
   and signs digests with cosign (keyless OIDC).

To force a specific version (e.g. first stable), add a footer to any
commit on `main`:

```
Release-As: 1.0.0
```
