# Agent workflow

- This checkout is the Cage 0.3.0 / wlroots 0.20.2 line. Leave the v0.2.0 and v0.1.5 branches' archive-and-patch build workflows unchanged.
- Cage and wlroots are submodules under `forks/`. They are pinned by this repository's gitlinks; use the fork branches recorded in `.gitmodules` for development.
- To change either dependency, switch to its development branch, make and commit the change in that submodule, then update the parent gitlink with `git add forks/cage` or `git add forks/wlroots-xtmapper`. Commit and push the fork change before publishing the parent pin.
- Build source is assembled from committed submodule trees under ignored `build/source/`; Meson state lives separately in `build/meson/`. Commit fork changes and update the parent gitlink before building them.
- Do not regenerate exported source patches. Dependency archives, Meson wraps, and `SHA256SUMS` remain maintained inputs.
- For build or launcher changes, run `bash -n build.sh cage_xtmapper.sh tests/*.sh`, ShellCheck, `bash tests/test-build.sh`, and `bash tests/test-launcher.sh`.
