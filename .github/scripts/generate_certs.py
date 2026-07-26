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
    import jwt
    import urllib.request
    import urllib.error
except ImportError:
    subprocess.run([sys.executable, "-m", "pip", "install", "--break-system-packages", "cryptography", "pyjwt", "pyjwt[crypto]"], check=True)
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import ec, rsa
    from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
    from cryptography import x509
    from cryptography.x509.oid import NameOID
    import jwt
    import urllib.request
    import urllib.error

def get_env_var(keys, name_for_err):
    for k in keys:
        val = os.environ.get(k, "").strip()
        if val:
            return val
    print(f"\n{'='*60}")
    print(f"❌ ОШИБКА: Переменная {name_for_err} не найдена или пустая!")
    print("="*60)
    print("Проверены секреты/переменные:", ", ".join(keys))
    print("Убедитесь, что в GitHub Repository Settings -> Secrets and variables -> Actions")
    print(f"задан секрет {keys[0]} (или один из альтернативных).")
    print("="*60)
    sys.exit(1)

key_id      = get_env_var(["APPSTORE_KEY_ID", "APP_STORE_CONNECT_KEY_ID", "APP_STORE_KEY_ID", "KEY_ID", "APPSTORE_KEYID"], "Key ID").strip()
issuer_id   = get_env_var(["APPSTORE_ISSUER_ID", "APP_STORE_CONNECT_ISSUER_ID", "APP_STORE_ISSUER_ID", "ISSUER_ID", "APPSTORE_ISSUERID"], "Issuer ID").strip()
api_key_b64 = get_env_var(["APPSTORE_API_KEY_BASE64", "APP_STORE_CONNECT_API_KEY_BASE64", "APPSTORE_KEY_BASE64", "APP_STORE_KEY_BASE64", "P8_BASE64", "P8_KEY", "APPSTORE_API_KEY", "APPSTORE_PRIVATE_KEY"], "API Key Base64").strip()

runner_tmp  = os.environ.get("RUNNER_TEMP", "/tmp")
github_env  = os.environ.get("GITHUB_ENV", "/tmp/env")
out_dir     = Path(runner_tmp) / "secrets_output"
out_dir.mkdir(exist_ok=True)
log_file    = out_dir / "cert_log.txt"

class Logger:
    def __init__(self, filepath):
        self.terminal = sys.stdout
        self.log = open(filepath, "w", encoding="utf-8")
    def write(self, message):
        self.terminal.write(message)
        self.log.write(message)
        self.log.flush()
    def flush(self):
        self.terminal.flush()
        self.log.flush()

sys.stdout = Logger(log_file)
sys.stderr = Logger(log_file)

# 1. Разворачиваем ASC API ключ
api_key_bytes = base64.b64decode(api_key_b64)
api_key_text  = api_key_bytes.decode("utf-8", errors="ignore").strip()

# Если в закодированной строке не было PEM заголовка — добавим нормализацию
if "-----BEGIN PRIVATE KEY-----" not in api_key_text:
    print("⚠️ PEM заголовок не найден в текстеключа. Добавляем стандартное обрамление PKCS#8...")
    clean_body = "".join(api_key_text.split())
    api_key_text = f"-----BEGIN PRIVATE KEY-----\n{clean_body}\n-----END PRIVATE KEY-----"

api_key_path = Path(runner_tmp) / f"AuthKey_{key_id}.p8"
api_key_path.write_text(api_key_text, encoding="utf-8")

first_few_chars = api_key_text[:30].replace('\n', ' ')
print(f"[1/6] ASC API ключ сохранён: {api_key_path}")
print(f"      - Key ID: {key_id[:3]}*** (длина: {len(key_id)})")
print(f"      - Issuer ID: {issuer_id[:4]}*** (длина: {len(issuer_id)})")
print(f"      - Начало файла ключа: {first_few_chars}...")

# 2. Эталонная JWT генерация через PyJWT (ES256)
def make_jwt():
    now = int(time.time())
    headers = {
        "alg": "ES256",
        "kid": key_id,
        "typ": "JWT"
    }
    payload = {
        "iss": issuer_id,
        "iat": now,
        "exp": now + 1100,
        "aud": "appstoreconnect-v1"
    }
    
    with open(api_key_path, "rb") as f:
        private_key = serialization.load_pem_private_key(f.read(), password=None)
    
    token = jwt.encode(payload, private_key, algorithm="ES256", headers=headers)
    if isinstance(token, bytes):
        token = token.decode("utf-8")
    return token.strip()

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
        err_body = e.read().decode("utf-8", errors="ignore")
        print(f"::error::Apple API Error {e.code} on {method} {path}: {err_body}")
        try:
            err = json.loads(err_body)
            print(f"API Error Details: {json.dumps(err, indent=2)}")
        except Exception:
            pass
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

def try_create_cert():
    resp = api("POST", "/certificates", {
        "data": {
            "type": "certificates",
            "attributes": {"certificateType": "IOS_DISTRIBUTION", "csrContent": csr_b64}
        }
    })
    return resp["data"]["id"], resp["data"]["attributes"]["certificateContent"]

try:
    cert_id, cert_content = try_create_cert()
    print(f"[3/6] Новый сертификат успешно создан, ID: {cert_id}")
except Exception as e:
    print(f"[3/6] Первичная попытка создания не удалась: {e}")
    print("[3/6] Проверяем существующие сертификаты для освобождения слота...")
    try:
        old_certs = api("GET", "/certificates?filter[certificateType]=IOS_DISTRIBUTION")
        if old_certs.get("data"):
            for old in old_certs["data"]:
                old_id = old["id"]
                old_name = old["attributes"].get("displayName", old_id)
                print(f"[3/6] Отображаем/отзываем устаревший сертификат ID: {old_id} ({old_name})...")
                try:
                    api("DELETE", f"/certificates/{old_id}")
                    print(f"✅ Старый сертификат {old_id} успешно отозван!")
                except Exception as del_err:
                    print(f"⚠️ Не удалось отозвать {old_id}: {del_err}")
            
            # Повторная попытка после отзыва
            print("[3/6] Повторная попытка создания сертификата...")
            cert_id, cert_content = try_create_cert()
            print(f"✅ Новый сертификат создан после отзыва старых, ID: {cert_id}")
        else:
            raise e
    except Exception as retry_err:
        print(f"\n{'='*60}")
        print(f"❌ Не удалось создать Distribution сертификат: {retry_err}")
        print("="*60)
        sys.exit(1)

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
