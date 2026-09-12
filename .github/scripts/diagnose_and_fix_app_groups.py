#!/usr/bin/env python3
"""
Скрипт диагностики и исправления App Group и разрешений виджета BibleWidget в Apple App Store Connect API.
"""
import os, sys, base64, json, urllib.request, urllib.error, subprocess, time
from pathlib import Path

key_id     = os.environ.get("APPSTORE_KEY_ID", "").strip()
issuer_id  = os.environ.get("APPSTORE_ISSUER_ID", "").strip()
key_path   = os.environ.get("AUTH_KEY_PATH", "").strip()

if not key_id or not issuer_id or not key_path:
    print("❌ Ошибка: не заданы переменные API ключа (APPSTORE_KEY_ID, APPSTORE_ISSUER_ID, AUTH_KEY_PATH)!")
    sys.exit(1)

try:
    from cryptography.hazmat.primitives import serialization, hashes
    from cryptography.hazmat.primitives.asymmetric import ec, utils
except ImportError:
    subprocess.run([sys.executable, "-m", "pip", "install", "--break-system-packages", "cryptography"], check=True)
    from cryptography.hazmat.primitives import serialization, hashes
    from cryptography.hazmat.primitives.asymmetric import ec, utils

with open(key_path, "rb") as f:
    key_bytes = f.read().replace(b"\r\n", b"\n").replace(b"\r", b"\n").strip()
    pk = serialization.load_pem_private_key(key_bytes, password=None)

def base64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('utf-8')

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

der_signature = pk.sign(signing_input, ec.ECDSA(hashes.SHA256()))
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
            if r.status == 204:
                return {"status": "success"}
            res_content = r.read()
            if not res_content or not res_content.strip():
                return {"status": "success"}
            return json.loads(res_content)
    except urllib.error.HTTPError as e:
        err_b = e.read().decode("utf-8", errors="ignore")
        return {"error_code": e.code, "body": err_b}

def extract_entitlements_from_b64(b64_str):
    raw = base64.b64decode(b64_str)
    start = raw.find(b"<?xml")
    end = raw.find(b"</plist>")
    if start != -1 and end != -1:
        plist_str = raw[start:end+8].decode("utf-8", errors="ignore")
        ent_start = plist_str.find("<key>Entitlements</key>")
        if ent_start != -1:
            dict_start = plist_str.find("<dict>", ent_start)
            dict_end = plist_str.find("</dict>", dict_start)
            if dict_start != -1 and dict_end != -1:
                return plist_str[dict_start:dict_end+7]
    return "Не удалось извлечь Entitlements"

print("="*60)
print("🔍 ДИАГНОСТИКА APPLE BUNDLE IDS И APP GROUPS")
print("="*60)

# 1. Поиск Bundle IDs
main_bid_id = None
widget_bid_id = None

bids_res = api_request("GET", "/bundleIds?limit=100")
for item in bids_res.get("data", []):
    ident = item.get("attributes", {}).get("identifier")
    b_id = item.get("id")
    if ident == "com.samvel.armenianbible":
        main_bid_id = b_id
        print(f"📱 Основное приложение Bundle ID: {ident} (ID: {b_id})")
    elif ident == "com.samvel.armenianbible.BibleWidget":
        widget_bid_id = b_id
        print(f"🧩 Виджет расширение Bundle ID: {ident} (ID: {b_id})")

# 2. Проверка App Groups
print("\n📦 Проверка существующих App Groups в аккаунте:")
app_groups_res = api_request("GET", "/appGroups?limit=100")
target_group_id = None
if "data" in app_groups_res:
    for g in app_groups_res["data"]:
        gid = g.get("attributes", {}).get("groupId")
        name = g.get("attributes", {}).get("name")
        id_ = g.get("id")
        print(f"  - App Group: {gid} (Name: {name}, ID: {id_})")
        if gid == "group.com.samvel.ArmenianBible":
            target_group_id = id_
else:
    print(f"  ⚠️ Ответ API: {app_groups_res}")

