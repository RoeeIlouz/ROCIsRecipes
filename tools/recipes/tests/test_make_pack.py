import gzip
import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from make_pack import build_pack, read_version  # noqa: E402


def _recipe(id_):
    return {"id": id_, "titleHe": "מתכון", "ingredients": [], "steps": [], "totalMinutes": 5}


class MakePackTest(unittest.TestCase):
    def _files(self, tmp, recipes, version="12"):
        recipes_path = Path(tmp) / "starter.json"
        recipes_path.write_text(json.dumps(recipes, ensure_ascii=False), encoding="utf-8")
        dart = Path(tmp) / "loader.dart"
        dart.write_text(f"const int kStarterVersion = {version};\n", encoding="utf-8")
        return str(recipes_path), str(dart), str(Path(tmp) / "out")

    def test_reads_the_pack_version_from_the_app_source(self):
        with tempfile.TemporaryDirectory() as tmp:
            _, dart, _ = self._files(tmp, [_recipe("a")], version="37")
            self.assertEqual(read_version(dart), 37)

    def test_a_missing_version_is_an_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            dart = Path(tmp) / "x.dart"
            dart.write_text("nothing here", encoding="utf-8")
            with self.assertRaises(ValueError):
                read_version(str(dart))

    def test_manifest_describes_the_published_bytes(self):
        with tempfile.TemporaryDirectory() as tmp:
            recipes, dart, out = self._files(tmp, [_recipe("a"), _recipe("b")], version="9")
            manifest = build_pack(recipes, dart, out)
            pack = (Path(out) / "recipes.json.gz").read_bytes()
            self.assertEqual(manifest["version"], 9)
            self.assertEqual(manifest["count"], 2)
            self.assertEqual(manifest["sha256"], hashlib.sha256(pack).hexdigest())
            self.assertEqual(manifest["bytes"], len(pack))
            self.assertEqual(
                [r["id"] for r in json.loads(gzip.decompress(pack).decode("utf-8"))], ["a", "b"]
            )
            on_disk = json.loads((Path(out) / "recipes_manifest.json").read_text(encoding="utf-8"))
            self.assertEqual(on_disk, manifest)

    def test_the_same_recipes_always_give_the_same_bytes(self):
        with tempfile.TemporaryDirectory() as tmp:
            recipes, dart, out = self._files(tmp, [_recipe("a")])
            first = build_pack(recipes, dart, out)["sha256"]
            second = build_pack(recipes, dart, out)["sha256"]
            self.assertEqual(first, second)

    def test_an_empty_or_duplicated_pack_is_never_published(self):
        with tempfile.TemporaryDirectory() as tmp:
            recipes, dart, out = self._files(tmp, [])
            with self.assertRaises(ValueError):
                build_pack(recipes, dart, out)
        with tempfile.TemporaryDirectory() as tmp:
            recipes, dart, out = self._files(tmp, [_recipe("a"), _recipe("a")])
            with self.assertRaises(ValueError):
                build_pack(recipes, dart, out)


if __name__ == "__main__":
    unittest.main()
