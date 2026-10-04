"""Verify backup privacy invariants in merged manifests and a built debug APK.

Run after building the APK and processing profile/release main manifests.
Uses only Python's standard library and the installed Android SDK's aapt2.
"""

import argparse
import hashlib
import os
from pathlib import Path
import re
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ANDROID = '{http://schemas.android.com/apk/res/android}'
RULES = {'fullBackupContent': 'backup_rules',
         'dataExtractionRules': 'data_extraction_rules'}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def dump(aapt2, apk, *args):
    result = subprocess.run([str(aapt2), 'dump', *args, str(apk)],
                            capture_output=True, text=True, encoding='utf-8',
                            timeout=30)
    require(result.returncode == 0, 'aapt2 failed: ' + result.stderr)
    return result.stdout


def xml_tree(text):
    """Decode aapt2's element/attribute tree for comparison with source XML."""
    stack = []
    root = None
    for line in text.splitlines():
        depth = len(line) - len(line.lstrip())
        element = re.match(r'\s*E: ([\w-]+)', line)
        if element:
            while stack and stack[-1][0] >= depth:
                stack.pop()
            node = ET.Element(element[1])
            if stack:
                stack[-1][1].append(node)
            else:
                require(root is None, 'Multiple packaged XML roots')
                root = node
            stack.append((depth, node))
        attribute = re.match(r'\s*A: ([\w-]+)="([^"]*)"', line)
        if attribute:
            require(bool(stack), 'Packaged attribute without element')
            stack[-1][1].set(attribute[1], attribute[2])
    require(root is not None, 'Packaged XML missing root')
    return root


def policy(tree, modern):
    require(tree.attrib == {}, 'Unexpected backup policy attributes')
    require(tree.tag == ('data-extraction-rules' if modern else
                         'full-backup-content'), 'Unexpected backup root')
    sections = list(tree) if modern else [tree]
    if modern:
        require([s.tag for s in sections] == ['cloud-backup', 'device-transfer'],
                'Cloud/D2D sections missing or cross-platform transfer enabled')
    for section in sections:
        require(section.attrib == {} and len(section) == 1,
                'Backup policy must have exactly one include per transfer type')
        include = section[0]
        require(include.tag == 'include' and len(include) == 0 and
                include.attrib == {'domain': 'file', 'path': 'language-tag.txt'},
                'Only application-support language-tag.txt may be backed up')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sdk', type=Path, default=Path(
        os.environ.get('ANDROID_HOME', str(Path(os.environ.get(
            'LOCALAPPDATA', '')) / 'Android' / 'sdk'))))
    args = parser.parse_args()
    aapt2 = max((args.sdk / 'build-tools').glob('*/aapt2.exe'),
                key=lambda p: tuple(int(n) for n in p.parent.name.split('.')))
    apk = ROOT / 'build/app/outputs/flutter-apk/app-debug.apk'
    out = ROOT / 'build/android-backup-acceptance'
    out.mkdir(parents=True, exist_ok=True)
    manifest = dump(aapt2, apk, 'xmltree', '--file', 'AndroidManifest.xml')
    resources = dump(aapt2, apk, 'resources')
    (out / 'packaged-manifest.txt').write_text(manifest, encoding='utf-8')
    require(re.search(r':allowBackup\([^)]*\)=true', manifest),
            'Packaged manifest does not enable the preference backup')
    require(':backupAgent(' not in manifest, 'Custom backup agent needs review')
    for attribute, name in RULES.items():
        match = re.search(r'resource (0x[\da-f]+) xml/' + name + r'\s', resources)
        require(match is not None, 'Packaged backup resource missing: ' + name)
        require(re.search(':' + attribute + r'\([^)]*\)=@' + match[1] + r'\b',
                          manifest), 'Packaged manifest references wrong rules')
        xml = dump(aapt2, apk, 'xmltree', '--file', 'res/xml/' + name + '.xml')
        (out / (name + '.txt')).write_text(xml, encoding='utf-8')
        policy(xml_tree(xml), modern=name == 'data_extraction_rules')
        policy(ET.parse(ROOT / 'android/app/src/main/res/xml' /
                        (name + '.xml')).getroot(),
               modern=name == 'data_extraction_rules')
    for variant in ['debug', 'profile', 'release']:
        path = (ROOT / 'build/app/intermediates/merged_manifest' / variant /
                ('process' + variant.title() + 'MainManifest') / 'AndroidManifest.xml')
        app = ET.parse(path).getroot().find('application')
        require(app is not None and app.get(ANDROID + 'allowBackup') == 'true',
                variant + ' merged manifest must enable preference backup')
        require(app.get(ANDROID + 'backupAgent') is None,
                variant + ' introduces a custom backup agent')
        for attribute, name in RULES.items():
            require(app.get(ANDROID + attribute) == '@xml/' + name,
                    variant + ' merged manifest does not reference ' + name)
    print('PASS: debug/profile/release merged manifests and packaged debug XML;')
    print('legacy, cloud and D2D allow only file/language-tag.txt; no cross-platform rules.')
    print('APK SHA-256: ' + hashlib.sha256(apk.read_bytes()).hexdigest())


if __name__ == '__main__':
    main()
