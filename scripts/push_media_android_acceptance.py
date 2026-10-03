"""Isolated native Android acceptance. See MOBILE_TESTING.md; no Firebase provisioning.

Reuses the notebook harness's native ADB/UI and encrypted checkpoint utilities.
Only the dedicated read-only AVD and newly created unmounted storage are changed.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import socket
import subprocess
import time
import uuid
import glaze_notebook_android_acceptance as h

h.OUT = h.ROOT / 'build' / 'push-media-mobile-acceptance'
h.SERIAL = 'emulator-5562'
h.PORT = 18083
h.BASE = 'http://127.0.0.1:18083'
LABEL = 'push-media-android-disposable'


def build():
    h.OUT.mkdir(parents=True, exist_ok=True)
    flutter = Path(os.environ.get('FLUTTER_ROOT', str(Path.home() / 'develop/flutter'))) / 'bin/flutter.bat'
    result = h.command(['cmd', '/d', '/c', flutter, 'build', 'apk', '--debug', '--no-pub',
                        '--dart-define=API_BASE_URL=http://10.0.2.2:18083'], timeout=600, cwd=h.ROOT)
    (h.OUT / 'apk-build.log').write_bytes(result)
    apk = h.OUT / 'acceptance-debug.apk'
    shutil.copy2(h.ROOT / 'build/app/outputs/flutter-apk/app-debug.apk', apk)
    (h.OUT / 'apk-metadata.json').write_text(json.dumps({'api_base': 'http://10.0.2.2:18083',
        'sha256': hashlib.sha256(apk.read_bytes()).hexdigest()}), encoding='utf-8')
    print('Isolated APK built without Firebase configuration.', flush=True)


def emulator():
    if h.SERIAL in h.command([h.ADB, 'devices']).decode():
        raise RuntimeError('Dedicated emulator port occupied; existing device preserved')
    h.OUT.mkdir(parents=True, exist_ok=True)
    with (h.OUT / 'emulator.out.log').open('wb') as out, (h.OUT / 'emulator.err.log').open('wb') as err:
        p = subprocess.Popen([str(h.SDK / 'emulator/emulator.exe'), '-avd', 'Medium_Phone_2', '-read-only',
            '-no-snapshot', '-no-window', '-no-audio', '-no-boot-anim', '-port', '5562'],
            stdout=out, stderr=err, creationflags=subprocess.CREATE_NO_WINDOW)
    (h.OUT / 'emulator.pid').write_text(str(p.pid))
    print('Dedicated read-only Android emulator started.', flush=True)


def verify_emulator():
    h.command(['powershell', '-NoProfile', '-Command',
        "$p=@(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^(emulator|qemu).*exe$' -and "
        "$_.CommandLine -match '-read-only' -and $_.CommandLine -match '-port[ =]+5562(?: |$)' }); "
        "if($p.Count -eq 0){exit 1}"])


def signup(username, password):
    opener = h.client()
    h.form(opener, '/signup', {'forename': 'Media', 'surname': 'Acceptance', 'username': username,
        'email': username + '@example.invalid', 'password': password,
        'passwordConfirmation': password}, '/signup')
    h.form(opener, '/login', {'username': username, 'password': password}, '/login')
    return opener


def multipart(opener, path, fields, file=None):
    boundary = 'acceptance' + uuid.uuid4().hex
    data = bytearray()
    for key, value in fields.items():
        content_type = 'Content-Type: application/json\r\n' if key == 'data' else ''
        data.extend((f'--{boundary}\r\nContent-Disposition: form-data; name="{key}"\r\n{content_type}\r\n{value}\r\n').encode())
    if file:
        name, mime, content = file
        data.extend((f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{name}"\r\n'
                     f'Content-Type: {mime}\r\n\r\n').encode())
        data.extend(content)
        data.extend(b'\r\n')
    data.extend(f'--{boundary}--\r\n'.encode())
    return h.request(opener, path, bytes(data), content_type='multipart/form-data; boundary=' + boundary)['data']


def start():
    if (h.OUT / 'state.dpapi').exists():
        raise RuntimeError('Previous encrypted acceptance checkpoint exists; stop it first')
    with socket.socket() as sock:
        if sock.connect_ex(('127.0.0.1', h.PORT)) == 0:
            raise RuntimeError('Isolated backend port occupied')
    verify_emulator()
    apk = h.OUT / 'acceptance-debug.apk'
    metadata = json.loads((h.OUT / 'apk-metadata.json').read_text())
    if metadata['api_base'] != 'http://10.0.2.2:18083' or metadata['sha256'] != hashlib.sha256(apk.read_bytes()).hexdigest():
        raise RuntimeError('Isolated APK fingerprint mismatch')
    s = {'container': 'keramik-media-android-' + uuid.uuid4().hex[:12],
        'username': 'media_' + uuid.uuid4().hex[:10], 'password': uuid.uuid4().hex + 'Aa9',
        'access': 'acceptance' + uuid.uuid4().hex[:10], 'secret': uuid.uuid4().hex + uuid.uuid4().hex, 'checks': []}
    h.save(s)
    h.command(['docker', 'run', '--detach', '--name', s['container'], '--label', 'keramik.acceptance=' + LABEL,
        '--publish', '127.0.0.1::9000', '--env', 'MINIO_ROOT_USER=' + s['access'], '--env', 'MINIO_ROOT_PASSWORD=' + s['secret'],
        'keramik-local/minio:RELEASE.2025-04-22T22-12-26Z', 'server', '/data'])
    port = h.command(['docker', 'port', s['container'], '9000/tcp']).decode().strip()
    if not re.fullmatch(r'127\.0\.0\.1:\d+', port):
        raise RuntimeError('Storage must bind loopback only')
    s['minio_port'] = int(port.split(':')[1]); h.save(s)
    for _ in range(45):
        try:
            h.urllib.request.urlopen('http://' + port + '/minio/health/ready', timeout=2).close(); break
        except OSError:
            time.sleep(1)
    h.command(['docker', 'run', '--rm', '--network', 'container:' + s['container'], '--env', 'MINIO_ROOT_USER=' + s['access'],
        '--env', 'MINIO_ROOT_PASSWORD=' + s['secret'], '--entrypoint', '/bin/sh', 'keramik-local/mc:RELEASE.2025-04-16T18-13-26Z', '-c',
        'mc alias set local http://127.0.0.1:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD >/dev/null && '
        'mc mb local/images local/avatars >/dev/null && mc anonymous set none local/images >/dev/null && mc anonymous set download local/avatars >/dev/null'])
    env = os.environ.copy()
    env.update({'MINIO_URL': 'http://' + port, 'MINIO_PUBLIC_URL': f'http://10.0.2.2:{s["minio_port"]}',
        'MINIO_ACCESS_KEY': s['access'], 'MINIO_SECRET_KEY': s['secret'], 'MINIO_BUCKET': 'images', 'MINIO_AVATAR_BUCKET': 'avatars'})
    args = '--spring.profiles.active=test --server.port=18083 --server.address=127.0.0.1 --chat.media.enabled=true --billing.stripe.enabled=false --billing.stripe.secret-key= --billing.stripe.webhook-secret='
    with (h.OUT / 'backend.out.log').open('wb') as out, (h.OUT / 'backend.err.log').open('wb') as err:
        p = subprocess.Popen(['cmd', '/d', '/c', str(h.BACKEND / 'gradlew.bat'), 'bootTestRun', '--args=' + args],
            cwd=h.BACKEND, env=env, stdout=out, stderr=err, creationflags=subprocess.CREATE_NO_WINDOW)
    s['backend_pid'] = p.pid; h.save(s)
    deadline = time.monotonic() + 100
    while time.monotonic() < deadline:
        if p.poll() is not None: raise RuntimeError('Isolated backend exited; private logs contain diagnostics')
        try:
            if h.request(h.client(), '/actuator/health/readiness')['status'] == 'UP': break
        except (OSError, RuntimeError): time.sleep(1)
    else: raise RuntimeError('Backend readiness exceeded 100 seconds')
    print('Disposable H2/private MinIO backend ready.', flush=True)
    owner = signup(s['username'], s['password'])
    peer_name = 'peer_' + uuid.uuid4().hex[:8]
    peer = signup(peer_name, uuid.uuid4().hex + 'Aa9')
    s['peer_name'] = peer_name
    peer_id = h.request(peer, '/api/account/me')['data']['userId']
    friend = h.request(owner, '/api/friend-requests', {'userId': peer_id})['data']
    h.request(peer, '/api/friend-requests/' + friend['friendRequestId'] + '/accept', {}, method='POST')
    s['conversation'] = h.request(owner, '/api/chat/direct', {'userId': peer_id})['data']['id']
    stages = h.request(owner, '/api/stages')['data']
    s['pieces'] = []
    for index, title in enumerate(['Viewed bowl', 'Never viewed vase']):
        stage = next(v for v in stages if v['title'] == 'Finished') if index == 0 else stages[0]
        piece = {'title': title, 'clayTypeId': 0, 'weight': .2, 'note': '', 'rating': 3,
            'stageId': stage['id'], 'tags': [], 'glazes': []}
        s['pieces'].append(multipart(owner, '/api/ceramics', {'data': json.dumps(piece)}))
    ffmpeg = Path(os.environ['LOCALAPPDATA']) / 'Microsoft/WinGet/Links/ffmpeg.exe'
    h.command([ffmpeg, '-hide_banner', '-loglevel', 'error', '-f', 'lavfi', '-i', 'color=c=0x2255aa:s=640x320',
        '-vf', 'drawbox=x=20:y=20:w=600:h=280:color=white:t=8', '-frames:v', '1', '-y', h.OUT / 'media-fixture.jpg'])
    for kind, name, mime, content in [('IMAGE', 'fixture.jpg', 'image/jpeg', (h.OUT / 'media-fixture.jpg').read_bytes()),
        ('VOICE', 'fixture.m4a', 'audio/mp4', (h.BACKEND / 'src/test/resources/media/mono-aac.m4a').read_bytes())]:
        multipart(peer, '/api/chat/conversations/' + s['conversation'] + '/attachments',
            {'clientMessageId': str(uuid.uuid4()), 'type': kind}, (name, mime, content))
    h.save(s)
    deadline = time.monotonic() + 90
    while time.monotonic() < deadline:
        try:
            if h.adb('shell', 'getprop', 'sys.boot_completed').strip() == b'1': break
        except RuntimeError: pass
        time.sleep(1)
    h.command([h.ADB, '-s', h.SERIAL, 'install', '-r', apk], timeout=90)
    h.adb('shell', 'pm', 'clear', h.PACKAGE)
    h.adb('push', h.OUT / 'media-fixture.jpg', '/sdcard/Pictures/media-fixture.jpg')
    h.adb('shell', 'am', 'broadcast', '-a', 'android.intent.action.MEDIA_SCANNER_SCAN_FILE', '-d', 'file:///sdcard/Pictures/media-fixture.jpg')
    h.adb('shell', 'monkey', '-p', h.PACKAGE, '1'); h.wait('Welcome back')
    h.enter(s['username'], 0); h.enter(s['password'], 1); h.hide_keyboard(); h.tap('Log in'); h.wait('Ceramic journal', 45)
    print('Isolated app installed, authenticated and seeded with image/voice chat.', flush=True)


def stop():
    s = h.load()
    h.command(['powershell', '-NoProfile', '-Command',
        "$ids=@(Get-NetTCPConnection -LocalPort 18083 -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique);"
        "foreach($id in $ids){$p=Get-CimInstance Win32_Process -Filter ('ProcessId='+$id);"
        "if($p.Name -ne 'java.exe' -or $p.CommandLine -notmatch 'server.port=18083' -or $p.CommandLine -notmatch 'spring.profiles.active=test'){throw 'Process ownership mismatch'}; Stop-Process -Id $id}"])
    if s.get('backend_pid'): subprocess.run(['taskkill', '/PID', str(s['backend_pid']), '/T', '/F'], capture_output=True, creationflags=subprocess.CREATE_NO_WINDOW)
    info = json.loads(h.command(['docker', 'inspect', s['container']]))[0]
    if info['Config']['Labels'].get('keramik.acceptance') != LABEL or info['Mounts']:
        raise RuntimeError('Storage cleanup ownership mismatch')
    h.command(['docker', 'rm', '--force', s['container']])
    verify_emulator(); h.adb('emu', 'kill')
    (h.OUT / 'results.json').write_text(json.dumps({'checks': s['checks']}, indent=2), encoding='utf-8')
    (h.OUT / 'state.dpapi').unlink()
    print('Owned disposable backend, storage and AVD removed; existing app preserved.', flush=True)


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('action', choices=['build', 'emulator', 'start', 'stop', 'labels', 'tap', 'text', 'back', 'capture', 'api'])
    parser.add_argument('value', nargs='?'); parser.add_argument('--index', type=int, default=0); args = parser.parse_args()
    if args.action in ('build', 'emulator', 'start', 'stop'): globals()[args.action]()
    elif args.action == 'labels': print(json.dumps(h.labels(), ensure_ascii=True))
    elif args.action == 'tap': h.tap(args.value, occurrence=args.index)
    elif args.action == 'text': h.enter(args.value, args.index)
    elif args.action == 'back': h.adb('shell', 'input', 'keyevent', '4')
    elif args.action == 'capture': h.capture(args.value)
    elif args.action == 'api':
        if not args.value.startswith(('/api/ceramics', '/api/chat/conversations/', '/api/account/settings')): raise ValueError('Only isolated acceptance reads allowed')
        print(json.dumps(h.request(h.session(h.load()), args.value), ensure_ascii=True))

if __name__ == '__main__':
    try: main()
    except Exception as error:
        print(f'Acceptance stopped: {type(error).__name__}: {error}', flush=True); raise SystemExit(1)
