#!/usr/bin/env python3
"""Offline tests for the public install.sh bootstrap and static route."""

from __future__ import annotations

import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
SHIM = ROOT / "web" / "install.sh"
TAG_URL = "https://github.com/wilsonborba/cortex_cli/releases/tag/v1.2.3"
INSTALLER = """#!/usr/bin/env bash
# Downloads one versioned Cortex CLI release, verifies its SHA-256 checksum,
REPOSITORY="wilsonborba/cortex_cli"
printf '%s\\n' "$@" > "$FAKE_INSTALL_LOG"
"""


FAKE_CURL = r'''#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$FAKE_CURL_LOG"
url=''
output=''
while (($#)); do
  case "$1" in
    --output) shift; output="$1" ;;
  esac
  url="$1"
  shift
done
if [[ "$url" == *'/releases/latest' ]]; then
  printf '%s' "$FAKE_LATEST_RESPONSE"
  exit 0
fi
if [[ "${FAKE_DOWNLOAD_FAIL:-0}" == 1 ]]; then
  exit 22
fi
if [[ "${FAKE_BAD_INSTALLER:-0}" == 1 ]]; then
  printf '%s\n' 'touch "$FAKE_INSTALL_LOG"' > "$output"
  exit 0
fi
cat > "$output" <<'INSTALLER'
''' + INSTALLER + '''
INSTALLER
'''


class InstallShimTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="install-shim-test-")
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.bin = self.work / "bin"
        self.bin.mkdir()
        fake_curl = self.bin / "curl"
        fake_curl.write_text(FAKE_CURL)
        fake_curl.chmod(0o755)
        self.calls = self.work / "curl-calls"
        self.installed_args = self.work / "installer-args"

    def run_shim(self, *args: str, **env_overrides: str) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env.update(
            {
                "PATH": f"{self.bin}:{env['PATH']}",
                "TMPDIR": str(self.work),
                "FAKE_CURL_LOG": str(self.calls),
                "FAKE_INSTALL_LOG": str(self.installed_args),
                "FAKE_LATEST_RESPONSE": f"302\n{TAG_URL}",
            }
        )
        env.update(env_overrides)
        return subprocess.run(
            ["bash", str(SHIM), *args],
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )

    def test_static_asset_has_direct_script_route_and_safe_headers(self) -> None:
        self.assertTrue(SHIM.is_file())
        self.assertTrue(SHIM.stat().st_mode & stat.S_IXUSR)
        self.assertTrue(SHIM.read_text().startswith("#!/usr/bin/env bash\n"))
        headers = (ROOT / "web" / "_headers").read_text()
        self.assertIn("/install.sh\n  Content-Type: text/x-shellscript", headers)
        self.assertIn("X-Content-Type-Options: nosniff", headers)
        self.assertIn("/* /index.html 200", (ROOT / "web" / "_redirects").read_text())

    def test_resolves_valid_release_downloads_existing_installer_and_cleans_temp(self) -> None:
        result = self.run_shim("--dry-run", "--install-dir", "/opt/cortex/bin")
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.calls.read_text().splitlines()
        self.assertEqual(len(calls), 2)
        self.assertIn("--output /dev/null", calls[0])
        self.assertIn("--max-redirs 0", calls[0])
        self.assertIn("https://raw.githubusercontent.com/wilsonborba/cortex_cli/v1.2.3/scripts/install.sh", calls[1])
        self.assertEqual(
            self.installed_args.read_text().splitlines(),
            ["--version", "v1.2.3", "--dry-run", "--install-dir", "/opt/cortex/bin"],
        )
        self.assertFalse(list(self.work.glob("tmp.*")))

    def test_missing_release_fails_before_download(self) -> None:
        result = self.run_shim(FAKE_LATEST_RESPONSE="302\nhttps://github.com/wilsonborba/cortex_cli/releases")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no published stable CLI release", result.stderr)
        self.assertEqual(len(self.calls.read_text().splitlines()), 1)
        self.assertFalse(self.installed_args.exists())

    def test_untrusted_or_prerelease_redirect_is_rejected(self) -> None:
        for location in (
            "https://evil.example/releases/tag/v1.2.3",
            "https://github.com/other/repo/releases/tag/v1.2.3",
            "https://github.com/wilsonborba/cortex_cli/releases/tag/v1.2.3-rc.1",
        ):
            with self.subTest(location=location):
                self.calls.unlink(missing_ok=True)
                result = self.run_shim(FAKE_LATEST_RESPONSE=f"302\n{location}")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("no published stable CLI release", result.stderr)
                self.assertEqual(len(self.calls.read_text().splitlines()), 1)

    def test_failed_download_cleans_temp_and_never_executes_partial_installer(self) -> None:
        before = set(self.work.iterdir())
        result = self.run_shim(FAKE_DOWNLOAD_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("could not download the versioned CLI installer", result.stderr)
        self.assertFalse(self.installed_args.exists())
        self.assertEqual(set(self.work.iterdir()), before | {self.calls})

    def test_unrecognized_download_is_not_executed_and_is_cleaned(self) -> None:
        before = set(self.work.iterdir())
        result = self.run_shim(FAKE_BAD_INSTALLER="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("downloaded file is not the CLI installer", result.stderr)
        self.assertFalse(self.installed_args.exists())
        self.assertEqual(set(self.work.iterdir()), before | {self.calls})

    def test_caller_cannot_select_version_or_pass_unknown_options(self) -> None:
        for args in (("--version", "9.9.9"), ("--unknown",)):
            with self.subTest(args=args):
                self.calls.unlink(missing_ok=True)
                result = self.run_shim(*args)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(self.calls.exists())
                self.assertFalse(self.installed_args.exists())


if __name__ == "__main__":
    unittest.main()
