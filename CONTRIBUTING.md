# Contributing

This checkout is the `v0.3.0` line: Cage 0.3.0 with wlroots 0.20.2. The `v0.2.0` and `v0.1.5` branches have their own established build workflows; preserve those branch-specific workflows when working here.

## Updating Cage or wlroots

Cage and wlroots are pinned as submodules under `forks/`. Their development branches are recorded in `.gitmodules`. Make and publish a dependency change in this order:

1. Switch the dependency submodule to its recorded development branch, edit it, and commit the change there.
2. Push that fork commit.
3. Update and commit the parent repository gitlink with `git add forks/cage` or `git add forks/wlroots-xtmapper`.
4. Build only after the fork commit and parent gitlink are recorded.

The build stages committed submodule trees under ignored `build/source/`; Meson state is separate under `build/meson/`. Do not regenerate exported source patches. Dependency archives, Meson wraps, and `SHA256SUMS` are maintained inputs.

## Backports

When a fix also applies to `v0.2.0` or `v0.1.5`, make a separate backport commit on that branch and adapt it to that branch's existing source and build layout. Do not assume the v0.3.0 submodule pins, CI steps, dependency inputs, or installer apply there. Run that branch's documented checks and preserve any contributor attribution carried by the original change.

## Checks and pull requests

For build, launcher, or installer changes, run:

```sh
bash -n build.sh install_deps.sh cage_xtmapper.sh tests/*.sh
shellcheck build.sh install_deps.sh cage_xtmapper.sh tests/*.sh
bash tests/test-install-deps.sh
bash tests/test-build.sh
bash tests/test-launcher.sh
```

Pull requests should explain the user-visible behavior, list checks run, and include relevant dependency fork commits before the parent pin. Preserve prior contributor credit when adapting code; see [CONTRIBUTORS.md](CONTRIBUTORS.md).
