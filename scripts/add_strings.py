#!/usr/bin/env python3
"""Добавляет строки в Localizable.xcstrings вместе с русским переводом.

    python3 scripts/add_strings.py "English key=Русский перевод" ...

`xcodebuild` сам ключи в каталог не дописывает, а `LocalizationTests` требует перевод
у каждой строки — скрипт сохраняет порядок ключей и формат каталога, как у Xcode.
"""
import json
import sys
from pathlib import Path

path = Path(__file__).resolve().parent.parent / "AIChat2/Resources/Localizable.xcstrings"
catalog = json.loads(path.read_text(encoding="utf-8"))
strings = catalog["strings"]
for pair in sys.argv[1:]:
    key, _, russian = pair.partition("=")
    if not key or not russian:
        sys.exit(f"Ожидается «key=перевод»: {pair}")
    if key not in strings:
        keys = list(strings)
        index = next((i for i, existing in enumerate(keys) if existing.casefold() > key.casefold()), len(keys))
        strings = dict([*strings.items()][:index] + [(key, {})] + [*strings.items()][index:])
    strings[key].setdefault("localizations", {})["ru"] = {"stringUnit": {"state": "translated", "value": russian}}
catalog["strings"] = strings
path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2, separators=(",", " : ")),
                encoding="utf-8")
print(f"OK: {len(sys.argv) - 1} strings")
