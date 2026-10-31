# brew-taps-api

Cask data for third-party [Homebrew](https://brew.sh/) taps, generated daily for [cask2nix](https://github.com/glassesneo/cask2nix).

[brew-api](https://github.com/BatteredBunny/brew-api) covers the official `homebrew/cask` tap; this repository does the same for the taps listed in [`taps.txt`](taps.txt). Third-party casks are Ruby, so `brew` has to evaluate them; CI does that on macOS and commits the result, and Nix only reads JSON.

## Layout

```
taps.txt                       # taps to generate, one per line
taps/<user>/<repo>/cask.json   # generated; `brew info --json=v2 --variations` per tap
```

`taps/` is replaced as a whole on every run, so a tap removed from `taps.txt` disappears from it.

## Usage

Add this repository as a non-flake input and pass `taps/` to cask2nix's `mkTaps`:

```nix
inputs.brew-taps-api = {
  url = "github:glassesneo/brew-taps-api";
  flake = false;
};

brewTaps = cask2nix.lib.mkTaps { inherit pkgs; source = "${brew-taps-api}/taps"; };
```

```nix
brewTaps.phibrowser.tap.phi
```

`nix flake update brew-taps-api` picks up the latest data, the same way as brew-api.

## Your own taps

Fork or copy this repository and edit `taps.txt`. The [update workflow](.github/workflows/update.yml) runs daily, on pushes that change `taps.txt` or the generator, and on demand. It regenerates `taps/`, evaluates every cask with cask2nix (`nix flake check ./tests`), and commits only when that passes. Pull requests that touch the same files run the same check without committing.

To generate locally (requires `brew` on `PATH`):

```bash
nix run github:glassesneo/brew-taps-api#gen-tap -- taps.txt taps
```
