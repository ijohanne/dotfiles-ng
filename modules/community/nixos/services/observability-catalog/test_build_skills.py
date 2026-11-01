import importlib.util
import json
import pathlib
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("build_skills", pathlib.Path(__file__).with_name("build-skills.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class CatalogTest(unittest.TestCase):
    def test_store_paths_preserve_the_declared_skill_name(self):
        with tempfile.TemporaryDirectory() as root:
            root = pathlib.Path(root)
            source = root / "nixhash-check-example"
            source.mkdir()
            (source / "SKILL.md").write_text("---\nname: check-example\ndescription: Check example.\n---\n# Example\n")
            dashboards = root / "dashboards"
            dashboards.mkdir()
            (dashboards / "overview.json").write_text(json.dumps({"title": "Example", "uid": "example", "panels": [{"targets": [{"expr": "up{job=\"example\"}"}]}]}))
            settings = {"grafanaUrl": "https://grafana.example", "services": {"example": {"skills": [str(source)], "dashboards": str(dashboards), "jobs": ["example"]}}}
            output = root / "output"
            module.build(settings, output)
            self.assertTrue((output / "check-example" / "SKILL.md").exists())
            generated = (output / "dashboard-example-overview" / "SKILL.md").read_text()
            self.assertIn("https://grafana.example/d/example", generated)
            self.assertIn('up{job="example"}', generated)
            with self.assertRaisesRegex(ValueError, "Duplicate skill"):
                module.build(settings, output)


if __name__ == "__main__":
    unittest.main()
