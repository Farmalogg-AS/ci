# Contributing

Commit messages and commit scope follow the workspace-wide [CONTRIBUTING.md](../CONTRIBUTING.md)
([GitHub](https://github.com/Farmalogg-AS/root/blob/main/CONTRIBUTING.md)). This file only covers what's specific to
this repo: other repos run these actions by version tag, so every tag is a published release.

## Making a change

- Keep actions generic: no steps specific to one repo (see [README.md](README.md)), and, since this repo is
  public, no secrets or infrastructure names (registries, resource groups, app names, package URLs). Take
  those as inputs; callers pass secrets from their own `secrets` context.
- Update [README.md](README.md) and add an entry under the upcoming version in [CHANGELOG.md](CHANGELOG.md) in
  the same commit as the change, so every tagged commit documents itself.
- In the changelog entry, call out anything consuming repos must change when they bump to that version (e.g. a
  new required input, or a changed tag format).
- To try out a change before releasing it, point a consuming repo's feature branch at your branch or commit
  (`uses: Farmalogg-AS/ci/.github/actions/<action>@<branch-or-sha>`), and switch it back to a version tag before
  merging.

## Releasing a version

- Tag the commit on `main` with the next version, as an annotated tag summarising the release, and push it:
  `git tag -a v0.N -m "<summary>"`, then `git push origin v0.N`. While on `v0.x`, bump the minor number
  for every release, including breaking ones.
- Keep the annotation a one-line summary of what the version changes, e.g.
  `richer qa/prod tag annotations, fix prod tagging for hotfixes`. Leave out the version number, since the
  tag name already carries it (`git tag -n` shows both). Details belong in the version's
  [CHANGELOG.md](CHANGELOG.md) section.
- Never move or delete a pushed tag. Consuming repos resolve `@vX.Y` on every run, so moving a tag silently
  changes what runs in every repo, and deleting it breaks them. Fix a bad release with a new version instead.
  The "Protect version tags" ruleset (Settings → Rules → Rulesets) enforces this for `v*` tags, admins
  included.
