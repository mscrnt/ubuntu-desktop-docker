# Changelog

## 1.0.0 (2026-05-19)


### Features

* full rewrite to Ubuntu 24.04, single image, modern CI/CD ([37b4521](https://github.com/mscrnt/ubuntu-desktop-docker/commit/37b452115b36aa39c9b269f2d35527488f0b2994))
* usability fixes — Firefox, multi-Python, NoMachine working, terminals ([c848235](https://github.com/mscrnt/ubuntu-desktop-docker/commit/c8482358150e2dc71ff3cfbd9c7c147086018f07))


### Bug Fixes

* **ci:** resolve lint and build failures ([7c1ca78](https://github.com/mscrnt/ubuntu-desktop-docker/commit/7c1ca7871af595797c554d7b7c7541870c409657))
* **ci:** trivy-action tags are v-prefixed (v0.36.0, not 0.36.0) ([f6fedcd](https://github.com/mscrnt/ubuntu-desktop-docker/commit/f6fedcd9a011e4a0037c7d4ba29329c980c14922))
* smoke test now passes locally (slim + full variants) ([1efbe43](https://github.com/mscrnt/ubuntu-desktop-docker/commit/1efbe43360fb1fa98880a6abfa749b7c681b059a))


### Refactor

* unify branches into single image, upgrade to 24.04, add CI/CD ([6e18ea2](https://github.com/mscrnt/ubuntu-desktop-docker/commit/6e18ea257517f367d2229369f0e75297e85380a3))


### CI/CD

* add release-please for automated semver + multi-registry publish ([5014397](https://github.com/mscrnt/ubuntu-desktop-docker/commit/50143974cecfd8e48c3e2c0e0f710f7024c8a80f))

## Changelog

This file is managed automatically by [release-please](https://github.com/googleapis/release-please)
based on conventional commits merged into `main`.
