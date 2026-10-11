#!/usr/bin/env python3
"""
Fetch all tags from asmr.one API and generate a Dart tag translations file.
The tag data is stored as compressed base64 to avoid exposing raw tag names
in source control.

Usage: python3 scripts/generate_tag_translations.py
"""
import json
import os
import urllib.request
import sys
import base64
import zlib
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

API_URL = "https://api.asmr-200.com/api/tags/"

def fetch_tags():
    req = urllib.request.Request(API_URL, headers={
        'Referer': 'https://www.asmr.one/',
        'Origin': 'https://www.asmr.one',
        'User-Agent': 'KikoFlu/tag-generator',
    })
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode('utf-8'))

def get_i18n_name(tag, lang_key):
    """Extract the i18n name for given lang key, preferring latest (non-deprecated) name."""
    i18n = tag.get('i18n', {})
    lang_data = i18n.get(lang_key, {})
    name = lang_data.get('name')
    return name  # None if not available

def load_extra_translations():
    """Load manually maintained translation files (e.g. Russian)."""
    extra = {}
    for filename in os.listdir(SCRIPT_DIR):
        if filename.startswith('tag_translations_') and filename.endswith('.json'):
            lang = filename[len('tag_translations_'):-len('.json')]  # e.g. 'ru'
            path = os.path.join(SCRIPT_DIR, filename)
            with open(path, 'r', encoding='utf-8') as f:
                extra[lang] = json.load(f)
            print(f"Loaded {len(extra[lang])} {lang} translations from {filename}", file=sys.stderr)
    return extra

def generate_dart(tags):
    # Load extra language translations (manually maintained)
    extra_langs = load_extra_translations()

    # Build translation data as a dict
    translations = {}
    sorted_tags = sorted(tags, key=lambda t: t['id'])

    for tag in sorted_tags:
        tag_id = tag['id']
        default_name = tag.get('name', '')

        zh_name = get_i18n_name(tag, 'zh-cn') or default_name
        en_name = get_i18n_name(tag, 'en-us') or default_name
        ja_name = get_i18n_name(tag, 'ja-jp') or default_name

        entry = {'zh': zh_name, 'en': en_name, 'ja': ja_name}

        # Merge extra language translations
        for lang, lang_data in extra_langs.items():
            if str(tag_id) in lang_data:
                entry[lang] = lang_data[str(tag_id)]

        translations[str(tag_id)] = entry

    # Encode: JSON -> UTF-8 -> zlib compress -> base64
    json_bytes = json.dumps(translations, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
    compressed = zlib.compress(json_bytes, 9)
    encoded = base64.b64encode(compressed).decode('ascii')

    # Split into 76-char lines for readability
    encoded_lines = [encoded[i:i+76] for i in range(0, len(encoded), 76)]

    lines = []
    lines.append("// AUTO-GENERATED FILE — DO NOT EDIT MANUALLY")
    lines.append(f"// Generated from {API_URL}")
    lines.append(f"// Date: {datetime.now().strftime('%Y-%m-%d')}")
    lines.append(f"// Total tags: {len(tags)}")
    lines.append("//")
    lines.append("// To regenerate: python3 scripts/generate_tag_translations.py")
    lines.append("//")
    lines.append("// Tag data is stored as compressed base64 to avoid exposing")
    lines.append("// raw tag names in source control.")
    lines.append("")
    lines.append("import 'dart:convert';")
    lines.append("import 'dart:io' show zlib;")
    lines.append("")
    lines.append("const String _encodedTagData =")
    for i, line in enumerate(encoded_lines):
        suffix = ";" if i == len(encoded_lines) - 1 else ""
        lines.append(f"    '{line}'{suffix}")
    lines.append("")
    lang_keys = "'zh' (Simplified Chinese), 'en' (English), 'ja' (Japanese)"
    if extra_langs:
        lang_keys += ', ' + ', '.join(f"'{k}'" for k in sorted(extra_langs.keys()))
    lines.append("/// Tag translation map: tag_id -> { locale_key: localized_name }")
    lines.append(f"/// Locale keys: {lang_keys}")
    lines.append("late final Map<int, Map<String, String>> tagTranslations = _decodeTagData();")
    lines.append("")
    lines.append("Map<int, Map<String, String>> _decodeTagData() {")
    lines.append("  try {")
    lines.append("    final bytes = base64Decode(_encodedTagData);")
    lines.append("    final decompressed = zlib.decode(bytes);")
    lines.append("    final jsonStr = utf8.decode(decompressed);")
    lines.append("    final Map<String, dynamic> raw = jsonDecode(jsonStr);")
    lines.append("    return raw.map((key, value) => MapEntry(")
    lines.append("      int.parse(key),")
    lines.append("      (value as Map<String, dynamic>).map((k, v) => MapEntry(k, v as String)),")
    lines.append("    ));")
    lines.append("  } catch (e) {")
    lines.append("    print('Failed to decode tag translations: \$e');")
    lines.append("    return {};")
    lines.append("  }")
    lines.append("}")
    lines.append("")
    lines.append("/// Reverse lookup: tag name (any language) -> tag_id")
    lines.append("/// Used for matching display names back to tag IDs")
    lines.append("late final Map<String, int> tagNameToId = _buildTagNameToId();")
    lines.append("")
    lines.append("Map<String, int> _buildTagNameToId() {")
    lines.append("  final map = <String, int>{};")
    lines.append("  for (final entry in tagTranslations.entries) {")
    lines.append("    for (final name in entry.value.values) {")
    lines.append("      map[name.toLowerCase()] = entry.key;")
    lines.append("    }")
    lines.append("  }")
    lines.append("  return map;")
    lines.append("}")
    lines.append("")

    return '\n'.join(lines)

def main():
    print("Fetching tags from API...", file=sys.stderr)
    tags = fetch_tags()
    print(f"Fetched {len(tags)} tags", file=sys.stderr)

    dart_code = generate_dart(tags)

    output_path = "lib/src/utils/tag_translations.dart"
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(dart_code)

    print(f"Generated {output_path} with {len(tags)} tags", file=sys.stderr)

if __name__ == '__main__':
    main()
