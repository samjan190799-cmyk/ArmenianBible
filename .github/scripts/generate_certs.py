#!/usr/bin/env python3
"""
Автономная генерация Apple Distribution Certificate и Provisioning Profile.
Запускается из GitHub Actions на macOS runner.
Требует env переменных: APPSTORE_KEY_ID, APPSTORE_ISSUER_ID, APPSTORE_API_KEY_BASE64
"""
import os, time, base64, json, subprocess, sys
from pathlib import Path

try:
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import ec, rsa
    from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
    from cryptography import x509
    from cryptography.x509.oid import NameOID
    import urllib.request
    import urllib.error
except ImportError:
    subprocess.run([sys.executable, "-m", "pip", "install", "cryptography"], check=True)
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import ec, rsa
    from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
    from cryptography import x509
    from cryptography.x509.oid import NameOID
    import urllib.request
    import urllib.error

key_id      = os.environ["APPSTORE_KEY_ID"]
issuer_id   = os.environ["APPSTORE_ISSUER_ID"]
api_key_b64 = os.environ["APPSTORE_API_KEY_BASE64"]
runner_tmp  = os.environ.get("RUNNER_TEMP", "/tmp")
github_env  = os.environ["GITHUB_ENV"]

# 1. Разворачиваем ASC API ключ
api_key_path = Path(runner_tmp) / f"AuthKey_{key_id}.p8"
api_key_path.write_bytes(base64.b64decode(api_key_b64))
print(f"[1/6] ASC API ключ сохранён: {api_key_path}")

# 2. JWT генерация (ES256 R||S формат)
def make_jwt():
    with open(api_key_path, "rb") as f:
        pk = serialization.load_pem_private_key(f.read(), password=None)
    hdr = {"alg": "ES256", "kid": key_id}
    pld = {"iss": issuer_id, "iat": int(time.time()), "exp": int(time.time()) + 1100, "aud": "appstoreconnect-v1"}
    def b64u(d):
        if isinstance(d, str): d = d.encode()
        return base64.urlsafe_b64encode(d).rstrip(b"=").decode()
    h = b64u(json.dumps(hdr, separators=(",", ":")))
    p = b64u(json.dumps(pld, separators=(",", ":")))
    sig_der = pk.sign(f"{h}.{p}".encode(), ec.ECDSA(hashes.SHA256()))
    r, s = decode_dss_signature(sig_der)
    return f"{h}.{p}.{b64u(r.to_bytes(32,'big') + s.to_bytes(32,'big'))}"

def api(method, path, body=None):
    jwt = make_jwt()
    req = urllib.request.Request(
        f"https://api.appstoreconnect.apple.com/v1{path}",
        data=json.dumps(body).encode() if body else None,
        headers={"Authorization": f"Bearer {jwt}", "Content-Type": "application/json"},
        method=method
    )
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        err = json.loads(e.read())
        print(f"API Error {e.code}: {json.dumps(err, indent=2)}")
        raise

# 3. Генерируем RSA ключ + CSR
print("[2/6] Генерация приватного ключа и CSR...")
dist_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
dist_key_path = Path(runner_tmp) / "dist_private.pem"
dist_key_path.write_bytes(dist_key.private_bytes(
    serialization.Encoding.PEM,
    serialization.PrivateFormat.TraditionalOpenSSL,
    serialization.NoEncryption()
))
csr = (
    x509.CertificateSigningRequestBuilder()
    .subject_name(x509.Name([
        x509.NameAttribute(NameOID.COMMON_NAME, "Samvel Hayrapetyan"),
        x509.NameAttribute(NameOID.EMAIL_ADDRESS, "samvel@example.com"),
        x509.NameAttribute(NameOID.COUNTRY_NAME, "US"),
    ]))
    .sign(dist_key, hashes.SHA256())
)
csr_b64 = base64.b64encode(csr.public_bytes(serialization.Encoding.DER)).decode()
print("[2/6] CSR готов")

# 4. Создаём Distribution Certificate
print("[3/6] Создание Distribution Certificate через Apple API...")
cert_id = None
cert_content = None
try:
    resp = api("POST", "/certificates", {
        "data": {
            "type": "certificates",
            "attributes": {"certificateType": "IOS_DISTRIBUTION", "csrContent": csr_b64}
        }
    })
    cert_id = resp["data"]["id"]
    cert_content = resp["data"]["attributes"]["certificateContent"]
    print(f"[3/6] Сертификат создан, ID: {cert_id}")
