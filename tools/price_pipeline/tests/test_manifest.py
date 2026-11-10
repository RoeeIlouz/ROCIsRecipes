import gzip
import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from make_manifest import build_manifest, main  # noqa: E402


def _write_snapshot(path: Path, generated_at: str = "2026-11-10") -> bytes:
    payload = json.dumps({"version": 1, "generatedAt": generated_at, "stores": []}).encode("utf-8")
    data = gzip.compress(payload)
    path.write_bytes(data)
    return data


class ManifestTest(unittest.TestCase):
    def test_manifest_has_hash_size_and_generation_date(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "snapshot.json.gz"
            data = _write_snapshot(path)
            manifest = build_manifest(str(path))
        self.assertEqual(manifest["generatedAt"], "2026-11-10")
        self.assertEqual(manifest["bytes"], len(data))
        self.assertEqual(manifest["sha256"], hashlib.sha256(data).hexdigest())

    def test_corrupt_snapshot_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "snapshot.json.gz"
            path.write_bytes(b"not gzip")
            with self.assertRaises(Exception):
                build_manifest(str(path))

    def test_snapshot_without_a_date_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "snapshot.json.gz"
            path.write_bytes(gzip.compress(b'{"version":1}'))
            with self.assertRaises(KeyError):
                build_manifest(str(path))

    def test_main_writes_the_manifest_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            snap, out = Path(tmp) / "snapshot.json.gz", Path(tmp) / "manifest.json"
            _write_snapshot(snap)
            self.assertEqual(main([str(snap), str(out)]), 0)
            self.assertEqual(json.loads(out.read_text(encoding="utf-8"))["generatedAt"], "2026-11-10")


if __name__ == "__main__":
    unittest.main()
