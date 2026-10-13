"""App Store Connect: статус версии и отправка на проверку через API-ключ.

  python asc_release.py status              — только чтение, печатает состояние
  python asc_release.py submit <версия>     — привязывает последнюю собранную сборку,
                                              отправляет версию на проверку Apple
Секреты берутся из окружения: APPSTORE_KEY_ID, APPSTORE_ISSUER_ID, APPSTORE_API_KEY_BASE64.
"""
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request

import jwt  # pip install pyjwt cryptography

BUNDLE_ID = "com.samvel.armenianbible"
API = "https://api.appstoreconnect.apple.com"


def token():
    key = base64.b64decode(os.environ["APPSTORE_API_KEY_BASE64"]).decode()
    now = int(time.time())
    return jwt.encode(
        {"iss": os.environ["APPSTORE_ISSUER_ID"], "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
        key,
        algorithm="ES256",
        headers={"kid": os.environ["APPSTORE_KEY_ID"], "typ": "JWT"},
    )


TOKEN = token()


def call(method, path, body=None):
    req = urllib.request.Request(
        API + path if path.startswith("/") else path,
        method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        detail = e.read().decode()
        print(f"HTTP {e.code} {method} {path}\n{detail}", file=sys.stderr)
        raise SystemExit(1)


def app_id():
    d = call("GET", f"/v1/apps?filter[bundleId]={BUNDLE_ID}")
    return d["data"][0]["id"]


def versions(aid):
    d = call("GET", f"/v1/apps/{aid}/appStoreVersions?limit=10&fields[appStoreVersions]=versionString,appStoreState,releaseType,platform,createdDate")
    return d["data"]


def builds(aid):
    d = call("GET", f"/v1/builds?filter[app]={aid}&sort=-uploadedDate&limit=10&include=preReleaseVersion"
                    "&fields[builds]=version,processingState,uploadedDate,expired,usesNonExemptEncryption,preReleaseVersion"
                    "&fields[preReleaseVersions]=version")
    pre = {i["id"]: i["attributes"]["version"] for i in d.get("included", [])}
    out = []
    for b in d["data"]:
        pid = (b["relationships"]["preReleaseVersion"]["data"] or {}).get("id")
        out.append({
            "id": b["id"], "build": b["attributes"]["version"], "marketing": pre.get(pid),
            "state": b["attributes"]["processingState"], "uploaded": b["attributes"]["uploadedDate"],
            "expired": b["attributes"]["expired"], "encryptionDeclared": b["attributes"].get("usesNonExemptEncryption"),
        })
    return out


def status():
    aid = app_id()
    print("app id:", aid)
    vs = versions(aid)
    print("\nVERSIONS")
    for v in vs:
        a = v["attributes"]
        print(f"  {a['versionString']:8} {a['appStoreState']:28} release={a.get('releaseType')} id={v['id']}")
    print("\nBUILDS (новые сверху)")
    for b in builds(aid):
        print("  ", b)
    editable = [v for v in vs if v["attributes"]["appStoreState"] in
                ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED", "INVALID_BINARY")]
    for v in editable:
        vid = v["id"]
        cur = call("GET", f"/v1/appStoreVersions/{vid}/build")
        print(f"\nVERSION {v['attributes']['versionString']}: привязанная сборка ->", (cur.get("data") or {}).get("id"))
        locs = call("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations?fields[appStoreVersionLocalizations]=locale,whatsNew,description")
        for l in locs["data"]:
            wn = (l["attributes"].get("whatsNew") or "").replace("\n", " ")[:140]
            print(f"  [{l['attributes']['locale']}] whatsNew: {wn!r}")
    info = call("GET", f"/v1/apps/{aid}/appInfos")
    for i in info["data"]:
        print("\nappInfo state:", i["attributes"].get("appStoreState"))


def submit(version):
    aid = app_id()
    vs = versions(aid)
    target = next((v for v in vs if v["attributes"]["versionString"] == version), None)
    if target is None:
        print(f"версии {version} нет, создаю")
        target = call("POST", "/v1/appStoreVersions", {"data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": version, "releaseType": "MANUAL"},
            "relationships": {"app": {"data": {"type": "apps", "id": aid}}}}})["data"]
    state = target["attributes"]["appStoreState"] if "attributes" in target else "?"
    print("версия", version, "состояние:", state)
    vid = target["id"]

    ready = [b for b in builds(aid) if b["marketing"] == version and b["state"] == "VALID" and not b["expired"]]
    if not ready:
        print("Нет готовой (VALID) сборки для версии", version, file=sys.stderr)
        raise SystemExit(1)
    best = max(ready, key=lambda b: int(b["build"]))
    print("привязываю сборку", best["build"], best["id"])
    call("PATCH", f"/v1/appStoreVersions/{vid}/relationships/build",
         {"data": {"type": "builds", "id": best["id"]}})
    if best["encryptionDeclared"] is None:
        call("PATCH", f"/v1/builds/{best['id']}", {"data": {"type": "builds", "id": best["id"],
                                                             "attributes": {"usesNonExemptEncryption": False}}})

    sub = call("POST", "/v1/reviewSubmissions", {"data": {
        "type": "reviewSubmissions", "attributes": {"platform": "IOS"},
        "relationships": {"app": {"data": {"type": "apps", "id": aid}}}}})["data"]
    call("POST", "/v1/reviewSubmissionItems", {"data": {
        "type": "reviewSubmissionItems",
        "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub["id"]}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
    done = call("PATCH", f"/v1/reviewSubmissions/{sub['id']}",
                {"data": {"type": "reviewSubmissions", "id": sub["id"], "attributes": {"submitted": True}}})
    print("отправлено на проверку:", done["data"]["attributes"].get("state"), done["data"]["id"])


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    if cmd == "status":
        status()
    elif cmd == "submit":
        submit(sys.argv[2])
    else:
        raise SystemExit("usage: status | submit <version>")
