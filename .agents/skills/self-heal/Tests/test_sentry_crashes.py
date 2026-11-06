import json
from pathlib import Path
import subprocess
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "Scripts/sentry-crashes"

EVENT = {
    "groupID": "42",
    "eventID": "abc",
    "release": {"version": "com.automattic.woocommerce@26.0+26.0.0.0"},
    "contexts": {
        "os": {"name": "iOS", "version": "26.1"},
        "device": {"model": "iPhone17,1"},
    },
    "user": {"email": "merchant@example.com", "ip_address": "203.0.113.7", "username": "merchant"},
    "tags": [{"key": "user", "value": "id:123456"}],
    "entries": [
        {
            "type": "exception",
            "data": {"values": [{
                "type": "NSInvalidArgumentException",
                "value": "Bad product \"Blue Mug\" at https://shop.example.com/p?id=98765 for merchant@example.com",
                "mechanism": {"type": "nsexception", "handled": False},
            }]},
        },
        {
            "type": "threads",
            "data": {"values": [
                {"crashed": False, "stacktrace": {"frames": [{"function": "idle"}]}},
                {"crashed": True, "stacktrace": {"frames": [
                    {"package": "/usr/lib/libobjc.A.dylib", "function": "objc_exception_throw", "inApp": False},
                    {"package": "/private/var/WooCommerce.app/WooCommerce", "function": "ProductViewModel.load()",
                     "filename": "ProductViewModel.swift", "lineNo": 87, "inApp": True},
                ]}},
            ]},
        },
        {"type": "breadcrumbs", "data": {"values": [{"message": "Opened order for Jane Doe"}]}},
        {"type": "request", "data": {"url": "https://shop.example.com/wp-json"}},
    ],
}


def run(*args, stdin):
    return subprocess.run([str(SCRIPT), *args], input=stdin, capture_output=True, text=True, check=True).stdout


class EventFilterTests(unittest.TestCase):
    def setUp(self):
        self.output = run("event-filter", stdin=json.dumps(EVENT))
        self.event = json.loads(self.output)

    def test_user_data_never_leaves_the_script(self):
        for leaked in ["merchant@example.com", "203.0.113.7", "Jane Doe", "Blue Mug", "shop.example.com", "123456", "98765"]:
            self.assertNotIn(leaked, self.output)

    def test_only_allowlisted_fields_are_kept(self):
        self.assertEqual(
            set(self.event),
            {"issueId", "eventId", "release", "os", "device", "exceptions", "crashedThread"},
        )

    def test_exception_message_keeps_its_shape(self):
        self.assertEqual(
            self.event["exceptions"][0]["value"],
            'Bad product "<string>" at <url> for <email>',
        )

    def test_crashed_thread_frames_are_ordered_from_the_crash_site(self):
        frames = self.event["crashedThread"]["frames"]
        self.assertEqual(frames[0]["function"], "ProductViewModel.load()")
        self.assertEqual(frames[0]["binary"], "WooCommerce")
        self.assertEqual(frames[0]["lineNo"], 87)


class RedactTests(unittest.TestCase):
    def test_redacts_free_text_placeholders(self):
        output = run("redact", stdin="'Ann' 10.0.0.1 1234 3fa85f64-5717-4562-b3fc-2c963f66afa6 Code 28\n")
        self.assertEqual(output.strip(), "'<string>' <ip> <number> <uuid> Code 28")


if __name__ == "__main__":
    unittest.main()
