#!/usr/bin/env python3
"""
Скачивание актуального App Store Provisioning Profile напрямую из App Store Connect API.
"""
import os, sys, base64, json, urllib.request, urllib.error, subprocess, time
from pathlib import Path

try:
    import jwt
except ImportError:
    subprocess.run([sys.executable, "-m", "pip", "install", "--break-system-packages", "pyjwt", "pyjwt[crypto]"], check=True)
    import jwt

key_id     = os.environ.get("APPSTORE_KEY_ID", "").strip()
issuer_id  = os.environ.get("APPSTORE_ISSUER_ID", "").strip()
key_path   = os.environ.get("AUTH_KEY_PATH", "").strip()
runner_tmp = os.environ.get("RUNNER_TEMP", "/tmp")
github_env = os.environ.get("GITHUB_ENV", "/tmp/env")

if not key_id or not issuer_id or not key_path:
    print("❌ Ошибка: не заданы переменные ключа API!")
    sys.exit(1)

# Генерируем JWT токен
now = int(time.time())
headers = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
payload = {"iss": issuer_id, "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"}

with open(key_path, "rb") as f:
    from cryptography.hazmat.primitives import serialization
    pk_obj = serialization.load_pem_private_key(f.read(), password=None)

token = jwt.encode(payload, pk_obj, algorithm="ES256", headers=headers)
if isinstance(token, bytes): token = token.decode("utf-8")

def api(method, path):
    req = urllib.request.Request(
        f"https://api.appstoreconnect.apple.com/v1{path}",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method=method
    )
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="ignore")
        print(f"::error::Apple API Error {e.code} on {method} {path}: {err_body}")
        raise

print("[1/3] Поиск Bundle ID com.samvel.armenianbible...")
bundles = api("GET", "/bundleIds?filter[identifier]=com.samvel.armenianbible")
if not bundles.get("data"):
    print("❌ Bundle ID com.samvel.armenianbible не найден в Apple Developer Portal!")
    sys.exit(1)

bundle_id = bundles["data"][0]["id"]
print(f"✅ Bundle ID найден: {bundle_id}")

print("[2/3] Запрос App Store Provisioning Profiles...")
profiles = api("GET", f"/profiles?filter[profileType]=IOS_APP_STORE&filter[bundleId]={bundle_id}")

pp_b64 = None
pp_name = None

for p in profiles.get("data", []):
    if p["attributes"].get("profileState") == "ACTIVE":
        pp_b64 = p["attributes"]["profileContent"]
        pp_name = p["attributes"]["name"]
        print(f"✅ Найден активный профиль: {pp_name}")
        break

if not pp_b64:
    print("⚠️ Активный App Store профиль не найден. Пробуем получить любой доступный...")
    if profiles.get("data"):
        pp_b64 = profiles["data"][0]["attributes"]["profileContent"]
        pp_name = profiles["data"][0]["attributes"]["name"]
        print(f"✅ Используем доступный профиль: {pp_name}")

if not pp_b64:
    print("❌ Профили провижининга отсутствуют. Убедитесь, что App Store профиль создан на developer.apple.com")
    sys.exit(1)

# Декодируем и сохраняем профиль
pp_bytes = base64.b64decode(pp_b64)
pp_dir = Path.home() / "Library/MobileDevice/Provisioning Profiles"
pp_dir.mkdir(parents=True, exist_ok=True)

# Извлекаем UUID из mobileprovision через security/plutil
tmp_pp = Path(runner_tmp) / "temp.mobileprovision"
tmp_pp.write_bytes(pp_bytes)

try:
    cmd = f"security cms -D -i '{tmp_pp}' | plutil -extract UUID raw -"
    uuid = subprocess.check_output(cmd, shell=True, text=True).strip()
except Exception:
    import uuid as uuid_lib
    uuid = str(uuid_lib.uuid4())

dest_pp = pp_dir / f"{uuid}.mobileprovision"
dest_pp.write_bytes(pp_bytes)

print(f"[3/3] Профиль установлен: {dest_pp} (UUID: {uuid})")

with open(github_env, "a", encoding="utf-8") as f:
    f.write(f"PROVISIONING_PROFILE_UUID={uuid}\n")
