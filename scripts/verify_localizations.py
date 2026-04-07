#!/usr/bin/env python3
"""
Localization safety checks for B2 Berufssprachkurs.

Checks:
1) Key parity between Localizable.swift and each Localizable.strings file.
2) Risky dynamic localization lookups that bypass Localizable constants
   (for example Localizable.string(self.rawValue)).

Exit code:
0 = all checks pass
1 = issues found
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


SWIFT_KEY_PATTERN = re.compile(r'^\s*static let\s+\w+\s*=\s*"([^"]+)"', re.M)
STRINGS_KEY_PATTERN = re.compile(r'^"([^"]+)"\s*=\s*"(?:\\.|[^"])*"\s*;', re.M)
LOCALIZABLE_STRING_CALL_PATTERN = re.compile(r"Localizable\.string\(([^)]*)\)")


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def parse_swift_keys(swift_text: str) -> set[str]:
    return set(SWIFT_KEY_PATTERN.findall(swift_text))


def parse_strings_keys(strings_text: str) -> set[str]:
    return set(STRINGS_KEY_PATTERN.findall(strings_text))


def find_dynamic_calls(repo_root: Path) -> tuple[list[tuple[Path, int, str]], list[tuple[Path, int, str]]]:
    hard_risk: list[tuple[Path, int, str]] = []
    soft_risk: list[tuple[Path, int, str]] = []

    for file_path in repo_root.rglob("*.swift"):
        if file_path.name == "Localizable.swift":
            continue
        text = read_text(file_path)
        lines = text.splitlines()
        for idx, line in enumerate(lines, start=1):
            for match in LOCALIZABLE_STRING_CALL_PATTERN.finditer(line):
                arg = match.group(1).strip()
                # Safe patterns:
                # - Localizable.string(Localizable.someConstant)
                # - Localizable.string("literal_key")  (still valid, but explicit)
                safe_constant = re.fullmatch(r"Localizable\.\w+", arg) is not None
                safe_literal = re.fullmatch(r'"[^"]+"', arg) is not None
                if safe_constant or safe_literal:
                    continue
                line_text = line.strip()
                if ".rawValue" in arg:
                    hard_risk.append((file_path, idx, line_text))
                else:
                    soft_risk.append((file_path, idx, line_text))
    return hard_risk, soft_risk


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    loc_root = repo_root / "B2 Berufssprachkurs" / "Core/09 - Resources/03 - Localisations"
    swift_file = loc_root / "Localizable.swift"
    language_files = {
        "de": loc_root / "de.lproj/Localizable.strings",
        "en": loc_root / "en.lproj/Localizable.strings",
    }

    errors: list[str] = []

    if not swift_file.exists():
        print(f"ERROR: Missing {swift_file}")
        return 1

    swift_keys = parse_swift_keys(read_text(swift_file))

    for lang, path in language_files.items():
        if not path.exists():
            errors.append(f"[{lang}] missing file: {path}")
            continue
        lang_keys = parse_strings_keys(read_text(path))
        missing = sorted(swift_keys - lang_keys)
        extra = sorted(lang_keys - swift_keys)
        if missing:
            errors.append(f"[{lang}] missing keys ({len(missing)}): {', '.join(missing)}")
        if extra:
            errors.append(f"[{lang}] extra keys ({len(extra)}): {', '.join(extra)}")

    hard_risk_calls, soft_risk_calls = find_dynamic_calls(repo_root / "B2 Berufssprachkurs")
    if hard_risk_calls:
        preview = "\n".join(
            f"  - {path.relative_to(repo_root)}:{line_no} -> {line_text}"
            for path, line_no, line_text in hard_risk_calls[:20]
        )
        more = "" if len(hard_risk_calls) <= 20 else f"\n  ... and {len(hard_risk_calls) - 20} more"
        errors.append(
            "high-risk Localizable.string(...) arguments detected (.rawValue) "
            f"({len(hard_risk_calls)}):\n{preview}{more}"
        )

    if errors:
        print("Localization verification FAILED\n")
        for err in errors:
            print(f"- {err}\n")
        return 1

    print("Localization verification passed.")
    print(f"- Swift keys: {len(swift_keys)}")
    for lang, path in language_files.items():
        lang_keys = parse_strings_keys(read_text(path))
        print(f"- {lang}.strings keys: {len(lang_keys)}")
    if soft_risk_calls:
        print(
            f"- Soft warning: dynamic Localizable.string(...) calls found: {len(soft_risk_calls)} "
            "(review during cleanup)"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