except Exception as e:
    print(f"[3/6] Создание не удалось ({e}), ищем существующий...")
    certs = api("GET", "/certificates?filter[certificateType]=IOS_DISTRIBUTION&limit=1")
    if not certs.get("data"):
        print("ОШИБКА: Нет Distribution сертификатов!")
        sys.exit(1)
    cert_id = certs["data"][0]["id"]
    cert_content = certs["data"][0]["attributes"]["certificateContent"]
    # Нам нужен ключ из secrets если переиспользуем старый cert
    print(f"[3/6] Используем существующий сертификат ID: {cert_id}")
    print("ПРЕДУПРЕЖДЕНИЕ: Используется существующий cert без приватного ключа!")
    print("Для правильной подписи необходимо создать новый сертификат.")

# Сохраняем .cer
cer_path = Path(runner_tmp) / "distribution.cer"
cer_path.write_bytes(base64.b64decode(cert_content))

# Конвертируем в PEM
pem_path = Path(runner_tmp) / "distribution.pem"
subprocess.run(["openssl", "x509", "-inform", "DER", "-in", str(cer_path), "-out", str(pem_path)], check=True)

# Создаём .p12
p12_password = "ArmenianBibleCI2026"
p12_path = Path(runner_tmp) / "distribution.p12"
ret = subprocess.run(
    ["openssl", "pkcs12", "-export", "-inkey", str(dist_key_path),
     "-in", str(pem_path), "-out", str(p12_path), "-passout", f"pass:{p12_password}", "-legacy"],
    capture_output=True
)
if ret.returncode != 0:
    subprocess.run(
        ["openssl", "pkcs12", "-export", "-inkey", str(dist_key_path),
         "-in", str(pem_path), "-out", str(p12_path), "-passout", f"pass:{p12_password}"],
        check=True
    )
print(f"[4/6] .p12 создан (пароль: {p12_password})")

# 5. Получаем Bundle ID
print("[5/6] Поиск Bundle ID com.samvel.armenianbible...")
bundles = api("GET", "/bundleIds?filter[identifier]=com.samvel.armenianbible")
if not bundles.get("data"):
    print("ОШИБКА: Bundle ID com.samvel.armenianbible не зарегистрирован в Apple Developer!")
    sys.exit(1)
bundle_id = bundles["data"][0]["id"]
print(f"[5/6] Bundle ID найден: {bundle_id}")

# 6. Получаем/создаём Provisioning Profile
print("[6/6] Provisioning Profile...")
profiles = api("GET", f"/profiles?filter[profileType]=IOS_APP_STORE&filter[bundleId]={bundle_id}")
pp_content = None
for p_item in profiles.get("data", []):
    if p_item["attributes"].get("profileState") == "ACTIVE":
        pp_content = p_item["attributes"]["profileContent"]
        print(f"[6/6] Используем профиль: {p_item['attributes']['name']}")
        break

if not pp_content:
    prof = api("POST", "/profiles", {
        "data": {
            "type": "profiles",
            "attributes": {"name": "ArmenianBible_CI_AppStore", "profileType": "IOS_APP_STORE"},
            "relationships": {
                "bundleId": {"data": {"type": "bundleIds", "id": bundle_id}},
                "certificates": {"data": [{"type": "certificates", "id": cert_id}]}
            }
        }
    })
    pp_content = prof["data"]["attributes"]["profileContent"]
    print(f"[6/6] Профиль создан: {prof['data']['attributes']['name']}")

pp_path = Path(runner_tmp) / "app_store.mobileprovision"
pp_path.write_bytes(base64.b64decode(pp_content))

# Записываем в GITHUB_ENV
with open(github_env, "a") as f:
    f.write(f"DIST_P12_PATH={p12_path}\n")
    f.write(f"DIST_P12_PASSWORD={p12_password}\n")
    f.write(f"PP_PATH={pp_path}\n")
    f.write(f"AUTH_KEY_PATH={api_key_path}\n")
    f.write(f"APPSTORE_KEY_ID={key_id}\n")
    f.write(f"APPSTORE_ISSUER_ID={issuer_id}\n")

# Сохраняем для артефакта
out = Path(runner_tmp) / "secrets_output"
out.mkdir(exist_ok=True)
p12_b64 = base64.b64encode(p12_path.read_bytes()).decode()
pp_b64  = base64.b64encode(pp_path.read_bytes()).decode()
(out / "BUILD_CERTIFICATE_BASE64.txt").write_text(p12_b64)
(out / "P12_PASSWORD.txt").write_text(p12_password)
(out / "PROVISIONING_PROFILE_BASE64.txt").write_text(pp_b64)

print("\n" + "="*60)
print("ГОТОВО! Все файлы подготовлены для подписи.")
print("="*60)
