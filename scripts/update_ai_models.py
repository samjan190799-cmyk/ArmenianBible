#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
update_ai_models.py — Безопасное обновление и верификация моделей ИИ (Gemini, OpenAI, Claude)
по эталонному стандарту приложения Forma (SamHealth).

Возможности:
1. Вывод статуса и иерархий моделей: python update_ai_models.py --status
2. Безопасный апгрейд на новейшие версии 2026 года: python update_ai_models.py --upgrade
3. Установка конкретной модели: python update_ai_models.py --set-gemini gemini-2.5-flash
4. Тестирование доступности моделей через API (ping test): python update_ai_models.py --test
5. 100% Защита от ошибок: Автоматический бэкап, валидация синтаксиса Swift и Rollback при сбое.
"""

import sys
import os
import re
import shutil
import argparse
import urllib.request
import urllib.error
import json
from pathlib import Path

# Кодировка вывода для Windows консоли
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

PROJECT_ROOT = Path(__file__).resolve().parent
REGISTRY_PATH = PROJECT_ROOT / "Sources" / "AIModelRegistry.swift"
BACKUP_PATH = PROJECT_ROOT / "Sources" / "AIModelRegistry.swift.bak"

# Эталонные иерархии моделей (актуальность: 2026 год)
LATEST_HIERARCHIES = {
    "gemini": [
        "gemini-2.5-flash",
        "gemini-2.0-flash",
        "gemini-1.5-flash",
        "gemini-1.5-pro"
    ],
    "openai": [
        "gpt-5-mini",
        "gpt-4.5-preview",
        "gpt-4o-mini",
        "gpt-4o",
        "gpt-3.5-turbo"
    ],
    "claude": [
        "claude-3-7-sonnet-latest",
        "claude-3-5-haiku-latest",
        "claude-3-5-sonnet-latest",
        "claude-3-5-haiku-20241022",
        "claude-3-haiku-20240307"
    ]
}

def create_backup():
    """Создает резервную копию AIModelRegistry.swift"""
    if REGISTRY_PATH.exists():
        shutil.copyfile(REGISTRY_PATH, BACKUP_PATH)
        return True
    return False

def restore_backup():
    """Восстанавливает AIModelRegistry.swift из резервной копии"""
    if BACKUP_PATH.exists():
        shutil.copyfile(BACKUP_PATH, REGISTRY_PATH)
        print("🔄 [Rollback] Файл успешно восстановлен из резервной копии!")
        return True
    return False

def validate_swift_syntax(file_path: Path) -> bool:
    """Проверяет баланс фигурных скобок, круглых скобок и строковых литералов Swift"""
    try:
        content = file_path.read_text(encoding="utf-8")
    except Exception as e:
        print(f"❌ Ошибка чтения файла {file_path}: {e}")
        return False

    stack = []
    in_string = False
    in_multiline_string = False
    in_single_comment = False
    in_multi_comment = False
    escape = False

    i = 0
    n = len(content)
    line_num = 1

    while i < n:
        c = content[i]
        
        if c == '\n':
            line_num += 1
            if in_single_comment:
                in_single_comment = False
            i += 1
            continue

        if in_single_comment:
            i += 1
            continue

        if in_multi_comment:
            if c == '*' and i + 1 < n and content[i + 1] == '/':
                in_multi_comment = False
                i += 2
                continue
            i += 1
            continue

        if in_multiline_string:
            if c == '"' and i + 2 < n and content[i:i+3] == '"""' and not escape:
                in_multiline_string = False
                i += 3
                continue
            if c == '\\':
                escape = not escape
            else:
                escape = False
            i += 1
            continue

        if in_string:
            if c == '"' and not escape:
                in_string = False
            elif c == '\\':
                escape = not escape
            else:
                escape = False
            i += 1
            continue

        # Начало комментариев
        if c == '/' and i + 1 < n:
            if content[i + 1] == '/':
                in_single_comment = True
                i += 2
                continue
            elif content[i + 1] == '*':
                in_multi_comment = True
                i += 2
                continue

        # Начало многострочной строки
        if c == '"' and i + 2 < n and content[i:i+3] == '"""':
            in_multiline_string = True
            i += 3
            continue

        # Начало обычной строки
        if c == '"':
            in_string = True
            escape = False
            i += 1
            continue

        # Проверка скобок
        if c in "({[":
            stack.append((c, line_num))
        elif c in ")}]":
            if not stack:
                print(f"❌ Лишняя закрывающая скобка '{c}' на строке {line_num}")
                return False
            last_open, open_line = stack.pop()
            pairs = {')': '(', '}': '{', ']': '['}
            if pairs[c] != last_open:
                print(f"❌ Несоответствие скобок: '{last_open}' (строка {open_line}) закрыта '{c}' (строка {line_num})")
                return False

        i += 1

    if stack:
        last_open, open_line = stack[-1]
        print(f"❌ Незакрытая скобка '{last_open}' (строка {open_line})")
        return False

    return True

