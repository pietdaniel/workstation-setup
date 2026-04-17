---
name: fix-ratify-vulns
description: Fix critical security vulnerabilities in Docker images and project dependencies. Use when user asks to "fix vulnerabilities", "patch CVEs", "update vulnerable packages", "fix security issues in Docker", "remediate CVEs", or wants to fix identified security vulnerabilities in a repository.
disable-model-invocation: true
tools: Read, Glob, Grep, Edit, Bash, AskUserQuestion
---

# Fix Docker Security Vulnerabilities

Remediates critical security vulnerabilities in Docker base images and project dependencies across the repository.

## Phase 1: Gather Vulnerability Information

Use the AskUserQuestion tool to collect details about the vulnerabilities before scanning anything.

Ask the user for:

- CVE IDs or vulnerability identifiers (e.g., CVE-2024-1234)
- Affected package/image names and the vulnerable version range
- The fixed version to upgrade to (if known)
- Which ecosystems are affected (npm, pip, Docker base image, Go, etc.)

If the user has not already provided this information, do not proceed past this phase until you have at least the package/image name and enough version information to act on.

## Phase 2: Discover All Dependency and Docker Files

Search the repository for every file that could reference a vulnerable package or image. Run these searches in parallel:

### Docker

- `Dockerfile`, `Dockerfile.*`, `*.dockerfile` — `FROM` directives and `RUN apt-get install` / `apk add` lines
- `docker-compose*.yml`, `docker-compose*.yaml` — `image:` keys

### Node.js / JavaScript

- `package.json` — `dependencies`, `devDependencies`, `peerDependencies`
- `package-lock.json` — full resolved dependency tree
- `yarn.lock`, `pnpm-lock.yaml`

### Python

- `requirements*.txt` — pip pinned deps
- `Pipfile`, `Pipfile.lock`
- `pyproject.toml` — Poetry `[tool.poetry.dependencies]` or PEP 621 `[project.dependencies]`

### Go

- `go.mod`, `go.sum`

### JVM (Java / Kotlin / Scala)

- `pom.xml` — Maven `<dependency>` blocks
- `build.gradle`, `build.gradle.kts` — Gradle dependency declarations

### Ruby

- `Gemfile`, `Gemfile.lock`

### Rust

- `Cargo.toml`, `Cargo.lock`

## Phase 3: Identify Vulnerable References

For each discovered file, search for the affected package/image names provided by the user.

Cross-reference the found versions against the vulnerable range. Flag:

1. **Direct matches** — the package is listed directly at a vulnerable version → update it
2. **Pinned-but-unlocked** — version constraint allows a vulnerable range even if the resolved version is safe → tighten the constraint
3. **Transitive-only** — the package appears only in a lockfile as a transitive dep → note it separately (see Phase 5)

## Phase 4: Apply Version Updates

Make the minimum change required to move off the vulnerable version. Prefer pinning to the exact fixed version over a broad range upgrade.

### Dockerfile base images

```
# Before
FROM node:18.19.0-alpine

# After
FROM node:18.20.4-alpine   ← or whatever the fixed tag is
```

- Update every `FROM` directive in multi-stage builds, not just the first.
- Look for `ARG`-based image tags (e.g., `ARG NODE_VERSION=18.19.0`) and update the `ARG` default.
- Check `docker-compose` `image:` keys for the same image.

### package.json

- Change the version specifier to `>=fixed-version` or the exact fixed version.
- Do **not** automatically run `npm install`; note that the user must regenerate the lockfile.

### requirements.txt / Pipfile

- Change `package==old` → `package==fixed` (or `package>=fixed,<next-major`).
- For Pipfile, update the version in `[packages]` or `[dev-packages]`.

### pyproject.toml

- Update the version specifier in `[tool.poetry.dependencies]` or `[project.dependencies]`.

### go.mod

- Update the `require` line: `module/path v0.old → module/path v0.fixed`
- Note that `go mod tidy` must be run to update `go.sum`.

### pom.xml

- Update the `<version>` tag inside the affected `<dependency>` block.

### build.gradle / build.gradle.kts

- Update the version string in the `implementation(...)` or `compile(...)` declaration.

### Gemfile

- Update the `gem 'name', '~> old'` version constraint.

## Phase 5: Report Changes and Follow-Up Actions

After all edits, produce a summary:

```
## Vulnerability Remediation Summary

### Changes Made
| File | Package / Image | Old Version | New Version |
|------|----------------|-------------|-------------|
| Dockerfile | node | 18.19.0-alpine | 18.20.4-alpine |
| package.json | lodash | ^4.17.15 | ^4.17.21 |

### Required Follow-Up Actions
- [ ] Regenerate lockfiles: `npm install` / `yarn install` / `pip-compile` / `go mod tidy`
- [ ] Rebuild Docker images: `docker build .`
- [ ] Run full test suite to verify no regressions

### Not Found
- <package> was not referenced directly in this repo (may be a transitive dependency only)

### Transitive Dependencies (manual action needed)
- <package> appears in package-lock.json as a transitive dep of <parent>.
  Run `npm audit fix` to attempt automatic resolution.
  Alternatively, upgrade <parent> to a version that pulls in the fixed transitive dep.
```

## Important Constraints

- **Never upgrade to `latest`** without a specific version — always pin to the known-fixed version.
- **Do not blindly do a major-version bump** — flag it to the user and ask before proceeding if the fixed version is a major version bump from the current one, as this may introduce breaking changes.
- **Check all stages** in multi-stage Dockerfiles — vulnerable images in intermediate stages can still be exploited during build.
- **Environment-specific compose files** — also check `docker-compose.override.yml`, `docker-compose.prod.yml`, `docker-compose.staging.yml`, etc.
- **Only edit files** — do not run `npm install`, `go mod tidy`, or similar commands automatically. Report what the user needs to run.
