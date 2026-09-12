#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
===============================================================================
Deep Audit & Verification Suite (Full-Spectrum iOS/Windows Pre-flight QA)
===============================================================================
Комплексный сквозной аудит кодовой базы iOS проекта при разработке на Windows:
1. Swift Access Control Auditor (проверка public vs internal, return types, args)
2. Swift Syntax & Structure Sanity (баланс скобок, строковые литералы, обязательные импорты)
3. App Group & Entitlements Matcher (проверка групп в entitlements, project.yml и Swift)
4. Apple REST API & Python Script Guard (py_compile, запрещенные параметры URL API Apple)
5. Localization Symmetry & Format Specifier QA (en / ru / hy .lproj проверка)
6. Data Flow & Widget Contract Integrity (синхронность ключей UserDefaults и WidgetCenter)
===============================================================================
"""

import os
import sys
import re
import py_compile
import xml.etree.ElementTree as ET
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

class AuditReport:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.passed_checks = []

    def pass_check(self, title: str, details: str = ""):
        self.passed_checks.append((title, details))
        print(f"  \033[92m✓\033[0m {title} {details}")

    def add_warning(self, title: str, details: str):
        self.warnings.append((title, details))
        print(f"  \033[93m⚠\033[0m {title}: {details}")

    def add_error(self, title: str, details: str, file_path: str = "", line_num: int = 0):
        location = f" [{file_path}:{line_num}]" if file_path and line_num else f" [{file_path}]" if file_path else ""
        self.errors.append((title, details, location))
        print(f"  \033[91m✗\033[0m \033[1m{title}\033[0m{location}\n    -> {details}")

    def is_clean(self) -> bool:
        return len(self.errors) == 0

    def print_summary(self):
        print("\n" + "=" * 70)
        print("  РЕЗУЛЬТАТЫ СКВОЗНОГО АУДИТА (DEEP AUDIT REPORT)")
        print("=" * 70)
        print(f"  Успешных проверок: \033[92m{len(self.passed_checks)}\033[0m")
        print(f"  Предупреждений:    \033[93m{len(self.warnings)}\033[0m")
        print(f"  Критических ошибок: \033[91m{len(self.errors)}\033[0m")
        print("=" * 70)
        if self.is_clean():
            print("\033[92m\033[1m  ✨ ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ! КОД ГОТОВ К КОММИТУ И СБОРКЕ В CI/CD.\033[0m\n")
        else:
            print("\033[91m\033[1m  🚨 ОБНАРУЖЕНЫ КРИТИЧЕСКИЕ ОШИБКИ! КОММИТ И ПУШ ЗАБЛОКИРОВАНЫ.\033[0m\n")


# -----------------------------------------------------------------------------
# 1. Swift Access Control & Signature Auditor
# -----------------------------------------------------------------------------
def audit_swift_access_control(repo_root: Path, report: AuditReport):
    print("\n[1/6] 🔍 Аудит уровней доступа Swift (Access Control Consistency)...")
    swift_files = list((repo_root / "Sources").glob("*.swift")) + list((repo_root / "Widget").glob("*.swift"))
    
    internal_types = set()
    public_types = set()
    
    type_decl_pattern = re.compile(r'^\s*(public\s+|open\s+)?(enum|struct|class|actor|protocol)\s+([A-Za-z0-9_]+)', re.M)
    for p in swift_files:
        text = p.read_text(encoding="utf-8", errors="ignore")
        for m in type_decl_pattern.finditer(text):
            is_pub = bool(m.group(1))
            tname = m.group(3)
            if is_pub:
                public_types.add(tname)
            else:
                internal_types.add(tname)

    # Публичный метод не может использовать внутренний тип в своей сигнатуре
    pub_decl_pattern = re.compile(r'^\s*(public|open)\s+(static\s+)?(func|var|let)\s+([A-Za-z0-9_]+)')
    
    found_violations = 0
    for p in swift_files:
        text = p.read_text(encoding="utf-8", errors="ignore")
        lines = text.splitlines()
        for idx, line in enumerate(lines, 1):
            if pub_decl_pattern.match(line):
                for itype in internal_types:
                    if itype in public_types:
                        continue
                    # Проверяем вхождение в тип возврата '-> Type' или тип переменной ': Type'
                    ret_match = re.search(r'->\s*([A-Za-z0-9_<>,\s\?\[\]]+)', line)
                    type_match = re.search(r':\s*([A-Za-z0-9_<>,\s\?\[\]]+)', line)
                    
                    target_strings = []
                    if ret_match:
                        target_strings.append(ret_match.group(1))
                    if type_match:
                        target_strings.append(type_match.group(1))
                        
                    for target in target_strings:
                        if re.search(r'\b' + re.escape(itype) + r'\b', target):
                            report.add_error(
                                "Нарушение уровней доступа Swift",
                                f"Публичный член использует внутренний тип '{itype}'. Swift compiler error: 'method/property cannot be declared public because its result/type uses an internal type'",
                                str(p.relative_to(repo_root)),
                                idx
                            )
                            found_violations += 1

    if found_violations == 0:
        report.pass_check("Swift Access Control", f"Проверено {len(swift_files)} файлов. Никаких конфликтов public/internal.")


# -----------------------------------------------------------------------------
# 2. Swift Syntax, Brackets & Mandatory Imports
# -----------------------------------------------------------------------------
def clean_swift_code(text: str) -> str:
    """Очищает код Swift от комментариев (включая вложенные /* /* */ */) и строковых литералов."""
    out = []
    i = 0
    n = len(text)
    while i < n:
        # Многострочная строка """
        if text[i:i+3] == '"""':
            i += 3
            while i < n and text[i:i+3] != '"""':
                if text[i] == '\\' and i + 1 < n:
                    i += 2
                else:
                    i += 1
            i = min(i + 3, n)
            continue
        # Однострочный комментарий //
        if text[i:i+2] == '//':
            i += 2
            while i < n and text[i] != '\n':
                i += 1
            continue
        # Вложенный комментарий /* ... */
        if text[i:i+2] == '/*':
            i += 2
            nesting = 1
            while i < n and nesting > 0:
                if text[i:i+2] == '/*':
                    nesting += 1
                    i += 2
                elif text[i:i+2] == '*/':
                    nesting -= 1
                    i += 2
                else:
                    i += 1
            continue
        # Обычная строка "
        if text[i] == '"':
            i += 1
            while i < n and text[i] != '"':
                if text[i] == '\\' and i + 1 < n:
                    i += 2
                elif text[i] == '\n':
                    break
                else:
                    i += 1
            if i < n and text[i] == '"':
                i += 1
            continue
        out.append(text[i])
        i += 1
    return "".join(out)