if not target_group_id:
    print("⚠️ App Group 'group.com.samvel.ArmenianBible' не найдена, создаем через API...")
    create_group_res = api_request("POST", "/appGroups", {
        "data": {
            "type": "appGroups",
            "attributes": {
                "groupId": "group.com.samvel.ArmenianBible",
                "name": "Armenian Bible Lock Screen Group"
            }
        }
    })
    if "data" in create_group_res:
        target_group_id = create_group_res["data"]["id"]
        print(f"✅ App Group успешно создана! (ID: {target_group_id})")
    else:
        print(f"⚠️ Не удалось создать App Group: {create_group_res}")

# 3. Проверка capabilities для виджета
needs_profile_regen = False

for name, bid_id in [("Main App", main_bid_id), ("Widget Extension", widget_bid_id)]:
    if not bid_id:
        continue
    print(f"\n⚙️ Возможности (Capabilities) для {name} (ID: {bid_id}):")
    caps_res = api_request("GET", f"/bundleIds/{bid_id}/bundleIdCapabilities?limit=50")
    has_app_groups = False
    if "data" in caps_res:
        for cap in caps_res["data"]:
            cap_type = cap.get("attributes", {}).get("capabilityType")
            print(f"  ✓ {cap_type}")
            if cap_type == "APP_GROUPS":
                has_app_groups = True
    else:
        print(f"  ⚠️ Ответ API: {caps_res}")

    if not has_app_groups:
        print(f"  🚨 ВНИМАНИЕ: У {name} ОТСУТСТВУЕТ возможность APP_GROUPS! Добавляем через API...")
        add_cap_res = api_request("POST", "/bundleIdCapabilities", {
            "data": {
                "type": "bundleIdCapabilities",
                "attributes": {
                    "capabilityType": "APP_GROUPS"
                },
                "relationships": {
                    "bundleId": {
                        "data": {
                            "type": "bundleIds",
                            "id": bid_id
                        }
                    }
                }
            }
        })
        if "data" in add_cap_res:
            print(f"  ✅ Возможность APP_GROUPS успешно добавлена к {name}!")
            has_app_groups = True
            needs_profile_regen = True
        else:
            print(f"  ⚠️ Ошибка добавления APP_GROUPS: {add_cap_res}")

    # Привязка App Group к Bundle ID
    if target_group_id:
        print(f"  🔗 Привязка App Group group.com.samvel.ArmenianBible к {name}...")
        link_res = api_request("POST", f"/bundleIds/{bid_id}/relationships/appGroups", {
            "data": [
                {
                    "type": "appGroups",
                    "id": target_group_id
                }
            ]
        })
        print(f"  Результат привязки: {link_res}")
        if link_res.get("status") == "success" or "data" in link_res:
            needs_profile_regen = True

# 4. Проверка существующих профилей провижининга
print("\n" + "="*60)
print("📜 ПРОВЕРКА ENTITLEMENTS В ТЕКУЩИХ ПРОФИЛЯХ ПРОВИЖИНИНГА")
print("="*60)

profiles_res = api_request("GET", "/profiles?filter[profileType]=IOS_APP_STORE&limit=100")
for p in profiles_res.get("data", []):
    p_name = p.get("attributes", {}).get("name", "")
    p_id = p.get("id")
    if "ArmenianBible" in p_name or "Widget" in p_name:
        b64_content = p.get("attributes", {}).get("profileContent", "")
        entitlements = extract_entitlements_from_b64(b64_content)
        print(f"\n📄 Профиль: {p_name} (ID: {p_id})")
        print("Entitlements:")
        print(entitlements)
        if "com.apple.security.application-groups" in entitlements:
            print("  ✅ App Groups ПРИСУТСТВУЮТ в профиле!")
        else:
            print("  ❌ App Groups ОТСУТСТВУЮТ в профиле! Виджет не сможет читать настройки!")
            needs_profile_regen = True

print("\n" + "="*60)
if needs_profile_regen:
    print("⚠️ ТРЕБУЕТСЯ ПЕРЕСОЗДАНИЕ ПРОФИЛЕЙ: auto_cert_setup.py пересоздаст их с правильными правами.")
else:
    print("✅ Все проверки прав завершены успешно.")
print("="*60)
