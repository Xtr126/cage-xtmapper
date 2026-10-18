# Contributing

This checkout is the `v0.3.0` line: Cage 0.3.0 with wlroots 0.20.2. Keep the `v0.2.0` and `v0.1.5` archive-and-patch build workflows unchanged when working here.

## Updating Cage or wlroots

Cage and wlroots are pinned as submodules under `forks/`. Their development branches are recorded in `.gitmodules`. Make and publish a dependency change in this order:

1. Switch the dependency submodule to its recorded development branch, edit it, and commit the change there.
2. Push that fork commit.
3. Update and commit the parent repository gitlink with `git add forks/cage` or `git add forks/wlroots-xtmapper`.
4. Build only after the fork commit and parent gitlink are recorded.

The build stages committed submodule trees under ignored `build/source/`; Meson state is separate under `build/meson/`. Do not regenerate exported source patches. Dependency archives, Meson wraps, and `SHA256SUMS` are maintained inputs.

## Checks and pull requests

For build or launcher changes, run:

```sh
bash -n build.sh cage_xtmapper.sh tests/*.sh
shellcheck build.sh cage_xtmapper.sh tests/*.sh
bash tests/test-build.sh
bash tests/test-launcher.sh
```

Installer changes should also run `bash -n install_deps.sh tests/test-install-deps.sh`, ShellCheck on both files, and `bash tests/test-install-deps.sh`. Pull requests should explain the user-visible behavior, list checks run, and include relevant dependency fork commits before the parent pin. Preserve prior contributor credit when adapting code; see [CONTRIBUTORS.md](CONTRIBUTORS.md).
