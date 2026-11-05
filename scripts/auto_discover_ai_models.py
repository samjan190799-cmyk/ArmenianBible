#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
===============================================================================
Auto-Discover & Upgrade AI Models (Gemini, OpenAI, Claude)
===============================================================================
Автономный интеллектуальный сканер и апдейтер моделей искусственного интеллекта.

Возможности:
1. Опрашивает официальные API (Google Generative Language, OpenAI, Anthropic).
2. Запрашивает ListModels и находит все новейшие генеративные модели.
3. Проводит живые пинг-тесты (generateContent, chat/completions, messages).
4. Автоматически и безопасно обновляет AIModelRegistry.swift и update_ai_models.py.
5. Проверяет синтаксис Swift, запускает Deep Audit и откатывает изменения при ошибке.
6. Поддерживает работу в CI/CD (GitHub Actions) по еженедельному cron-расписанию.
===============================================================================
"""

import sys
import os
import re
import json
import shutil
import argparse
import datetime
import subprocess
import urllib.request
import urllib.error
from pathlib import Path

# Кодировка вывода для Windows консоли
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

CURRENT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = CURRENT_DIR.parent if CURRENT_DIR.name == "scripts" else CURRENT_DIR
REGISTRY_PATH = PROJECT_ROOT / "Sources" / "AIModelRegistry.swift"
BACKUP_PATH = PROJECT_ROOT / "Sources" / "AIModelRegistry.swift.bak"
SCRIPTS_UPDATE_PATH = PROJECT_ROOT / "scripts" / "update_ai_models.py"
ROOT_UPDATE_PATH = PROJECT_ROOT / "update_ai_models.py"
# Серверный каталог моделей: его отдаёт Worker по GET /v1/models, а приложение берёт кнопкой «Обновить модели»
CATALOG_PATH = PROJECT_ROOT / "cloudflare" / "ai-proxy" / "src" / "models.js"

# Базовые кандидаты для проверки при недоступности ListModels.
# Сверено с официальной документацией 2026-11-05 (ai.google.dev, developers.openai.com, platform.claude.com).
# Закрыты и сюда не входят: gemini-1.5 и 2.0, gpt-3.5-turbo, gpt-4.5-preview, o1 и o3-mini, все claude-3.x
KNOWN_CANDIDATES = {
    "gemini": [
        "gemini-3.5-flash-lite",
        "gemini-3.6-flash",
        "gemini-3.8-flash",
        "gemini-2.5-flash-lite"
    ],
    "openai": [
        "gpt-6-luna",
        "gpt-6.1-terra",
        "gpt-6.1-sol"
    ],
    "claude": [
        "claude-haiku-5-5",
        "claude-sonnet-5-5",
        "claude-sonnet-5",
        "claude-haiku-4-5"
    ]
}

# Слова в идентификаторах, по которым модель не подходит для ответов в чате: озвучка, картинки, Live,
# предварительные версии, специальные и дорогие семейства, закрытые claude-3.x
EXCLUDED = {
    "gemini": ["embedding", "aqa", "imagen", "bison", "gecko", "image", "tts", "live", "audio", "transcribe",
               "robotics", "computer-use", "veo", "native", "preview", "exp", "thinking", "learnlm"],
    "openai": ["audio", "realtime", "transcribe", "tts", "search", "image", "vision", "codex", "instruct", "pro",
               "deep-research", "moderation", "embedding", "cyber", "preview", "chat-latest", "computer-use"],
    "claude": ["claude-3", "claude-2", "instant"],
}

# Сколько моделей каждого уровня (0 недорогие, 1 средние, 2 остальные) попадает в список провайдера
TIER_LIMITS = {0: 2, 1: 2, 2: 1}

# Если проверку прошло меньше моделей, список провайдера не меняем: ключ мог просто не иметь доступа
MIN_VERIFIED = 2


def is_excluded(model: str, provider: str) -> bool:
    return any(word in model for word in EXCLUDED.get(provider, []))


def is_openai_reasoning(model: str) -> bool:
    """gpt-5 и новее, а также o1/o3/o4: у них нет произвольной температуры, лимит задаётся max_completion_tokens"""
    match = re.match(r"gpt-(\d+)", model)
    if match:
        return int(match.group(1)) >= 5
    return bool(re.match(r"o\d", model))

def log(msg: str):
    print(msg, flush=True)

# -----------------------------------------------------------------------------
# 1. Запросы к API для обнаружения доступных моделей
# -----------------------------------------------------------------------------

def discover_gemini_models(api_key: str) -> list[str]:
    """Запрашивает список моделей через Google Gemini API (v1beta/models)"""
    if not api_key:
        return []
    
    # pageSize: по умолчанию Google отдаёт только первые 50 моделей, и новые можно не увидеть. Ключ идёт заголовком, не в адресе
    url = "https://generativelanguage.googleapis.com/v1beta/models?pageSize=200"
    req = urllib.request.Request(url, headers={
        "Content-Type": "application/json",
        "x-goog-api-key": api_key
    })

    found = []
    try:
        with urllib.request.urlopen(req, timeout=12) as res:
            if res.status == 200:
                data = json.loads(res.read().decode("utf-8"))
                for m in data.get("models", []):
                    name = m.get("name", "").replace("models/", "")
                    methods = m.get("supportedGenerationMethods", [])
                    # Нам нужны только чат-модели, поддерживающие generateContent
                    if "generateContent" in methods and name.startswith("gemini-"):
                        if not is_excluded(name, "gemini"):
                            found.append(name)
    except Exception as e:
        log(f"  ⚠️ Запрос ListModels Gemini не удался: {e}. Используем расширенный список кандидатов.")
        found = KNOWN_CANDIDATES["gemini"]

    # Добавляем известных кандидатов, которых может не быть в списке
    for c in KNOWN_CANDIDATES["gemini"]:
        if c not in found:
            found.append(c)

    return found


def discover_openai_models(api_key: str) -> list[str]:
    """Запрашивает список моделей через OpenAI API (/v1/models)"""
    if not api_key:
        return []
    
    url = "https://api.openai.com/v1/models"
    req = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {api_key}"
    })
    
    found = []
    try:
        with urllib.request.urlopen(req, timeout=12) as res:
            if res.status == 200:
                data = json.loads(res.read().decode("utf-8"))
                for m in data.get("data", []):
                    mid = m.get("id", "")
                    if mid.startswith("gpt-") or mid.startswith("o3") or mid.startswith("o4"):
                        # Исключаем audio, realtime, codex, pro и т.д., а также датированные снимки (gpt-4o-2024-08-06)
                        if is_excluded(mid, "openai") or re.search(r"-\d{4}-\d{2}-\d{2}$", mid):
                            continue
                        found.append(mid)
    except Exception as e:
        log(f"  ⚠️ Запрос ListModels OpenAI не удался: {e}. Используем список кандидатов.")
        found = KNOWN_CANDIDATES["openai"]

    for c in KNOWN_CANDIDATES["openai"]:
        if c not in found:
            found.append(c)

    return found


def discover_claude_models(api_key: str) -> list[str]:
    """Запрашивает список моделей через Anthropic API (/v1/models)"""
    if not api_key:
        return []
    
    url = "https://api.anthropic.com/v1/models?limit=100"
    req = urllib.request.Request(url, headers={
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01"
    })

    found = []
    try:
        with urllib.request.urlopen(req, timeout=12) as res:
            if res.status == 200:
                data = json.loads(res.read().decode("utf-8"))
                for m in data.get("data", []):
                    mid = m.get("id", "")
                    if mid.startswith("claude-") and not is_excluded(mid, "claude"):
                        found.append(mid)
    except Exception as e:
        log(f"  ⚠️ Запрос ListModels Claude не удался: {e}. Используем список кандидатов.")
        found = KNOWN_CANDIDATES["claude"]

    for c in KNOWN_CANDIDATES["claude"]:
        if c not in found:
            found.append(c)

    return found


# -----------------------------------------------------------------------------
# 2. Пинг-тесты (валидация реальной работоспособности модели)
# -----------------------------------------------------------------------------

def request_ok(req: urllib.request.Request) -> bool:
    """200 — модель отвечает. 429 — модель есть, но упёрлись в лимит ключа: для каталога это не повод её вычёркивать"""
    try:
        with urllib.request.urlopen(req, timeout=12) as res:
            return res.status == 200
    except urllib.error.HTTPError as e:
        return e.code == 429
    except Exception:
        return False


def ping_gemini_model(model: str, api_key: str) -> bool:
    # Ключ идёт заголовком, а не в адресе: адреса попадают в логи
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
    payload = json.dumps({
        "contents": [{"parts": [{"text": "ping"}]}],
        "generationConfig": {"maxOutputTokens": 16}
    }).encode("utf-8")

    req = urllib.request.Request(url, data=payload, headers={
        "Content-Type": "application/json",
        "x-goog-api-key": api_key
    })
    return request_ok(req)


def ping_openai_model(model: str, api_key: str) -> bool:
    url = "https://api.openai.com/v1/chat/completions"
    # У gpt-5 и новее параметр max_tokens не принимается (400), нужен max_completion_tokens; размышление держим коротким
    body = {
        "model": model,
        "messages": [{"role": "user", "content": "ping"}],
        "max_completion_tokens": 16
    }
    if is_openai_reasoning(model):
        body["reasoning_effort"] = "low"
    payload = json.dumps(body).encode("utf-8")

    req = urllib.request.Request(url, data=payload, headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    })
    return request_ok(req)


def ping_claude_model(model: str, api_key: str) -> bool:
    url = "https://api.anthropic.com/v1/messages"
    # temperature не передаём: Claude 5 его не принимает
    payload = json.dumps({
        "model": model,
        "max_tokens": 16,
        "messages": [{"role": "user", "content": "ping"}]
    }).encode("utf-8")

    req = urllib.request.Request(url, data=payload, headers={
        "Content-Type": "application/json",
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01"
    })
    return request_ok(req)


# -----------------------------------------------------------------------------
# 3. Сортировка моделей по новизне и приоритету
# -----------------------------------------------------------------------------

def parse_model_version(name: str) -> tuple:
    """Извлекает числовую версию из названия модели для сортировки (например, 'gemini-2.5-flash' -> (2, 5))"""
    nums = re.findall(r'(\d+)(?:\.(\d+))?', name)
    if nums:
        major = int(nums[0][0])
        minor = int(nums[0][1]) if nums[0][1] else 0
        return (major, minor)
    return (0, 0)


def model_tier(model: str, provider: str) -> int:
    """0 — быстрые и недорогие (идут первыми: ими отвечают по умолчанию), 1 — средние, 2 — остальные"""
    m = model.lower()
    if provider == "gemini":
        if "lite" in m:
            return 0
        return 1 if "flash" in m else 2
    if provider == "openai":
        if any(word in m for word in ("luna", "mini", "nano")):
            return 0
        return 1 if "terra" in m else 2
    if provider == "claude":
        if "haiku" in m:
            return 0
        return 1 if "sonnet" in m else 2
    return 2


def rank_models(models: list[str], provider: str) -> list[str]:
    """Сортирует проверенные модели: сначала недорогие, внутри уровня более новые.
    Из каждого уровня берём не больше TIER_LIMITS, чтобы в приложение не уходил длинный хвост устаревших версий."""
    unique = [m for m in dict.fromkeys(models) if not is_excluded(m, provider)]

    def sort_key(m: str):
        ver = parse_model_version(m)
        return (model_tier(m, provider), -ver[0], -ver[1], m)

    result = []
    taken_per_tier = {}
    for m in sorted(unique, key=sort_key):
        tier = model_tier(m, provider)
        if taken_per_tier.get(tier, 0) >= TIER_LIMITS.get(tier, 1):
            continue
        taken_per_tier[tier] = taken_per_tier.get(tier, 0) + 1
        result.append(m)
    return result


# -----------------------------------------------------------------------------
# 4. Безопасное обновление AIModelRegistry.swift
# -----------------------------------------------------------------------------

def validate_swift_syntax(file_path: Path) -> bool:
    """Проверяет баланс скобок в Swift-файле"""
    try:
        content = file_path.read_text(encoding="utf-8")
    except Exception as e:
        log(f"❌ Ошибка чтения файла {file_path}: {e}")
        return False

    stack = []
    pairs = {')': '(', ']': '[', '}': '{'}
    in_string = False
    in_single_comment = False
    in_multi_comment = False
    escape = False

    i = 0
    n = len(content)
    while i < n:
        c = content[i]
        if in_single_comment:
            if c == '\n':
                in_single_comment = False
            i += 1
            continue
        if in_multi_comment:
            if content[i:i+2] == '*/':
                in_multi_comment = False
                i += 2
                continue
            i += 1
            continue
        if in_string:
            if escape:
                escape = False
            elif c == '\\':
                escape = True
            elif c == '"':
                in_string = False
            i += 1
            continue
        if content[i:i+2] == '//':
            in_single_comment = True
            i += 2
            continue
        if content[i:i+2] == '/*':
            in_multi_comment = True
            i += 2
            continue
        if c == '"':
            in_string = True
            i += 1
            continue
        if c in '({[':
            stack.append(c)
        elif c in ')}]':
            if not stack or stack[-1] != pairs[c]:
                return False
            stack.pop()
        i += 1

    return len(stack) == 0


def update_catalog_file(gemini_list: list[str], openai_list: list[str], claude_list: list[str]) -> bool:
    """Обновляет списки в cloudflare/ai-proxy/src/models.js (его отдаёт Worker по GET /v1/models)"""
    if not CATALOG_PATH.exists():
        log(f"ℹ️ Каталог {CATALOG_PATH} не найден, серверный список не обновлён.")
        return False

    text = CATALOG_PATH.read_text(encoding="utf-8")
    original = text

    def replace_list(code: str, key: str, models: list[str]) -> str:
        items = ", ".join(f"'{m}'" for m in models)
        # Берём первое вхождение «key: [ ... ]» — это поле MODEL_CATALOG
        return re.sub(rf"(\b{key}:\s*)\[[^\]]*\]", lambda m: f"{m.group(1)}[{items}]", code, count=1)

    if gemini_list:
        text = replace_list(text, "gemini", gemini_list)
    if openai_list:
        text = replace_list(text, "openai", openai_list)
    if claude_list:
        text = replace_list(text, "claude", claude_list)

    if text == original:
        log("ℹ️ Серверный каталог моделей уже актуален.")
        return False

    today = datetime.date.today().isoformat()
    text = re.sub(r"(updated:\s*)'[^']*'", lambda m: f"{m.group(1)}'{today}'", text, count=1)
    CATALOG_PATH.write_text(text, encoding="utf-8")
    log("✅ Серверный каталог моделей обновлён (cloudflare/ai-proxy/src/models.js). Чтобы он дошёл до приложений, выпустите Worker: npx wrangler deploy")
    return True


def update_registry_file(gemini_list: list[str], openai_list: list[str], claude_list: list[str]) -> bool:
    """Обновляет иерархии в AIModelRegistry.swift с валидацией синтаксиса"""
    if not REGISTRY_PATH.exists():
        log(f"❌ Файл {REGISTRY_PATH} не найден.")
        return False

    # Список провайдера меняем, только если проверку прошло достаточно моделей: ключ мог просто не иметь доступа
    def usable(models: list[str], title: str) -> list[str]:
        if models and len(models) < MIN_VERIFIED:
            log(f"  ⚠️ {title}: проверку прошло меньше {MIN_VERIFIED} моделей ({len(models)}), список не меняем.")
            return []
        return models

    gemini_list = usable(gemini_list, "Gemini")
    openai_list = usable(openai_list, "OpenAI")
    claude_list = usable(claude_list, "Claude")
    if not (gemini_list or openai_list or claude_list):
        log("ℹ️ Нечего обновлять: ни у одного провайдера нет достаточного числа проверенных моделей.")
        return False

    shutil.copyfile(REGISTRY_PATH, BACKUP_PATH)
    content = REGISTRY_PATH.read_text(encoding="utf-8")

    def replace_hierarchy(code: str, var_name: str, models: list[str]) -> str:
        formatted = ",\n".join(f'        "{m}"' for m in models)
        pattern = rf'(static let {var_name}:\s*\[String\]\s*=\s*\[)[^\]]*(\])'
        replacement = rf'\g<1>\n{formatted}\n    \g<2>'
        return re.sub(pattern, replacement, code, flags=re.DOTALL)

    # Активная модель в Swift не хранится литералом: это первая модель списка (AIModelRegistry.storedActive), поэтому правим только массивы
    if gemini_list:
        content = replace_hierarchy(content, "geminiHierarchy", gemini_list)

    if openai_list:
        content = replace_hierarchy(content, "openAIHierarchy", openai_list)

    if claude_list:
        content = replace_hierarchy(content, "claudeHierarchy", claude_list)

    REGISTRY_PATH.write_text(content, encoding="utf-8")

    if not validate_swift_syntax(REGISTRY_PATH):
        log("❌ Синтаксис Swift нарушен после правки. Откат изменений...")
        shutil.copyfile(BACKUP_PATH, REGISTRY_PATH)
        return False

    if BACKUP_PATH.exists():
        BACKUP_PATH.unlink()

    # Серверный каталог для кнопки «Обновить модели»: после выпуска Worker (npx wrangler deploy) приложения получат список без релиза
    update_catalog_file(gemini_list, openai_list, claude_list)

    # Синхронизируем также update_ai_models.py
    for up_path in [ROOT_UPDATE_PATH, SCRIPTS_UPDATE_PATH]:
        if up_path.exists():
            up_text = up_path.read_text(encoding="utf-8")
            if gemini_list:
                up_text = re.sub(r'("gemini":\s*\[)[^\]]*(\])', r'\g<1>\n' + ',\n'.join(f'        "{m}"' for m in gemini_list) + r'\n    \g<2>', up_text, flags=re.DOTALL)
            if openai_list:
                up_text = re.sub(r'("openai":\s*\[)[^\]]*(\])', r'\g<1>\n' + ',\n'.join(f'        "{m}"' for m in openai_list) + r'\n    \g<2>', up_text, flags=re.DOTALL)
            if claude_list:
                up_text = re.sub(r'("claude":\s*\[)[^\]]*(\])', r'\g<1>\n' + ',\n'.join(f'        "{m}"' for m in claude_list) + r'\n    \g<2>', up_text, flags=re.DOTALL)
            up_path.write_text(up_text, encoding="utf-8")

    log("✅ Файлы моделей успешно синхронизированы!")
    return True


# -----------------------------------------------------------------------------
# 5. Главный цикл обнаружения и оркестрации
# -----------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Автоматическое обнаружение и обновление моделей ИИ")
    parser.add_argument("--apply", "-a", action="store_true", help="Автоматически применить найденные новые модели")
    parser.add_argument("--gemini-key", type=str, default=os.getenv("GEMINI_API_KEY"), help="API-ключ Google Gemini")
    parser.add_argument("--openai-key", type=str, default=os.getenv("OPENAI_API_KEY"), help="API-ключ OpenAI")
    parser.add_argument("--claude-key", type=str, default=os.getenv("ANTHROPIC_API_KEY"), help="API-ключ Claude")
    args = parser.parse_args()

    log("\n" + "=" * 70)
    log("  🌐 СКАНИРОВАНИЕ И АВТОМАТИЧЕСКОЕ ОБНАРУЖЕНИЕ МОДЕЛЕЙ ИИ (2026)")
    log("=" * 70)

    verified_gemini = []
    verified_openai = []
    verified_claude = []

    # 1. Сканирование Gemini
    if args.gemini_key:
        log("\n[1/3] 🔍 Опрос API Google Generative AI...")
        candidates = discover_gemini_models(args.gemini_key)
        log(f"  Найдено потенциальных кандидатов: {len(candidates)}")
        for m in candidates:
            if ping_gemini_model(m, args.gemini_key):
                log(f"    ✅ {m:<25} Доступна (HTTP 200)")
                verified_gemini.append(m)
            else:
                log(f"    ⚪ {m:<25} Не поддерживается данным ключом")
        verified_gemini = rank_models(verified_gemini, "gemini")
    else:
        log("\n[1/3] ℹ️ Ключ GEMINI_API_KEY не передан. Пропуск живого сканирования.")

    # 2. Сканирование OpenAI
    if args.openai_key:
        log("\n[2/3] 🔍 Опрос API OpenAI...")
        candidates = discover_openai_models(args.openai_key)
        log(f"  Найдено потенциальных кандидатов: {len(candidates)}")
        for m in candidates:
            if ping_openai_model(m, args.openai_key):
                log(f"    ✅ {m:<25} Доступна (HTTP 200)")
                verified_openai.append(m)
            else:
                log(f"    ⚪ {m:<25} Не поддерживается")
        verified_openai = rank_models(verified_openai, "openai")
    else:
        log("\n[2/3] ℹ️ Ключ OPENAI_API_KEY не передан. Пропуск живого сканирования.")

    # 3. Сканирование Claude
    if args.claude_key:
        log("\n[3/3] 🔍 Опрос API Anthropic Claude...")
        candidates = discover_claude_models(args.claude_key)
        log(f"  Найдено потенциальных кандидатов: {len(candidates)}")
        for m in candidates:
            if ping_claude_model(m, args.claude_key):
                log(f"    ✅ {m:<25} Доступна (HTTP 200)")
                verified_claude.append(m)
            else:
                log(f"    ⚪ {m:<25} Не поддерживается")
        verified_claude = rank_models(verified_claude, "claude")
    else:
        log("\n[3/3] ℹ️ Ключ ANTHROPIC_API_KEY не передан. Пропуск живого сканирования.")

    log("\n" + "=" * 70)
    log("  ИТОГИ ПРОВЕРКИ И ВЕРИФИКАЦИИ:")
    log("=" * 70)
    if verified_gemini:
        log(f"  🔹 Gemini (топ): {verified_gemini[:5]}")
    if verified_openai:
        log(f"  🔹 OpenAI (топ): {verified_openai[:5]}")
    if verified_claude:
        log(f"  🔹 Claude (топ): {verified_claude[:5]}")

    # Применение обновлений
    if args.apply and (verified_gemini or verified_openai or verified_claude):
        log("\n🚀 Применение обнаруженных моделей к кодовой базе...")
        success = update_registry_file(verified_gemini, verified_openai, verified_claude)
        if success:
            log("\n🔍 Запуск Deep Audit для проверки проекта...")
            audit_script = PROJECT_ROOT / "scripts" / "deep_audit.py"
            if audit_script.exists():
                subprocess.run([sys.executable, str(audit_script)])
    else:
        log("\n💡 Для автоматического обновления файлов запустите с флагом --apply")

if __name__ == "__main__":
    main()
