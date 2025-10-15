#!/usr/bin/env python3
import hashlib
import os
import sys
from collections import defaultdict

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
TARGET_DIRS = {
    'docs',
    'adrs',
    'test',
    'lib',
    'EquipmentForm',
    'scripts',
}

EXCLUDED_DIRS = {
    '.git',
    '.dart_tool',
    'build',
    '.idea',
    '.vscode',
    '.flutter-plugins',
    '.flutter-plugins-dependencies',
    '.packages',
    '.pub-cache',
}
ALLOWED_NAME_DUPLICATES = {
    'README.md',
    'LICENSE',
    '.gitignore',
    'index.html',
}


def iter_files():
    for root, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in EXCLUDED_DIRS]
        for filename in files:
            path = os.path.join(root, filename)
            if os.path.islink(path):
                continue
            relative = os.path.relpath(path, ROOT)
            top_level = relative.split(os.sep, 1)[0]
            if top_level not in TARGET_DIRS:
                continue
            yield relative


def file_hash(path):
    hasher = hashlib.sha256()
    with open(os.path.join(ROOT, path), 'rb') as fh:
        for chunk in iter(lambda: fh.read(8192), b''):
            hasher.update(chunk)
    return hasher.hexdigest()


def main():
    by_name = defaultdict(list)
    by_hash = defaultdict(list)

    for relative in iter_files():
        name = os.path.basename(relative)
        by_name[name].append(relative)
        digest = file_hash(relative)
        by_hash[digest].append(relative)

    issues = []

    for name, paths in sorted(by_name.items()):
        if len(paths) > 1 and name not in ALLOWED_NAME_DUPLICATES:
            issues.append(
                f"File name collision for '{name}': {', '.join(sorted(paths))}"
            )

    for digest, paths in sorted(by_hash.items()):
        if len(paths) > 1:
            issues.append(
                f"Duplicate content detected (hash {digest[:12]}…): {', '.join(sorted(paths))}"
            )

    if issues:
        print('Duplicate detector found issues:')
        for issue in issues:
            print(f'- {issue}')
        sys.exit(1)

    print('No duplicate names or contents detected.')


if __name__ == '__main__':
    main()