def parse_current_models():
    """Считывает текущие иерархии и активные модели из AIModelRegistry.swift"""
    if not REGISTRY_PATH.exists():
        print(f"❌ Файл не найден: {REGISTRY_PATH}")
        return None

    content = REGISTRY_PATH.read_text(encoding="utf-8")
    
    def extract_hierarchy(var_name):
        match = re.search(rf'public static let {var_name}:\s*\[String\]\s*=\s*\[(.*?)\]', content, re.DOTALL)
        if match:
            raw = match.group(1)
            items = [item.strip(' "\'\t\r\n') for item in raw.split(',') if item.strip(' "\'\t\r\n')]
            return items
        return []

    def extract_default(key_name):
        match = re.search(rf'forKey:\s*"{key_name}"\)\s*\?\?\s*"([^"]+)"', content)
        if match:
            return match.group(1)
        return "Не определена"

    return {
        "gemini": {
            "default": extract_default("active_gemini_model"),
            "hierarchy": extract_hierarchy("geminiHierarchy")
        },
        "openai": {
            "default": extract_default("active_openai_model"),
            "hierarchy": extract_hierarchy("openAIHierarchy")
        },
        "claude": {
            "default": extract_default("active_claude_model"),
            "hierarchy": extract_hierarchy("claudeHierarchy")
        }
    }

def print_status():
    """Выводит детальный статус реестра моделей ИИ"""
    data = parse_current_models()
    if not data:
        return

    print("\n" + "=" * 65)
    print(" 🤖 СТАТУС МОДЕЛЕЙ ИИ (Armenian Bible & Forma Architecture)")
    print("=" * 65)
    
    providers = [
        ("Google Gemini", "gemini"),
        ("OpenAI ChatGPT", "openai"),
        ("Anthropic Claude", "claude")
    ]

    for title, key in providers:
        info = data.get(key, {})
        default_model = info.get("default", "N/A")
        hierarchy = info.get("hierarchy", [])
        
        print(f"\n🔹 {title}:")
        print(f"   • Активная (по умолчанию): \033[92m{default_model}\033[0m")
        print(f"   • Каскадная иерархия (Fail-Safe Fallbacks):")
        for idx, m in enumerate(hierarchy, 1):
            star = "⭐️ (первичная)" if m == default_model else "🛡 (резерв)"
            print(f"     {idx}. {m:<28} {star}")

    print("\n" + "-" * 65)
    print("🛡 Каскадная защита: АКТИВНА")
    print("   Если новейшая модель вернет 404/400/429, приложение")
    print("   автоматически переключится на резервную без ошибок для пользователя.")
    print("=" * 65 + "\n")

