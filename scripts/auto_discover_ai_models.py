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

# Базовые кандидаты для проверки при недоступности ListModels
KNOWN_CANDIDATES = {
    "gemini": [
        "gemini-3.5-flash-lite",
        "gemini-3.5-flash",
        "gemini-2.5-flash",
        "gemini-2.5-pro"
    ],
    "openai": [
        "gpt-5",
        "gpt-5-mini",
        "gpt-4.5-preview",
        "gpt-4o",
        "gpt-4o-mini",
        "o3-mini",
        "o1-mini",
        "o1",
        "gpt-3.5-turbo"
    ],
    "claude": [
        "claude-3-7-sonnet-latest",
        "claude-3-5-sonnet-latest",
        "claude-3-5-haiku-latest",
        "claude-3-5-haiku-20241022",
        "claude-3-haiku-20240307"
    ]
}

def log(msg: str):
    print(msg, flush=True)

# -----------------------------------------------------------------------------
# 1. Запросы к API для обнаружения доступных моделей
# -----------------------------------------------------------------------------

def discover_gemini_models(api_key: str) -> list[str]:
    """Запрашивает список моделей через Google Gemini API (v1beta/models)"""
    if not api_key:
        return []
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
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
                    # Нам нужны только модели, поддерживающие generateContent
                    if "generateContent" in methods:
                        # Исключаем embedding, aqa, imagen, text-bison
                        if any(x in name for x in ["embedding", "aqa", "imagen", "bison", "gecko"]):
                            continue
                        if "gemini" in name:
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
                    if mid.startswith("gpt-") or mid.startswith("o1") or mid.startswith("o3") or mid.startswith("o4"):
                        # Исключаем audio, realtime, vision-preview и т.д.
                        if any(x in mid for x in ["audio", "realtime", "transcribe", "tts", "search"]):
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
    
    url = "https://api.anthropic.com/v1/models"
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
                    if "claude" in mid:
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

def ping_gemini_model(model: str, api_key: str) -> bool:
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    payload = json.dumps({
        "contents": [{"parts": [{"text": "ping"}]}],
        "generationConfig": {"maxOutputTokens": 5}
    }).encode("utf-8")
    
    req = urllib.request.Request(url, data=payload, headers={
        "Content-Type": "application/json",
        "x-goog-api-key": api_key
    })
    try:
        with urllib.request.urlopen(req, timeout=8) as res:
            return res.status == 200
    except Exception:
        return False


def ping_openai_model(model: str, api_key: str) -> bool:
    url = "https://api.openai.com/v1/chat/completions"
    payload = json.dumps({
        "model": model,
        "messages": [{"role": "user", "content": "ping"}],
        "max_tokens": 5
    }).encode("utf-8")
    
    req = urllib.request.Request(url, data=payload, headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    })
    try:
        with urllib.request.urlopen(req, timeout=8) as res:
            return res.status == 200
    except Exception:
        return False


def ping_claude_model(model: str, api_key: str) -> bool:
    url = "https://api.anthropic.com/v1/messages"
    payload = json.dumps({
        "model": model,
        "max_tokens": 5,
        "messages": [{"role": "user", "content": "ping"}]
    }).encode("utf-8")
    
    req = urllib.request.Request(url, data=payload, headers={
        "Content-Type": "application/json",
        "x-api-key": api_key,
        "anthropic-version": "2023-06-01"
    })
    try:
        with urllib.request.urlopen(req, timeout=8) as res:
            return res.status == 200
    except Exception:
        return False


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


def rank_models(models: list[str], provider: str) -> list[str]:
    """Сортирует список проверенных моделей по убыванию новизны и производительности"""
    if provider == "gemini":
        # Приоритет: старшая версия -> flash -> pro -> lite
        def gemini_score(m: str):
            ver = parse_model_version(m)
            sub_score = 0
            if "flash" in m and "lite" not in m:
                sub_score = 3
            elif "pro" in m:
                sub_score = 2
            elif "lite" in m or "8b" in m:
                sub_score = 1
            return (ver[0], ver[1], sub_score)
        
        return sorted(list(dict.fromkeys(models)), key=gemini_score, reverse=True)

    elif provider == "openai":
        def openai_score(m: str):
            ver = parse_model_version(m)
            sub_score = 0
            if "mini" in m:
                sub_score = 1
            elif "4o" in m:
                sub_score = 2
            elif "o3" in m or "o1" in m:
                sub_score = 3
            return (ver[0], ver[1], sub_score)
        
        return sorted(list(dict.fromkeys(models)), key=openai_score, reverse=True)

    elif provider == "claude":
        def claude_score(m: str):
            ver = parse_model_version(m)
            sub_score = 0
            if "sonnet" in m:
                sub_score = 3
            elif "haiku" in m:
                sub_score = 2
            elif "opus" in m:
                sub_score = 1
            return (ver[0], ver[1], sub_score)
        
        return sorted(list(dict.fromkeys(models)), key=claude_score, reverse=True)

    return models


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


def update_registry_file(gemini_list: list[str], openai_list: list[str], claude_list: list[str]) -> bool:
    """Обновляет иерархии в AIModelRegistry.swift с валидацией синтаксиса"""
    if not REGISTRY_PATH.exists():
        log(f"❌ Файл {REGISTRY_PATH} не найден.")
        return False

    shutil.copyfile(REGISTRY_PATH, BACKUP_PATH)
    content = REGISTRY_PATH.read_text(encoding="utf-8")

    def replace_hierarchy(code: str, var_name: str, models: list[str]) -> str:
        formatted = ",\n".join(f'        "{m}"' for m in models)
        pattern = rf'(static let {var_name}:\s*\[String\]\s*=\s*\[)[^\]]*(\])'
        replacement = rf'\g<1>\n{formatted}\n    \g<2>'
        return re.sub(pattern, replacement, code, flags=re.DOTALL)

    if gemini_list:
        content = replace_hierarchy(content, "geminiHierarchy", gemini_list)
        target_gemini = gemini_list[0]
        content = re.sub(r'(forKey:\s*"active_gemini_model"\)\s*\?\?\s*)"[^"]+"', rf'\1"{target_gemini}"', content)
        content = re.sub(r'(return\s*)"gemini-[^"]+"', rf'\1"{target_gemini}"', content)

    if openai_list:
        content = replace_hierarchy(content, "openAIHierarchy", openai_list)
        target_openai = openai_list[0] if "mini" in openai_list[0] else (openai_list[1] if len(openai_list) > 1 else openai_list[0])
        content = re.sub(r'(forKey:\s*"active_openai_model"\)\s*\?\?\s*)"[^"]+"', rf'\1"{target_openai}"', content)

    if claude_list:
        content = replace_hierarchy(content, "claudeHierarchy", claude_list)

    REGISTRY_PATH.write_text(content, encoding="utf-8")

    if not validate_swift_syntax(REGISTRY_PATH):
        log("❌ Синтаксис Swift нарушен после правки. Откат изменений...")
        shutil.copyfile(BACKUP_PATH, REGISTRY_PATH)
        return False

    if BACKUP_PATH.exists():
        BACKUP_PATH.unlink()

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
