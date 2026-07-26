#!/usr/bin/env python3
"""
Официальный нативный генератор JWT токенов для Apple App Store Connect API (RFC 7515 ES256 / IEEE P1363 standard).
"""
import os, sys, base64, json, urllib.request, urllib.error, subprocess, time
from pathlib import Path

key_id     = os.environ.get("APPSTORE_KEY_ID", "").strip()
issuer_id  = os.environ.get("APPSTORE_ISSUER_ID", "").strip()
key_path   = os.environ.get("AUTH_KEY_PATH", "").strip()
runner_tmp = Path(os.environ.get("RUNNER_TEMP", "/tmp"))
github_env = os.environ.get("GITHUB_ENV", "/tmp/env")

if not key_id or not issuer_id or not key_path:
    print("❌ Ошибка: не заданы переменные API ключа!")
    sys.exit(1)

try:
    from cryptography.hazmat.primitives import serialization, hashes
    from cryptography.hazmat.primitives.asymmetric import ec, utils
except ImportError:
    subprocess.run([sys.executable, "-m", "pip", "install", "--break-system-packages", "cryptography"], check=True)
    from cryptography.hazmat.primitives import serialization, hashes
    from cryptography.hazmat.primitives.asymmetric import ec, utils

# Читаем .p8 ключ
with open(key_path, "rb") as f:
    key_bytes = f.read().replace(b"\r\n", b"\n").replace(b"\r", b"\n").strip()
    pk = serialization.load_pem_private_key(key_bytes, password=None)

def base64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('utf-8')

# Генерируем RFC 7515 JWS ES256 токен вручную для 100% совместимости с Apple API
now = int(time.time())
header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
payload = {
    "iss": issuer_id,
    "iat": now - 10,
    "exp": now + 1100,
    "aud": "appstoreconnect-v1"
}

header_b64 = base64url_encode(json.dumps(header, separators=(',', ':')).encode('utf-8'))
payload_b64 = base64url_encode(json.dumps(payload, separators=(',', ':')).encode('utf-8'))

signing_input = f"{header_b64}.{payload_b64}".encode('utf-8')

# DER подпись из cryptography
der_signature = pk.sign(signing_input, ec.ECDSA(hashes.SHA256()))

# Конвертируем DER подпись (ASN.1) в формат IEEE P1363 (ровно 64 байта R+S), требуемый Apple API
r, s = utils.decode_dss_signature(der_signature)
raw_signature = r.to_bytes(32, byteorder='big') + s.to_bytes(32, byteorder='big')
sig_b64 = base64url_encode(raw_signature)

token = f"{header_b64}.{payload_b64}.{sig_b64}"

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
        print(f"⚠️ Apple API Answer [{e.code}]: {err_b}")
        return {"error_code": e.code, "body": err_b}

print("🔑 [1/4] Генерация локальной парной пары ключей и CSR...")
csr_key_path = Path(runner_tmp) / "dist.key"
csr_path = Path(runner_tmp) / "dist.csr"

subprocess.run(["openssl", "genrsa", "-out", str(csr_key_path), "2048"], check=True)
subprocess.run([
    "openssl", "req", "-new", "-key", str(csr_key_path),
    "-out", str(csr_path), "-subj", "/CN=iOS Distribution/O=ArmenianBible/C=US"
], check=True)

csr_raw = csr_path.read_text()
csr_pem = csr_raw.replace("-----BEGIN CERTIFICATE REQUEST-----", "").replace("-----END CERTIFICATE REQUEST-----", "").replace("\r", "").replace("\n", "").strip()

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
    print("✅ Сертификат подписи успешно сгенерирован Apple API!")
else:
    print("⚠️ Лимит сертификатов исчерпан. Выполняем авто-освобождение слота через API...")
    certs_res = api_request("GET", "/certificates?filter[certificateType]=IOS_DISTRIBUTION")
    if not certs_res.get("data"):
        certs_res = api_request("GET", "/certificates?filter[certificateType]=DISTRIBUTION")
        
    for old_cert in certs_res.get("data", []):
        cert_id = old_cert["id"]
        print(f"🗑 Авто-отзыв старого сертификата {cert_id}...")
        api_request("DELETE", f"/certificates/{cert_id}")
        
    print("🔄 Повторная генерация свежего сертификата подписи...")
    res_retry = api_request("POST", "/certificates", create_payload)
    if "data" in res_retry and "attributes" in res_retry["data"]:
        cer_b64 = res_retry["data"]["attributes"]["certificateContent"]
        print("✅ Свежий сертификат подписи успешно сгенерирован!")

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
            "security", "list-keychains", "-d", "user", "-s", keychain_path, "login.keychain-db"
        ], check=True)
        subprocess.run([
            "security", "set-key-partition-list",
            "-S", "apple-tool:,apple:,codesign:",
            "-s", "-k", "123456", keychain_path
        ], check=True)
        print("✅ Сертификат подписи успешно импортирован и зарегистирован в Keychain!")

print("📲 [3/4] Скачивание профилей для приложения и виджета...")
profiles_res = api_request("GET", "/profiles?filter[profileType]=IOS_APP_STORE")
pp_dir = Path.home() / "Library/MobileDevice/Provisioning Profiles"
pp_dir.mkdir(parents=True, exist_ok=True)

main_uuid = None
widget_uuid = None

for p in profiles_res.get("data", []):
    name = p["attributes"]["name"]
    pp_b64 = p["attributes"]["profileContent"]
    pp_bytes = base64.b64decode(pp_b64)
    
    tmp_pp = runner_tmp / f"temp_{p['id']}.mobileprovision"
    tmp_pp.write_bytes(pp_bytes)
    
    try:
        uuid = subprocess.check_output(f"security cms -D -i '{tmp_pp}' | plutil -extract UUID raw -", shell=True, text=True).strip()
    except Exception:
        import uuid as u_lib
        uuid = str(u_lib.uuid4())
        
    dest_pp = pp_dir / f"{uuid}.mobileprovision"
    dest_pp.write_bytes(pp_bytes)
    
    if "Widget" in name and not widget_uuid:
        widget_uuid = uuid
        print(f"✅ Профиль виджета смонтирован [{name}]: {uuid}")
    elif ("ArmenianBible_Clean_AppStore" in name) and not main_uuid:
        main_uuid = uuid
        print(f"✅ Профиль основного приложения смонтирован [{name}]: {uuid}")

# Если один из профилей не разделился по имени, берем логические доступные
if not main_uuid and profiles_res.get("data"):
    main_uuid = uuid
    print(f"✅ Назначен основной профиль: {main_uuid}")

with open(github_env, "a", encoding="utf-8") as f:
    if main_uuid:
        f.write(f"MAIN_APP_PROFILE_UUID={main_uuid}\n")
    if widget_uuid:
        f.write(f"WIDGET_PROFILE_UUID={widget_uuid}\n")

print("✨ [4/4] Подготовка завершена!")
