#!/usr/bin/env python3
"""
Автоматическое создание и импорт iOS Distribution Certificate (.p12) и Provisioning Profile напрямую через App Store Connect API на GitHub Actions runner.
"""
import os, sys, base64, json, urllib.request, urllib.error, subprocess, time
from pathlib import Path

key_id     = os.environ.get("APPSTORE_KEY_ID", "").strip()
issuer_id  = os.environ.get("APPSTORE_ISSUER_ID", "").strip()
key_path   = os.environ.get("AUTH_KEY_PATH", "").strip()
runner_tmp = os.environ.get("RUNNER_TEMP", "/tmp")
github_env = os.environ.get("GITHUB_ENV", "/tmp/env")

if not key_id or not issuer_id or not key_path:
    print("❌ Ошибка: не заданы переменные API ключа!")
    sys.exit(1)

try:
    import jwt
    from cryptography.hazmat.primitives import serialization
except ImportError:
    subprocess.run([sys.executable, "-m", "pip", "install", "--break-system-packages", "pyjwt", "cryptography"], check=True)
    import jwt
    from cryptography.hazmat.primitives import serialization

# Генерируем 100% валидный JWT токен по стандарту Apple
now = int(time.time())
headers = {"kid": key_id, "typ": "JWT"}
payload = {"iss": issuer_id, "iat": now - 10, "exp": now + 1100, "aud": "appstoreconnect-v1"}

with open(key_path, "rb") as f:
    key_bytes = f.read().replace(b"\r\n", b"\n").replace(b"\r", b"\n").strip()
    pk_obj = serialization.load_pem_private_key(key_bytes, password=None)

token = jwt.encode(payload, pk_obj, algorithm="ES256", headers=headers)
if isinstance(token, bytes): token = token.decode("utf-8")
token = token.strip()

def api_request(method, path, body=None):
    url = f"https://api.appstoreconnect.apple.com/v1{path}"
    data = json.dumps(body).encode("utf-8") if body else None
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        },
        method=method
    )
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        err_b = e.read().decode("utf-8", errors="ignore")
        print(f"⚠️ API Answer [{e.code}]: {err_b}")
        return {"error_code": e.code, "body": err_b}

print("🔑 [1/4] Генерация локальной парной пары ключей и CSR...")
csr_key_path = Path(runner_tmp) / "dist.key"
csr_path = Path(runner_tmp) / "dist.csr"

subprocess.run(["openssl", "genrsa", "-out", str(csr_key_path), "2048"], check=True)
subprocess.run([
    "openssl", "req", "-new", "-key", str(csr_key_path),
    "-out", str(csr_path), "-subj", "/CN=iOS Distribution/O=ArmenianBible/C=US"
], check=True)

csr_pem = csr_path.read_text().replace("\r\n", "\n").replace("\n", "").replace("-----BEGIN CERTIFICATE REQUEST-----", "").replace("-----END CERTIFICATE REQUEST-----", "")

print("🍎 [2/4] Запрос на создание iOS Distribution сертификата в Apple...")
create_payload = {
    "data": {
        "type": "certificates",
        "attributes": {
            "certificateType": "IOS_DISTRIBUTION",
            "csrContent": csr_pem
        }
    }
}

res = api_request("POST", "/certificates", create_payload)

cer_b64 = None
if "data" in res and "attributes" in res["data"]:
    cer_b64 = res["data"]["attributes"]["certificateContent"]
    print("✅ Сертификат успешно сгенерирован Apple API!")

if cer_b64:
    # Сохраняем .cer и собираем .p12
    cer_path = Path(runner_tmp) / "dist.cer"
    p12_path = Path(runner_tmp) / "dist.p12"
    cer_path.write_bytes(base64.b64decode(cer_b64))
    
    # Собираем .p12 через openssl
    subprocess.run([
        "openssl", "x509", "-inform", "DER", "-in", str(cer_path), "-out", str(runner_tmp / "dist.pem")
    ], check=True)
    subprocess.run([
        "openssl", "pkcs12", "-export", "-out", str(p12_path),
        "-inkey", str(csr_key_path), "-in", str(runner_tmp / "dist.pem"),
        "-passout", "pass:123456"
    ], check=True)
    
    keychain_path = os.environ.get("KEYCHAIN_PATH", "")
    if keychain_path and Path(keychain_path).exists():
        print(f"🔑 Импорт .p12 сертификата в Keychain: {keychain_path}")
        subprocess.run([
            "security", "import", str(p12_path),
            "-k", keychain_path,
            "-P", "123456",
            "-A", "-T", "/usr/bin/codesign"
        ], check=True)
        subprocess.run([
            "security", "set-key-partition-list",
            "-S", "apple-tool:,apple:,codesign:",
            "-s", "-k", "123456", keychain_path
        ], check=True)
        print("✅ Сертификат подписи успешно импортирован в Keychain!")

print("📲 [3/4] Скачивание профиля ArmenianBible_AppStore_Final...")
profiles_res = api_request("GET", "/profiles?filter[profileType]=IOS_APP_STORE")
profile_data = None

for p in profiles_res.get("data", []):
    name = p["attributes"]["name"]
    if "ArmenianBible" in name or "Final" in name:
        profile_data = p
        print(f"✅ Выбран профиль: {name}")
        break

if not profile_data and profiles_res.get("data"):
    profile_data = profiles_res["data"][0]
    print(f"✅ Использован профиль: {profile_data['attributes']['name']}")

if profile_data:
    pp_b64 = profile_data["attributes"]["profileContent"]
    pp_bytes = base64.b64decode(pp_b64)
    pp_dir = Path.home() / "Library/MobileDevice/Provisioning Profiles"
    pp_dir.mkdir(parents=True, exist_ok=True)
    
    tmp_pp = Path(runner_tmp) / "temp.mobileprovision"
    tmp_pp.write_bytes(pp_bytes)
    
    try:
        uuid = subprocess.check_output(f"security cms -D -i '{tmp_pp}' | plutil -extract UUID raw -", shell=True, text=True).strip()
    except Exception:
        import uuid as u_lib
        uuid = str(u_lib.uuid4())
        
    dest_pp = pp_dir / f"{uuid}.mobileprovision"
    dest_pp.write_bytes(pp_bytes)
    print(f"✅ Профиль провижининга {uuid} смонтирован в систему!")
    
    with open(github_env, "a", encoding="utf-8") as f:
        f.write(f"PROVISIONING_PROFILE_UUID={uuid}\n")

print("✨ [4/4] Подготовка завершена!")
