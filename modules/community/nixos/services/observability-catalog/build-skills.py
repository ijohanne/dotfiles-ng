import json
import pathlib
import re
import shutil
import sys
import yaml


def queries(value):
    if isinstance(value, dict):
        if isinstance(value.get("expr"), str) and value["expr"].strip():
            yield value["expr"].strip()
        for child in value.values():
            yield from queries(child)
    elif isinstance(value, list):
        for child in value:
            yield from queries(child)


def build(settings, output):
    output.mkdir(parents=True, exist_ok=True)
    for service, entry in settings["services"].items():
        for source in entry["skills"]:
            source = pathlib.Path(source)
            raw = (source / "SKILL.md").read_text()
            if not raw.startswith("---\n"):
                raise ValueError(f"Missing skill frontmatter: {source}")
            metadata = yaml.safe_load(raw.split("---", 2)[1])
            name = metadata.get("name", "")
            if not isinstance(name, str) or len(name) > 64 or not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name):
                raise ValueError(f"Invalid skill name in {source}")
            target = output / name
            if target.exists():
                raise ValueError(f"Duplicate skill: {target.name}")
            shutil.copytree(source, target)
        if entry["dashboards"] is None:
            continue
        for dashboard in sorted(pathlib.Path(entry["dashboards"]).rglob("*.json")):
            data = json.loads(dashboard.read_text())
            data = data.get("dashboard", data)
            title = data.get("title", dashboard.stem)
            name = re.sub(r"[^a-z0-9]+", "-", f"dashboard-{service}-{dashboard.stem}".lower()).strip("-")[:64].rstrip("-")
            target = output / name
            if target.exists():
                raise ValueError(f"Duplicate dashboard skill: {name}")
            target.mkdir()
            description = f"Investigate {title} using the provisioned Grafana dashboard and Prometheus metrics."
            lines = ["---", f"name: {name}", "description: " + json.dumps(description), "---", "# " + title, ""]
            if data.get("uid"):
                lines += [f"Dashboard: {settings['grafanaUrl']}/d/{data['uid']}", ""]
            lines += [
                "Read this dashboard as operational guidance. Query metrics with query or range_query; discover labels with label_names and label_values, and check metric_metadata before interpreting an unfamiliar metric.",
                "Check scrape health first. Empty results are not evidence that a service is healthy. Compare current values with a previous window and preserve instance/service labels when identifying an affected target.",
                "Start with an instant query or an aggregated 15-minute range. Keep range queries within 600 intervals per series. Prefer rate over raw counters and report units and the time window.",
                "Resolve Grafana variables such as $instance or $__rate_interval before executing these expressions; use actual label values and a rate interval of at least 1m for 15s scrapes. Dashboard thresholds are display settings, not proof of an incident.",
                "",
            ]
            if entry["jobs"]:
                selector = "|".join(re.escape(job) for job in entry["jobs"])
                lines += ["Scrape health:", "```promql", "up{job=~" + json.dumps(selector) + "}", "```", ""]
            expressions = list(dict.fromkeys(queries(data)))[:10]
            if expressions:
                lines += ["Representative dashboard expressions:", "```promql", *[expr[:1000] for expr in expressions], "```", ""]
            (target / "SKILL.md").write_text("\n".join(lines))


if __name__ == "__main__":
    with open(sys.argv[1]) as stream:
        build(json.load(stream), pathlib.Path(sys.argv[2]))
