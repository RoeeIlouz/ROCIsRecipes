import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from build_recipes import build, merge_batches  # noqa: E402


def _recipe(id_, title="מתכון"):
    return {"id": id_, "titleHe": title, "ingredients": [], "steps": [], "totalMinutes": 5}


class MergeBatchesTest(unittest.TestCase):
    def _write(self, folder, name, recipes):
        (Path(folder) / name).write_text(json.dumps(recipes, ensure_ascii=False), encoding="utf-8")

    def test_merges_batches_in_file_name_order(self):
        with tempfile.TemporaryDirectory() as tmp:
            self._write(tmp, "batch2.json", [_recipe("b")])
            self._write(tmp, "batch1.json", [_recipe("a")])
            self.assertEqual([r["id"] for r in merge_batches(tmp)], ["a", "b"])

    def test_duplicate_ids_across_batches_are_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            self._write(tmp, "batch1.json", [_recipe("a")])
            self._write(tmp, "batch2.json", [_recipe("a")])
            with self.assertRaises(ValueError) as ctx:
                merge_batches(tmp)
            self.assertIn("a", str(ctx.exception))

    def test_ignores_files_that_are_not_batches(self):
        with tempfile.TemporaryDirectory() as tmp:
            self._write(tmp, "batch1.json", [_recipe("a")])
            (Path(tmp) / "notes.txt").write_text("x", encoding="utf-8")
            self.assertEqual(len(merge_batches(tmp)), 1)

    def test_empty_folder_is_an_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(ValueError):
                merge_batches(tmp)


class BuildTest(unittest.TestCase):
    def test_attaches_photo_credits_by_recipe_id(self):
        with tempfile.TemporaryDirectory() as tmp:
            content = Path(tmp) / "content"
            content.mkdir()
            (content / "batch1.json").write_text(json.dumps([_recipe("a"), _recipe("b")]), encoding="utf-8")
            photos = Path(tmp) / "photos.json"
            photo = {"asset": "assets/recipes/photos/a.jpg", "author": "X", "license": "CC0", "sourceUrl": "https://e.org"}
            photos.write_text(json.dumps({"a": photo}), encoding="utf-8")
            out = Path(tmp) / "starter_he.json"
            build(str(content), str(photos), str(out))
            built = {r["id"]: r for r in json.loads(out.read_text(encoding="utf-8"))}
            self.assertEqual(built["a"]["photo"], photo)
            self.assertNotIn("photo", built["b"])

    def test_works_without_a_photos_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            content = Path(tmp) / "content"
            content.mkdir()
            (content / "batch1.json").write_text(json.dumps([_recipe("a")]), encoding="utf-8")
            out = Path(tmp) / "starter_he.json"
            build(str(content), str(Path(tmp) / "missing.json"), str(out))
            self.assertEqual(len(json.loads(out.read_text(encoding="utf-8"))), 1)

    def test_output_is_byte_stable(self):
        with tempfile.TemporaryDirectory() as tmp:
            content = Path(tmp) / "content"
            content.mkdir()
            (content / "batch1.json").write_text(json.dumps([_recipe("a"), _recipe("b")]), encoding="utf-8")
            first, second = Path(tmp) / "1.json", Path(tmp) / "2.json"
            build(str(content), str(Path(tmp) / "none.json"), str(first))
            build(str(content), str(Path(tmp) / "none.json"), str(second))
            self.assertEqual(first.read_bytes(), second.read_bytes())


if __name__ == "__main__":
    unittest.main()
