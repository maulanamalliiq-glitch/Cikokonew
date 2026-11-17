"""Apply validated workflow inputs without changing the Android application ID."""
import os
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
name = os.environ['RELEASE_NAME']
code = os.environ['RELEASE_CODE']
if not re.fullmatch(r'\d+\.\d+\.\d+', name):
    raise SystemExit('Version name must use X.Y.Z')
if not re.fullmatch(r'[1-9]\d*', code) or not 2565 < int(code) <= 2100000000:
    raise SystemExit('Version code must be above 2565 and within the Android limit')
pubspec = root / 'flutter/pubspec.yaml'
gradle = root / 'flutter/android/app/build.gradle.kts'
p, count = re.subn(r'^version: .+$', f'version: {name}+{code}', pubspec.read_text(), flags=re.M)
assert count == 1
g, count = re.subn(r'versionCode\s*=\s*\d+', f'versionCode = {code}', gradle.read_text())
assert count == 1
g, count = re.subn(r'versionName\s*=\s*"[^"]+"', f'versionName = "{name}"', g)
assert count == 1
pubspec.write_text(p)
gradle.write_text(g)
print(f'Build version {name}+{code}; confirm it exceeds ALL uploads in Play Console.')