def audit_swift_syntax_and_imports(repo_root: Path, report: AuditReport):
    print("\n[2/6] 🔍 Проверка синтаксической целостности и импортов Swift...")
    swift_files = list((repo_root / "Sources").glob("*.swift")) + list((repo_root / "Widget").glob("*.swift"))
    
    clean_count = 0
    for p in swift_files:
        rel_path = str(p.relative_to(repo_root))
        text = p.read_text(encoding="utf-8", errors="ignore")
        lines = text.splitlines()

        clean_text = clean_swift_code(text)
        
        curlies = clean_text.count('{') - clean_text.count('}')
        parens = clean_text.count('(') - clean_text.count(')')
        brackets = clean_text.count('[') - clean_text.count(']')
        
        if curlies != 0:
            report.add_error("Дисбаланс фигурных скобок", f"Разница '{{' vs '}}': {curlies}", rel_path)
        if parens != 0:
            # Предупреждение на круглые скобки из-за возможных макросов/интерполяций
            if abs(parens) > 2:
                report.add_error("Дисбаланс круглых скобок", f"Разница '(' vs ')': {parens}", rel_path)
            else:
                report.add_warning("Возможный дисбаланс круглых скобок", f"{rel_path}: разница {parens}")
        if brackets != 0:
            report.add_error("Дисбаланс квадратных скобок", f"Разница '[' vs ']': {brackets}", rel_path)

        # Обязательные импорты
        if "WidgetCenter.shared" in text and "import WidgetKit" not in text:
            report.add_error("Пропущен импорт", "Используется 'WidgetCenter.shared' без 'import WidgetKit'", rel_path)

        # Ошибки опциональной развертки non-optional синглтонов
        for idx, line in enumerate(lines, 1):
            if re.search(r'AppGroupConstants\.sharedDefaults\?', line):
                report.add_error("Ошибочная опциональная цепочка", "AppGroupConstants.sharedDefaults не является опционалом (уберите '?')", rel_path, idx)
            if "if let def = defaults" in line and "AppGroupConstants.sharedDefaults" in text:
                report.add_error("Ошибочный conditional binding", "'if let def = defaults' вызовет ошибку компиляции на non-optional типе", rel_path, idx)

        clean_count += 1

    report.pass_check("Swift Syntax & Imports", f"Проверено {clean_count} файлов на скобки, импорты и опционалы.")