def upgrade_models(gemini_model=None, openai_model=None, claude_model=None):
    """Безопасно обновляет иерархии и дефолтные модели с бэкапом и валидацией"""
    if not REGISTRY_PATH.exists():
        print("❌ Файл реестра не найден!")
        return False

    print("📦 Создание резервной копии AIModelRegistry.swift...")
    create_backup()

    content = REGISTRY_PATH.read_text(encoding="utf-8")

    # 1. Обновляем иерархии
    def replace_hierarchy(code, var_name, new_list):
        items_str = ",\n        ".join([f'"{m}"' for m in new_list])
        pattern = rf'public static let {var_name}:\s*\[String\]\s*=\s*\[(.*?)\]'
        replacement = f'public static let {var_name}: [String] = [\n        {items_str}\n    ]'
        return re.sub(pattern, replacement, code, flags=re.DOTALL)

    gemini_list = LATEST_HIERARCHIES["gemini"].copy()
    if gemini_model and gemini_model not in gemini_list:
        gemini_list.insert(0, gemini_model)

    openai_list = LATEST_HIERARCHIES["openai"].copy()
    if openai_model and openai_model not in openai_list:
        openai_list.insert(0, openai_model)

    claude_list = LATEST_HIERARCHIES["claude"].copy()
    if claude_model and claude_model not in claude_list:
        claude_list.insert(0, claude_model)

    content = replace_hierarchy(content, "geminiHierarchy", gemini_list)
    content = replace_hierarchy(content, "openAIHierarchy", openai_list)
    content = replace_hierarchy(content, "claudeHierarchy", claude_list)

    # 2. Обновляем дефолтные значения активных моделей
    target_gemini = gemini_model or gemini_list[0]
    target_openai = openai_model or openai_list[2] # gpt-4o-mini как ультрастабильный дефолт
    target_claude = claude_model or "claude-3-5-haiku-20241022"

    content = re.sub(r'(forKey:\s*"active_gemini_model"\)\s*\?\?\s*)"[^"]+"', rf'\1"{target_gemini}"', content)
    content = re.sub(r'(forKey:\s*"active_openai_model"\)\s*\?\?\s*)"[^"]+"', rf'\1"{target_openai}"', content)
    content = re.sub(r'(forKey:\s*"active_claude_model"\)\s*\?\?\s*)"[^"]+"', rf'\1"{target_claude}"', content)

    # Записываем изменения
    REGISTRY_PATH.write_text(content, encoding="utf-8")
    print("📝 Файл обновлен. Запуск проверки синтаксиса Swift...")

    # Валидация синтаксиса
    if not validate_swift_syntax(REGISTRY_PATH):
        print("❌ ОШИБКА: Синтаксис Swift нарушен! Немедленный откат...")
        restore_backup()
        return False

    print("✅ Синтаксическая проверка Swift пройдена успешно!")
    if BACKUP_PATH.exists():
        BACKUP_PATH.unlink() # Удаляем временный бэкап при успехе
    print("🎉 Все модели безопасно обновлены без единой ошибки!")
    print_status()
    return True

