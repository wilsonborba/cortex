#!/usr/bin/env bash
set -euo pipefail

readonly REPOSITORY='wilsonborba/cortex_cli'
readonly LATEST_RELEASE_URL="https://github.com/${REPOSITORY}/releases/latest"
readonly INSTALLER_BASE_URL="https://raw.githubusercontent.com/${REPOSITORY}"

usage() {
  cat <<'EOF'
Usage: install.sh [--install-dir ABSOLUTE_PATH] [--dry-run]

Installs the latest stable Cortex CLI release for Linux or macOS on x86_64 or
ARM64. The versioned CLI installer verifies the release SHA-256 checksum.

Options:
  --install-dir ABSOLUTE_PATH  Install directory (default: ~/.local/bin)
  --dry-run                    Print the selected release without installing
  -h, --help                   Show this help
EOF
}

fail() {
  printf 'Cortex installer: %s\n' "$1" >&2
  exit 1
}

forward_args=()
while (($#)); do
  case "$1" in
    --version)
      fail 'the version is selected from the latest published release; --version is not accepted.'
      ;;
    --install-dir)
      (($# >= 2)) || fail '--install-dir needs an absolute path.'
      [[ "$2" == /* ]] || fail '--install-dir needs an absolute path.'
      forward_args+=(--install-dir "$2")
      shift 2
      ;;
    --dry-run)
      forward_args+=(--dry-run)
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unsupported option: $1"
      ;;
  esac
done

command -v curl >/dev/null 2>&1 || fail 'curl is required.'

# Ask GitHub for the latest-release redirect without following it or fetching
# the release page. Only a repository tag URL with a stable version is used.
if ! release_response="$(curl --silent --show-error \
  --proto '=https' --proto-redir '=https' --max-redirs 0 \
  --output /dev/null --write-out '%{http_code}\n%{redirect_url}' \
  "$LATEST_RELEASE_URL")"; then
  fail 'could not check for a published CLI release.'
fi
release_status="${release_response%%$'\n'*}"
release_url="${release_response#*$'\n'}"
case "$release_status" in
  301|302|303|307|308) ;;
  *) fail 'no published stable CLI release is available yet.' ;;
esac
if [[ ! "$release_url" =~ ^https://github\.com/wilsonborba/cortex_cli/releases/tag/(v[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
  fail 'no published stable CLI release is available yet.'
fi
version="${BASH_REMATCH[1]}"

temp_dir="$(mktemp -d)" || fail 'could not create a temporary directory.'
cleanup() {
  rm -rf "$temp_dir"
}
trap cleanup EXIT

installer_path="$temp_dir/install.sh"
installer_url="${INSTALLER_BASE_URL}/${version}/scripts/install.sh"
if ! curl --fail --silent --show-error --proto '=https' \
  --output "$installer_path" "$installer_url"; then
  fail 'could not download the versioned CLI installer.'
fi
[[ -s "$installer_path" ]] || fail 'the downloaded CLI installer is empty.'
[[ "$(head -n 1 "$installer_path")" == '#!/usr/bin/env bash' ]] || \
  fail 'the downloaded file is not the CLI installer.'
grep -Fq 'REPOSITORY="wilsonborba/cortex_cli"' "$installer_path" || \
  fail 'the downloaded file is not the CLI installer.'
grep -Fq 'Downloads one versioned Cortex CLI release, verifies its SHA-256 checksum' \
  "$installer_path" || fail 'the downloaded file is not the CLI installer.'

bash "$installer_path" --version "$version" "${forward_args[@]}"
