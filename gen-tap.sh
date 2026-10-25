# Regenerate <outdir> from a manifest of Homebrew taps, writing each tap's casks
# to <outdir>/<user>/<repo>/cask.json in brew-api's format so the whole tree can
# be passed to brew-nix's mkTaps. Requires brew on PATH.
if [ $# -ne 2 ]; then
  echo "usage: gen-tap <manifest> <outdir>" >&2
  exit 1
fi
manifest="$1"
out="$2"

# One tap per line; blank lines and # comments are ignored.
mapfile -t taps < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$manifest" | grep -v '^$' || true)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for tap in "${taps[@]}"; do
  # brew names taps in lower case, so the directory follows it.
  tap="${tap,,}"
  if [[ ! "$tap" =~ ^[a-z0-9_.-]+/[a-z0-9_.-]+$ ]]; then
    echo "gen-tap: invalid tap '$tap' in $manifest" >&2
    exit 1
  fi

  brew tap "$tap" >&2
  mapfile -t tokens < <(brew tap-info --json "$tap" | jq -r '.[0].cask_tokens[]')

  mkdir -p "$tmp/$tap"
  if [ ${#tokens[@]} -eq 0 ]; then
    printf '[\n]\n' > "$tmp/$tap/cask.json"
    continue
  fi

  # --variations keeps every os/arch url instead of resolving them for this host.
  # The output mirrors brew-api: volatile fields dropped, one cask per line.
  brew info --json=v2 --variations --cask "${tokens[@]}" | jq -r '
    .casks
    | sort_by(.token)
    | map(del(.tap_git_head, .tap, .installed_time, .installed, .ruby_source_path, .ruby_source_checksum))
    | "[\n" + (map("\t" + tojson) | join(",\n")) + "\n]"
  ' > "$tmp/$tap/cask.json"
done

# Replace the whole tree only after every tap succeeded, so taps removed from
# the manifest disappear and a failure never leaves a partial update.
rm -rf "$out"
mkdir -p "$out"
cp -R "$tmp"/. "$out"
