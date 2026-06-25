# Contributing to caddy-waf

Thank you for your interest in contributing. This project follows the Developmi engineering standard.

## Development setup

```bash
# Clone the repository
git clone https://github.com/Miguel-DevOps/caddy-waf.git
cd caddy-waf

# Copy the environment template
cp .env.example .env

# Copy the Caddyfile template
cp Caddyfile.example Caddyfile
```

No additional dependencies are required — the project uses Docker and Docker Compose for all operations.

## Commit standard

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(service): add systemd service file for Caddy WAF
fix(docker): resolve layer cache invalidation in build step
docs: update README with Cosign verification instructions
chore(config): bump OWASP CRS to v4.24.0
```

Types: `feat` · `fix` · `docs` · `chore` · `refactor` · `perf` · `test` · `ci`

## Branch naming

```
feat/short-description
fix/issue-number-description
docs/update-readme
chore/bump-dependencies
ci/update-workflow
```

## Pull request process

1. Fork the repository and create your branch from `main`.
2. Make your changes, following the existing code style.
3. Test your changes locally with `docker compose up`.
4. Ensure any new environment variables are documented in `.env.example`.
5. Update documentation if your change affects public behavior.
6. Open a PR with a clear title following the commit standard.
7. CI will automatically build, scan, and sign the image on merge to `main`.
8. A maintainer will review within 5 business days.

## Reporting issues

Use [GitHub Issues](https://github.com/Miguel-DevOps/caddy-waf/issues). Include:
- Steps to reproduce
- Expected vs. actual behavior
- Caddy version, Docker version, and platform (linux/amd64, linux/arm64)
- Relevant log output (JSON audit logs are especially helpful)

## Code of conduct

This project adheres to the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).
