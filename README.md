# cage-xtmapper v0.2.0

This compatibility branch builds Cage 0.2.0 with wlroots 0.18.3 for distributions whose system libraries do not meet the v0.3.0 requirements. Use this branch for older systems that cannot build the default branch.

See the [v0.3.0 README](https://github.com/Xtr126/cage-xtmapper/blob/v0.3.0/README.md) for common usage, installation, and troubleshooting guidance. The v0.3.0 branch is the default branch and contains the main project documentation.

## Build

Install the build dependencies, clone with the pinned fork submodules, and build:

```sh
git clone --recurse-submodules -b v0.2.0 https://github.com/Xtr126/cage-xtmapper
cd cage-xtmapper
./install_deps.sh
./build.sh
```

For an existing checkout, initialize the pinned source trees with:

```sh
git submodule update --init --recursive
```

The build assembles the pinned Cage and wlroots commits under `build/source/` and keeps Meson's build state under `build/meson/`. The dependency archives and wrap files remain in this branch for systems that need Meson fallbacks.

The pinned fork branches are listed in `.gitmodules`: Cage uses `rebased-v0.2.0` and wlroots uses `codex/xtmapper-v0.18.3`. Commit fork changes before updating the matching parent gitlink.
