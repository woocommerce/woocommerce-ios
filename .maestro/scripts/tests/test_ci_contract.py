from __future__ import annotations

import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]


class MaestroCiContractTests(unittest.TestCase):
    def test_toolchain_is_configured_before_downloading_the_app(self) -> None:
        wrapper = (
            REPO_ROOT / ".buildkite" / "commands" / "run-maestro-tests.sh"
        ).read_text(encoding="utf-8")

        self.assertLess(
            wrapper.index("source .maestro/scripts/configure-toolchain.sh"),
            wrapper.index('echo "--- :package: Downloading simulator app artifact"'),
        )

    def test_phone_full_is_available_in_the_ci_wrapper(self) -> None:
        wrapper = (REPO_ROOT / ".buildkite" / "commands" / "run-maestro-tests.sh").read_text(
            encoding="utf-8"
        )

        self.assertIn("release|burst|phone-full|pos-ipad|ios-system", wrapper)
        self.assertIn("phone-full|pos-ipad|ios-system", wrapper)
        self.assertIn("runner+=(--seed)", wrapper)

    def test_scheduled_phone_full_is_non_gating(self) -> None:
        schedule = (
            REPO_ROOT / ".buildkite" / "schedules" / "maestro-smoke-burst.yml"
        ).read_text(encoding="utf-8")

        self.assertIn('MAESTRO_PROFILE: "phone-full"', schedule)
        self.assertIn('label: ":iphone: Maestro phone-full observation"', schedule)
        self.assertIn("soft_fail: true", schedule)

    def test_maestro_junit_is_sent_to_test_analytics(self) -> None:
        for path in (
            REPO_ROOT / ".buildkite" / "pipeline.yml",
            REPO_ROOT / ".buildkite" / "schedules" / "maestro-smoke-burst.yml",
        ):
            with self.subTest(path=path):
                text = path.read_text(encoding="utf-8")
                self.assertIn("${TEST_COLLECTOR}:", text)
                self.assertIn("files: build/maestro/**/report.xml", text)
                self.assertIn("BUILDKITE_ANALYTICS_TOKEN_MAESTRO_TESTS", text)


if __name__ == "__main__":
    unittest.main()
