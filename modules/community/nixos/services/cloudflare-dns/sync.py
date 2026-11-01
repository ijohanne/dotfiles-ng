import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request


def request(method, path, data=None):
    token = os.environ.get("CLOUDFLARE_DNS_API_TOKEN") or os.environ.get("CF_DNS_API_TOKEN")
    if not token:
        raise RuntimeError("Cloudflare DNS API token is missing")
    headers = {"Authorization": "Bearer " + token, "Content-Type": "application/json"}
    req = urllib.request.Request(
        "https://api.cloudflare.com/client/v4/" + path,
        data=None if data is None else json.dumps(data).encode(),
        headers=headers,
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            result = json.load(response)
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"Cloudflare returned HTTP {error.code}") from None
    if not result.get("success"):
        raise RuntimeError("Cloudflare rejected the DNS operation")
    return result["result"]


def sync(config):
    for record in config["records"]:
        path = f"zones/{config['zoneId']}/dns_records"
        existing = request("GET", path + "?" + urllib.parse.urlencode({"name": record["name"]}))
        if len(existing) > 1:
            raise RuntimeError(f"Multiple records already exist for {record['name']}")
        if existing:
            old = existing[0]
            if old["type"] != record["type"]:
                raise RuntimeError(f"Refusing to replace a different record type for {record['name']}")
            if all(old.get(key) == value for key, value in record.items()):
                print(f"Unchanged {record['name']}")
                continue
            request("PATCH", path + "/" + old["id"], record)
        else:
            request("POST", path, record)
        print(f"Reconciled {record['name']}")


if __name__ == "__main__":
    try:
        with open(sys.argv[1]) as stream:
            sync(json.load(stream))
    except (RuntimeError, urllib.error.URLError) as error:
        sys.exit(str(error))
