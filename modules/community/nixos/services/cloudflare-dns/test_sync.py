import importlib.util
import pathlib
import unittest

spec = importlib.util.spec_from_file_location("cloudflare_sync", pathlib.Path(__file__).with_name("sync.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ReconcileTest(unittest.TestCase):
    def run_sync(self, existing):
        calls = []
        def request(method, path, data=None):
            calls.append((method, path, data))
            return existing if method == "GET" else {}
        module.request = request
        record = {"name": "prometheus.example.com", "type": "CNAME", "content": "gateway.example.com", "ttl": 300, "proxied": False}
        module.sync({"zoneId": "zone", "records": [record]})
        return calls, record

    def test_creates_only_the_declared_record(self):
        calls, record = self.run_sync([])
        self.assertEqual(calls[-1], ("POST", "zones/zone/dns_records", record))
        self.assertIn("name=prometheus.example.com", calls[0][1])

    def test_leaves_matching_record_untouched(self):
        old = {"id": "existing", "name": "prometheus.example.com", "type": "CNAME", "content": "gateway.example.com", "ttl": 300, "proxied": False}
        calls, _ = self.run_sync([old])
        self.assertEqual(len(calls), 1)

    def test_refuses_conflicting_types(self):
        with self.assertRaisesRegex(RuntimeError, "different record type"):
            self.run_sync([{"type": "A"}])

    def test_refuses_multiple_records(self):
        with self.assertRaisesRegex(RuntimeError, "Multiple records"):
            self.run_sync([{}, {}])


if __name__ == "__main__":
    unittest.main()