# -----------------------------------------------------------------------------
# 3. App Group & Entitlements Matcher
# -----------------------------------------------------------------------------
def audit_app_groups_and_entitlements(repo_root: Path, report: AuditReport):
    print("\n[3/6] 🔍 Аудит App Group песочницы и Entitlements...")
    main_ent_path = repo_root / "Sources" / "ArmenianBible.entitlements"
    widget_ent_path = repo_root / "Widget" / "BibleWidget.entitlements"
    project_yml_path = repo_root / "project.yml"
    verse_swift_path = repo_root / "Sources" / "BibleVerse.swift"

    def parse_entitlements(path: Path) -> list:
        if not path.exists():
            return []
        try:
            tree = ET.parse(path)
            root = tree.getroot()
            dict_node = root.find("dict")
            if dict_node is None:
                return []
            keys = dict_node.findall("key")
            for k in keys:
                if k.text == "com.apple.security.application-groups":
                    arr_node = dict_node.find("array")
                    if arr_node is not None:
                        return [s.text for s in arr_node.findall("string") if s.text]
        except Exception as e:
            report.add_error("Ошибка парсинга XML", f"Не удалось распарсить {path.name}: {e}")
        return []

    main_groups = parse_entitlements(main_ent_path)
    widget_groups = parse_entitlements(widget_ent_path)

    if not main_groups:
        report.add_error("Отсутствуют App Groups", f"В {main_ent_path.name} не найдена секция application-groups!")
    if not widget_groups:
        report.add_error("Отсутствуют App Groups", f"В {widget_ent_path.name} не найдена секция application-groups!")

    if set(main_groups) != set(widget_groups):
        report.add_error(
            "Рассогласование App Groups",
            f"Группы основного приложения ({main_groups}) не совпадают с виджетом ({widget_groups})!"
        )
    else:
        report.pass_check("Entitlements Harmony", f"Группы синхронизированы: {main_groups}")

    # Проверяем Swift константы в BibleVerse.swift
    if verse_swift_path.exists():
        verse_text = verse_swift_path.read_text(encoding="utf-8", errors="ignore")
        active_match = re.search(r'activeSuiteName\s*=\s*"([^"]+)"', verse_text)
        if active_match:
            active_val = active_match.group(1)
            if active_val not in main_groups:
                report.add_error(
                    "Несоответствие App Group в коде",
                    f"AppGroupConstants.activeSuiteName = '{active_val}' отсутствует в entitlements!",
                    "Sources/BibleVerse.swift"
                )
            else:
                report.pass_check("Swift App Group Contract", f"Код обращается к зарегистрированной группе: {active_val}")


# -----------------------------------------------------------------------------
# 4. Apple REST API & Python Scripts Guard
# -----------------------------------------------------------------------------
def audit_apple_api_and_python_scripts(repo_root: Path, report: AuditReport):
    print("\n[4/6] 🔍 Валидация скриптов CI/CD и вызовов Apple REST API...")
    py_files = list(repo_root.glob(".github/scripts/*.py")) + list(repo_root.glob("scripts/*.py"))
    
    for p in py_files:
        rel_path = str(p.relative_to(repo_root))
        # 1. Проверка синтаксиса Python через py_compile
        try:
            py_compile.compile(str(p), doraise=True)
        except py_compile.PyCompileError as e:
            report.add_error("Синтаксическая ошибка Python", str(e), rel_path)
            continue

        if p.name == "deep_audit.py":
            continue

        text = p.read_text(encoding="utf-8", errors="ignore")
        lines = text.splitlines()

        # 2. Проверка недопустимых URL-параметров в Apple Store Connect API
        # Эндпоинт /bundleIdCapabilities НЕ поддерживает query parameter limit
        for idx, line in enumerate(lines, 1):
            if "bundleIdCapabilities" in line and "limit=" in line:
                report.add_error(
                    "Запрещенный параметр Apple API",
                    "Эндпоинт /bundleIdCapabilities не поддерживает параметр ?limit= (вызывает ошибку 400 PARAMETER_ERROR.ILLEGAL)",
                    rel_path,
                    idx
                )

    report.pass_check("Python Scripts & Apple API", f"Проверено {len(py_files)} скриптов. Все синтаксически валидны, параметры API корректны.")


