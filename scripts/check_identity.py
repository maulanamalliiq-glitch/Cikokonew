"""Check the existing Cikoko identity and agreement between version files."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
gradle = (root / 'flutter/android/app/build.gradle.kts').read_text()
pubspec = (root / 'flutter/pubspec.yaml').read_text()
firebase = json.loads((root / 'flutter/android/app/google-services.json').read_text())
package = 'com.KelurahanCikoko.malik'
assert f'applicationId = "{package}"' in gradle
assert f'namespace = "{package}"' in gradle
assert firebase['project_info']['project_id'] == 'kelurahan-cikoko-862d3'
assert any(c['client_info']['android_client_info']['package_name'] == package for c in firebase['client'])
version = re.search(r'^version: (\d+\.\d+\.\d+)\+(\d+)\s*$', pubspec, re.M)
assert version, 'Invalid pubspec version'
assert re.search(r'versionCode\s*=\s*' + version[2] + r'\b', gradle)
assert f'versionName = "{version[1]}"' in gradle
assert 'https://datawebs.my.id/mobile-api/index.php' in (root / 'flutter/lib/api.dart').read_text()
print(f'Cikoko identity verified; version {version[1]}+{version[2]}')
