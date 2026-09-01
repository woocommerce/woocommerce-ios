from __future__ import annotations

import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
MAESTRO_ROOT = REPO_ROOT / ".maestro"


class MaestroLoginContractTests(unittest.TestCase):
    def test_non_wordpress_recovery_preserves_the_entered_address(self) -> None:
        source = (MAESTRO_ROOT / "flows" / "login_not_wp_site.yaml").read_text(
            encoding="utf-8"
        )

        recovery = source.index('- tapOn: "Enter Another Store"')
        preserved_address = source.index(
            '- assertVisible:\n'
            '    id: "Site address"\n'
            '    text: "https://google.com"\n'
            '    label: "Verify the last entered site address is preserved"'
        )

        self.assertLess(recovery, preserved_address)

    def test_site_address_entry_waits_for_qr_fallback_or_legacy_form(self) -> None:
        source = (MAESTRO_ROOT / "subflows" / "open_site_address_login.yaml").read_text(
            encoding="utf-8"
        )

        chooser_wait = source.index("No computer\\? Log in with site address|Site address")
        conditional_fallback = source.index("when:", chooser_wait)
        site_address_form = source.index('id: "Site address"', conditional_fallback)

        self.assertLess(chooser_wait, conditional_fallback)
        self.assertLess(conditional_fallback, site_address_form)

    def test_login_flows_share_the_site_address_entry(self) -> None:
        flow_paths = [
            MAESTRO_ROOT / "flows" / name
            for name in (
                "login_google.yaml",
                "login_help.yaml",
                "login_no_jetpack.yaml",
                "login_not_woo_store.yaml",
                "login_not_wp_site.yaml",
                "login_wrong_account.yaml",
                "login_wrong_credentials.yaml",
            )
        ]

        for path in flow_paths:
            with self.subTest(path=path):
                source = path.read_text(encoding="utf-8")
                self.assertIn("../subflows/open_site_address_login.yaml", source)
                self.assertNotIn("Prologue Self Hosted Button", source)

        shared_login = (MAESTRO_ROOT / "subflows" / "login.yaml").read_text(encoding="utf-8")
        self.assertIn("file: open_site_address_login.yaml", shared_login)
        self.assertNotIn("Prologue Self Hosted Button", shared_login)


if __name__ == "__main__":
    unittest.main()