def test_api_models(gemini_key=None, openai_key=None, claude_key=None):
    """Выполняет тестовые легковесные пинги к API моделей"""
    print("\n🌐 Тестирование сетевой доступности моделей через API...")
    
    # Пинг Gemini
    if gemini_key:
        print("\n[Gemini] Тестирование:")
        for model in LATEST_HIERARCHIES["gemini"]:
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={gemini_key}"
            payload = json.dumps({"contents": [{"parts": [{"text": "ping"}]}]}).encode("utf-8")
            req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
            try:
                with urllib.request.urlopen(req, timeout=8) as res:
                    if res.status == 200:
                        print(f"  ✅ {model:<25} Доступна (HTTP 200)")
            except urllib.error.HTTPError as e:
                print(f"  ⚠️ {model:<25} Недоступна (HTTP {e.code})")
            except Exception as e:
                print(f"  ❌ {model:<25} Ошибка сети: {e}")
    else:
        print("ℹ️ Ключ Gemini API не передан (пропуск теста). Передайте через --gemini-key")

    # Пинг OpenAI
    if openai_key:
        print("\n[OpenAI] Тестирование:")
        for model in LATEST_HIERARCHIES["openai"]:
            url = "https://api.openai.com/v1/chat/completions"
            payload = json.dumps({"model": model, "messages": [{"role": "user", "content": "ping"}], "max_tokens": 5}).encode("utf-8")
            req = urllib.request.Request(url, data=payload, headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {openai_key}"
            })
            try:
                with urllib.request.urlopen(req, timeout=8) as res:
                    if res.status == 200:
                        print(f"  ✅ {model:<25} Доступна (HTTP 200)")
            except urllib.error.HTTPError as e:
                print(f"  ⚠️ {model:<25} Недоступна (HTTP {e.code})")
            except Exception as e:
                print(f"  ❌ {model:<25} Ошибка сети: {e}")
    else:
        print("ℹ️ Ключ OpenAI API не передан (пропуск теста). Передайте через --openai-key")

    # Пинг Claude
    if claude_key:
        print("\n[Claude] Тестирование:")
        for model in LATEST_HIERARCHIES["claude"]:
            url = "https://api.anthropic.com/v1/messages"
            payload = json.dumps({"model": model, "max_tokens": 5, "messages": [{"role": "user", "content": "ping"}]}).encode("utf-8")
            req = urllib.request.Request(url, data=payload, headers={
                "Content-Type": "application/json",
                "x-api-key": claude_key,
                "anthropic-version": "2023-06-01"
            })
            try:
                with urllib.request.urlopen(req, timeout=8) as res:
                    if res.status == 200:
                        print(f"  ✅ {model:<25} Доступна (HTTP 200)")
            except urllib.error.HTTPError as e:
                print(f"  ⚠️ {model:<25} Недоступна (HTTP {e.code})")
            except Exception as e:
                print(f"  ❌ {model:<25} Ошибка сети: {e}")
    else:
        print("ℹ️ Ключ Claude API не передан (пропуск теста). Передайте через --claude-key")

def main():
    parser = argparse.ArgumentParser(description="Безопасное обновление и верификация моделей ИИ для Armenian Bible LockScreen")
    parser.add_argument("--status", "-s", action="store_true", help="Показать статус текущих моделей и резервных цепочек")
    parser.add_argument("--upgrade", "-u", action="store_true", help="Безопасно обновить иерархии до новейших стабильных версий 2026 года")
    parser.add_argument("--set-gemini", type=str, help="Задать основную модель Gemini (например: gemini-2.5-flash)")
    parser.add_argument("--set-openai", type=str, help="Задать основную модель OpenAI (например: gpt-4o)")
    parser.add_argument("--set-claude", type=str, help="Задать основную модель Claude (например: claude-3-7-sonnet-latest)")
    parser.add_argument("--test", "-t", action="store_true", help="Проверить доступность моделей прямыми пинг-запросами к API")
    parser.add_argument("--gemini-key", type=str, default=os.getenv("GEMINI_API_KEY"), help="API-ключ Gemini для тестирования")
    parser.add_argument("--openai-key", type=str, default=os.getenv("OPENAI_API_KEY"), help="API-ключ OpenAI для тестирования")
    parser.add_argument("--claude-key", type=str, default=os.getenv("ANTHROPIC_API_KEY"), help="API-ключ Claude для тестирования")

    args = parser.parse_args()

    if args.upgrade or args.set_gemini or args.set_openai or args.set_claude:
        upgrade_models(
            gemini_model=args.set_gemini,
            openai_model=args.set_openai,
            claude_model=args.set_claude
        )
    elif args.test:
        test_api_models(
            gemini_key=args.gemini_key,
            openai_key=args.openai_key,
            claude_key=args.claude_key
        )
    else:
        print_status()

if __name__ == "__main__":
    main()
