#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
exec flutter run -d web-server --web-hostname 127.0.0.1 --web-port 18105
