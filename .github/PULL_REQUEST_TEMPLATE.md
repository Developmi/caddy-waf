## Summary

<!-- 1-3 bullets describing what this PR does and why. -->

## Changes

| File | Change |
|------|--------|
| `path/to/file` | What changed and why |

## Test Plan

- [ ] `make lint` — all checks pass (yamllint, actionlint, hadolint, zizmor)
- [ ] `make test-waf` — go-ftw integration suite passes (4/4)
- [ ] `docker compose config` — valid compose file
- [ ] Manual validation against a running stack (if runtime behavior changed)

## Checklist

- [ ] Conventional commit format used in every commit (`feat:`, `fix:`, `docs:`, `chore:`, `ci:`)
- [ ] Branch name follows `type/description` convention
- [ ] No `Co-Authored-By` or AI attribution trailers in commit messages
- [ ] Docs updated if behavior changed (README, TUNING, SECURITY, ROADMAP)
- [ ] CHANGELOG entry added if this is a user-visible change

## Closes

<!-- Link the issue this PR resolves, if any. e.g. `Closes #12` -->