# -----------------------------------------------------------------------------
# 5. Localization Symmetry & Format Specifier QA
# -----------------------------------------------------------------------------
def audit_localizations(repo_root: Path, report: AuditReport):
    print("\n[5/6] 🔍 Аудит симметрии локализаций (i18n QA)...")
    lproj_dirs = {
        "en": repo_root / "Sources" / "en.lproj" / "Localizable.strings",
        "ru": repo_root / "Sources" / "ru.lproj" / "Localizable.strings",
        "hy": repo_root / "Sources" / "hy.lproj" / "Localizable.strings"
    }

    key_value_pattern = re.compile(r'^\s*"([^"]+)"\s*=\s*"([^"]*)";', re.M)
    dict_by_lang = {}

    for lang, path in lproj_dirs.items():
        if not path.exists():
            report.add_error("Файл локализации отсутствует", f"Файл {path} не найден!")
            return
        content = path.read_text(encoding="utf-8", errors="ignore")
        dict_by_lang[lang] = {m.group(1): m.group(2) for m in key_value_pattern.finditer(content)}

    en_keys = set(dict_by_lang.get("en", {}).keys())
    ru_keys = set(dict_by_lang.get("ru", {}).keys())
    hy_keys = set(dict_by_lang.get("hy", {}).keys())

    all_keys = en_keys | ru_keys | hy_keys
    missing_keys = False

    for k in all_keys:
        if k not in en_keys:
            report.add_warning("Пропущен ключ локализации [en]", f"Ключ '{k}' отсутствует в en.lproj")
            missing_keys = True
        if k not in ru_keys:
            report.add_warning("Пропущен ключ локализации [ru]", f"Ключ '{k}' отсутствует в ru.lproj")
            missing_keys = True
        if k not in hy_keys:
            report.add_warning("Пропущен ключ локализации [hy]", f"Ключ '{k}' отсутствует в hy.lproj")
            missing_keys = True

    # Проверка совпадения спецификаторов форматирования (%@, %d, etc)
    specifier_pattern = re.compile(r'%[@dulfsz]')
    for k in en_keys & ru_keys & hy_keys:
        en_spec = specifier_pattern.findall(dict_by_lang["en"][k])
        ru_spec = specifier_pattern.findall(dict_by_lang["ru"][k])
        hy_spec = specifier_pattern.findall(dict_by_lang["hy"][k])
        if en_spec != ru_spec or en_spec != hy_spec:
            report.add_error(
                "Несовпадение спецификаторов формата строки",
                f"Ключ '{k}' имеет разные спецификаторы: en={en_spec}, ru={ru_spec}, hy={hy_spec}",
                "Localizable.strings"
            )

    report.pass_check("Localization Symmetry", f"Сравнено {len(all_keys)} ключей между en, ru, hy.")


# -----------------------------------------------------------------------------
# 6. Data Flow & Widget Contract Integrity
# -----------------------------------------------------------------------------
def audit_data_flow_and_widgets(repo_root: Path, report: AuditReport):
    print("\n[6/6] 🔍 Аудит сквозного потока данных (End-to-End Data Flow)...")
    manager_path = repo_root / "Sources" / "BibleManager.swift"
    widget_path = repo_root / "Widget" / "BibleWidget.swift"
    verse_path = repo_root / "Sources" / "BibleVerse.swift"

    if not manager_path.exists() or not widget_path.exists() or not verse_path.exists():
        report.add_error("Отсутствуют ключевые компоненты потока данных", "Один из файлов менеджера/виджета не найден")
        return

    mgr_text = manager_path.read_text(encoding="utf-8", errors="ignore")
    widget_text = widget_path.read_text(encoding="utf-8", errors="ignore")
    verse_text = verse_path.read_text(encoding="utf-8", errors="ignore")

    # Проверяем, что при смене стиля вызывается перезагрузка виджетов
    if "setWidgetVisualStyle" in mgr_text:
        if "WidgetCenter.shared.reloadAllTimelines()" not in mgr_text:
            report.add_error(
                "Обрыв обратной связи виджета",
                "В setWidgetVisualStyle() отсутствует вызов WidgetCenter.shared.reloadAllTimelines()!",
                "Sources/BibleManager.swift"
            )
        else:
            report.pass_check("Widget Timeline Invalidation", "При изменении стиля вызывается WidgetCenter.shared.reloadAllTimelines().")

    # Проверяем согласованность ключа стиля
    mgr_writes_style = "widget_visual_style" in mgr_text or "widget_visual_style" in verse_text
    widget_reads_style = "widget_visual_style" in widget_text or "widget_visual_style" in verse_text
    
    if mgr_writes_style and widget_reads_style:
        report.pass_check("Style Key Contract", "Ключ 'widget_visual_style' согласован между приложением и виджетом.")
    else:
        report.add_error("Несогласованный ключ UserDefaults", "Ключ стиля виджета не совпадает между приложением и виджетом!")


# -----------------------------------------------------------------------------
# Точка входа
# -----------------------------------------------------------------------------
def main():
    repo_root = Path(__file__).resolve().parent.parent
    report = AuditReport()

    print("=" * 70)
    print("  🚀 ЗАПУСК ПОЛНОГО СКВОЗНОГО АУДИТА (FULL-SPECTRUM DEEP AUDIT)")
    print(f"  Репозиторий: {repo_root}")
    print("=" * 70)

    audit_swift_access_control(repo_root, report)
    audit_swift_syntax_and_imports(repo_root, report)
    audit_app_groups_and_entitlements(repo_root, report)
    audit_apple_api_and_python_scripts(repo_root, report)
    audit_localizations(repo_root, report)
    audit_data_flow_and_widgets(repo_root, report)

    report.print_summary()
    sys.exit(0 if report.is_clean() else 1)


if __name__ == "__main__":
    main()
