"""Native Android notebook acceptance helpers; all server data is disposable.

See MOBILE_TESTING.md. Uses Python's standard library, ADB and Docker only.
Credentials are random and the local checkpoint is encrypted with Windows DPAPI.
"""
import argparse
import ctypes
from ctypes import wintypes
import http.cookiejar
import hashlib
import json
import os
from pathlib import Path
import re
import socket
import shutil
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
BACKEND = ROOT.parent / 'clay_dock_backend'
OUT = ROOT / 'build' / 'notebook-mobile-acceptance'
SDK = Path(os.environ['LOCALAPPDATA']) / 'Android' / 'Sdk'
ADB = SDK / 'platform-tools' / 'adb.exe'
SERIAL = 'emulator-5560'
PORT = 18082
BASE = f'http://127.0.0.1:{PORT}'
PACKAGE = 'nu.miguel.claydock'
LABEL = 'keramik.acceptance=notebook-android-disposable'


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    flutter = Path(os.environ.get('FLUTTER_ROOT', str(Path.home() / 'develop' / 'flutter'))) / 'bin' / 'flutter.bat'
    output = command(['cmd.exe', '/d', '/c', flutter, 'build', 'apk', '--debug', '--no-pub',
                      '--dart-define=API_BASE_URL=http://10.0.2.2:18082'], timeout=480, cwd=ROOT)
    (OUT / 'acceptance-apk-build.log').write_bytes(output)
    apk = OUT / 'acceptance-debug.apk'
    shutil.copy2(ROOT / 'build/app/outputs/flutter-apk/app-debug.apk', apk)
    (OUT / 'apk-metadata.json').write_text(json.dumps({
        'api_base': 'http://10.0.2.2:18082', 'sha256': hashlib.sha256(apk.read_bytes()).hexdigest()
    }), encoding='utf-8')
    print('Isolated Android acceptance APK built and fingerprinted.')


def emulator():
    devices = command([ADB, 'devices']).decode()
    if SERIAL in devices:
        raise RuntimeError('Acceptance emulator port is occupied; existing device left untouched')
    OUT.mkdir(parents=True, exist_ok=True)
    with (OUT / 'emulator.out.log').open('wb') as stdout, (OUT / 'emulator.err.log').open('wb') as stderr:
        process = subprocess.Popen([str(SDK / 'emulator/emulator.exe'), '-avd', 'Medium_Phone_2',
                                    '-read-only', '-no-snapshot', '-no-window', '-no-audio',
                                    '-no-boot-anim', '-port', '5560'], stdout=stdout, stderr=stderr,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
    (OUT / 'emulator.pid').write_text(str(process.pid), encoding='ascii')
    print('Read-only secondary AVD launched on the dedicated acceptance port.')


def verify_emulator():
    command(['powershell.exe', '-NoProfile', '-Command',
             "$p=@(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^(emulator|qemu).*exe$' -and "
             "$_.CommandLine -match '-read-only' -and $_.CommandLine -match '-port[ =]+5560(?: |$)' }); "
             "if($p.Count -eq 0){exit 1}"])


class Blob(ctypes.Structure):
    _fields_ = [('length', wintypes.DWORD), ('data', ctypes.POINTER(ctypes.c_byte))]


def protected(data, decrypt=False):
    buffer = ctypes.create_string_buffer(data)
    source = Blob(len(data), ctypes.cast(buffer, ctypes.POINTER(ctypes.c_byte)))
    result = Blob()
    fn = ctypes.windll.crypt32.CryptUnprotectData if decrypt else ctypes.windll.crypt32.CryptProtectData
    if not fn(ctypes.byref(source), None, None, None, None, 1, ctypes.byref(result)):
        raise RuntimeError('Windows-user checkpoint encryption failed')
    try:
        return ctypes.string_at(result.data, result.length)
    finally:
        ctypes.windll.kernel32.LocalFree(result.data)


def save(state):
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'state.dpapi').write_bytes(protected(json.dumps(state).encode()))


def load():
    return json.loads(protected((OUT / 'state.dpapi').read_bytes(), decrypt=True))


def command(args, timeout=40, cwd=None):
    process = subprocess.Popen([str(a) for a in args], cwd=cwd, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, creationflags=subprocess.CREATE_NO_WINDOW)
    try:
        stdout, _ = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'],
                       capture_output=True, timeout=15, creationflags=subprocess.CREATE_NO_WINDOW)
        process.communicate(timeout=15)
        raise RuntimeError(f'{Path(str(args[0])).name} exceeded its {timeout}-second limit') from None
    if process.returncode:
        raise RuntimeError(f'{Path(str(args[0])).name} operation failed; sensitive output withheld')
    return stdout


def adb(*args):
    return command([ADB, '-s', SERIAL, *args])


def tree():
    for _ in range(5):
        raw = adb('exec-out', 'uiautomator', 'dump', '/dev/tty').decode('utf-8', errors='replace')
        start, end = raw.find('<?xml'), raw.find('</hierarchy>')
        if start >= 0 and end >= 0:
            return ET.fromstring(raw[start:end + len('</hierarchy>')])
        time.sleep(.8)
    raise RuntimeError('Android accessibility hierarchy unavailable')


def nodes():
    return list(tree().iter('node'))


def labels():
    return [n.get('content-desc') or n.get('text') or n.get('hint') for n in nodes()
            if n.get('password') != 'true' and (n.get('content-desc') or n.get('text') or n.get('hint'))]


def tap(label, contains=False, occurrence=0):
    found = [n for n in nodes() if any(
        label in n.get(a, '') if contains else label == n.get(a, '')
        for a in ('text', 'content-desc'))]
    if not found and not contains:
        found = [n for n in nodes() if any(label in n.get(a, '') for a in ('text', 'content-desc'))]
    if len(found) <= occurrence:
        raise RuntimeError(f'Android control missing: {label}')
    tap_node(found[occurrence])


def tap_node(node):
    if node.get('enabled') == 'false':
        raise RuntimeError('Expected Android control is disabled')
    x1, y1, x2, y2 = map(int, re.findall(r'\d+', node.get('bounds')))
    adb('shell', 'input', 'tap', str((x1 + x2) // 2), str((y1 + y2) // 2))
    time.sleep(.6)


def scroll_to(label):
    hide_keyboard()
    for _ in range(7):
        if any(label in n.get(attribute, '') for n in nodes() for attribute in ('content-desc', 'text', 'hint')):
            return
        width, height = map(int, re.findall(rb'(\d+)x(\d+)', adb('shell', 'wm', 'size'))[-1])
        # Stay in page padding, outside multiline fields' internal scrolling.
        adb('shell', 'input', 'swipe', str(width - 8), str(height * 3 // 4), str(width - 8), str(height // 3), '400')
        time.sleep(.4)
    raise RuntimeError(f'Android control not reachable by scrolling: {label}')


def hide_keyboard():
    info = adb('shell', 'dumpsys', 'input_method')
    current = re.search(rb'^\s*mInputShown[=:]\s*(true|false)', info, re.MULTILINE)
    if current and current[1] == b'true':
        adb('shell', 'input', 'keyevent', '4')
        time.sleep(.4)


def enter(value, index=0, replace=False):
    fields = [n for n in nodes() if n.get('class') == 'android.widget.EditText']
    tap_node(fields[index])
    if replace:
        adb('shell', 'input', 'keyevent', '123')
        adb('shell', 'input', 'keyevent', *(['67'] * 105))
    adb('shell', 'input', 'text', value.replace(' ', '%s'))
    time.sleep(.4)


def enter_hint(hint, value, replace=False):
    fields = [n for n in nodes() if n.get('class') == 'android.widget.EditText' and
              any(hint in n.get(attribute, '') for attribute in ('hint', 'content-desc', 'text'))]
    if len(fields) != 1:
        raise RuntimeError(f'Android text field unavailable: {hint}')
    tap_node(fields[0])
    if replace:
        adb('shell', 'input', 'keyevent', '123', *(['67'] * 105))
    adb('shell', 'input', 'text', value.replace(' ', '%s'))
    time.sleep(.4)


def wait(label, timeout=35):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            if any(label in v for v in labels()):
                return
        except (RuntimeError, subprocess.TimeoutExpired):
            pass
        time.sleep(.6)
    raise RuntimeError(f'Timed out waiting for Android screen: {label}')


def capture(name):
    if not re.fullmatch(r'[a-z0-9_-]+', name):
        raise ValueError('Invalid screenshot name')
    hierarchy = tree()
    time.sleep(.8)
    (OUT / f'{name}.png').write_bytes(adb('exec-out', 'screencap', '-p'))
    (OUT / f'{name}.xml').write_text(ET.tostring(hierarchy, encoding='unicode'), encoding='utf-8')
    print(f'Screenshot saved: {name}.png', flush=True)


def client():
    return urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))


def request(opener, path, body=None, method=None, content_type='application/json'):
    data = None if body is None else (json.dumps(body).encode() if content_type == 'application/json' else body)
    req = urllib.request.Request(BASE + path, data=data, method=method,
                                 headers={'Content-Type': content_type} if data else {})
    try:
        with opener.open(req, timeout=15) as response:
            raw = response.read()
            return json.loads(raw) if raw.startswith(b'{') else raw.decode()
    except urllib.error.HTTPError as error:
        raise RuntimeError(f'Isolated API request failed: {method or "GET"} {path} ({error.code})') from None


def form(opener, path, fields, csrf_page):
    html = request(opener, csrf_page)
    match = re.search(r'name="_csrf"[^>]*value="([^"]+)"', html)
    if not match:
        raise RuntimeError('Isolated website CSRF token unavailable')
    fields['_csrf'] = match[1]
    return request(opener, path, urllib.parse.urlencode(fields).encode(), content_type='application/x-www-form-urlencoded')


def session(state):
    opener = client()
    form(opener, '/login', {'username': state['username'], 'password': state['password']}, '/login')
    request(opener, '/api/account/me')
    return opener


def seed_piece():
    state = load()
    opener = session(state)
    stages = request(opener, '/api/stages')['data']
    clays = request(opener, '/api/clay')['data']
    piece = {'title': 'Acceptance bowl', 'clayTypeId': clays[0]['id'], 'weight': .4,
             'note': 'Keep this note', 'rating': 3, 'stageId': stages[0]['id'], 'tags': [],
             'glazes': [{'id': 0, 'glazeId': state['glazes'][1], 'ceramicId': 0,
                         'note': 'Existing layer', 'layerOrder': 1, 'coatCount': 1}],
             'heightCm': 12, 'widthCm': None, 'depthCm': None, 'diameterCm': 8,
             'outcomeNote': 'Keep this outcome'}
    boundary = 'acceptance' + uuid.uuid4().hex
    payload = (f'--{boundary}\r\nContent-Disposition: form-data; name="data"\r\n'
               'Content-Type: application/json\r\n\r\n' + json.dumps(piece) + f'\r\n--{boundary}--\r\n').encode()
    created = request(opener, '/api/ceramics', payload, content_type='multipart/form-data; boundary=' + boundary)['data']
    state['piece_id'] = created['id']
    state['piece_before'] = request(opener, '/api/ceramics/' + str(created['id']))['data']
    save(state)
    print('Synthetic piece with existing glaze, clay, dimensions and notes created.', flush=True)


def start():
    OUT.mkdir(parents=True, exist_ok=True)
    if (OUT / 'state.dpapi').exists():
        raise RuntimeError('Acceptance state already exists; stop the previous run first')
    with socket.socket() as sock:
        if sock.connect_ex(('127.0.0.1', PORT)) == 0:
            raise RuntimeError('Isolated backend port is occupied')
    if not (OUT / 'emulator.pid').exists():
        raise RuntimeError('Start the documented read-only acceptance emulator first')
    verify_emulator()
    apk = OUT / 'acceptance-debug.apk'
    metadata = json.loads((OUT / 'apk-metadata.json').read_text(encoding='utf-8'))
    if metadata['api_base'] != 'http://10.0.2.2:18082' or metadata['sha256'] != hashlib.sha256(apk.read_bytes()).hexdigest():
        raise RuntimeError('Build a fingerprinted APK for the isolated endpoint before testing')
    state = {'container': 'keramik-notebook-android-' + uuid.uuid4().hex[:12],
             'username': 'notebook_' + uuid.uuid4().hex[:10],
             'password': uuid.uuid4().hex + 'Aa9', 'access': 'acceptance' + uuid.uuid4().hex[:10],
             'secret': uuid.uuid4().hex + uuid.uuid4().hex, 'checks': []}
    save(state)
    command(['docker', 'run', '--detach', '--name', state['container'], '--label', LABEL,
             '--publish', '127.0.0.1::9000', '--env', 'MINIO_ROOT_USER=' + state['access'],
             '--env', 'MINIO_ROOT_PASSWORD=' + state['secret'],
             'keramik-local/minio:RELEASE.2025-04-22T22-12-26Z', 'server', '/data'])
    port = command(['docker', 'port', state['container'], '9000/tcp']).decode().strip()
    if not re.fullmatch(r'127\.0\.0\.1:\d+', port):
        raise RuntimeError('Isolated storage binding is not loopback')
    state['minio_port'] = int(port.split(':')[1])
    save(state)
    for _ in range(45):
        try:
            urllib.request.urlopen('http://' + port + '/minio/health/ready', timeout=2).close()
            break
        except (OSError, urllib.error.URLError):
            time.sleep(1)
    command(['docker', 'run', '--rm', '--network', 'container:' + state['container'],
             '--env', 'MINIO_ROOT_USER=' + state['access'], '--env', 'MINIO_ROOT_PASSWORD=' + state['secret'],
             '--entrypoint', '/bin/sh', 'keramik-local/mc:RELEASE.2025-04-16T18-13-26Z', '-c',
             'mc alias set local http://127.0.0.1:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD >/dev/null && '
             'mc mb local/images local/avatars >/dev/null && mc anonymous set none local/images >/dev/null && '
             'mc anonymous set download local/avatars >/dev/null'])
    env = os.environ.copy()
    env.update({'MINIO_URL': 'http://' + port, 'MINIO_PUBLIC_URL': f'http://10.0.2.2:{state["minio_port"]}',
                'MINIO_ACCESS_KEY': state['access'], 'MINIO_SECRET_KEY': state['secret'],
                'MINIO_BUCKET': 'images', 'MINIO_AVATAR_BUCKET': 'avatars'})
    with (OUT / 'backend.out.log').open('wb') as stdout, (OUT / 'backend.err.log').open('wb') as stderr:
        process = subprocess.Popen(['cmd.exe', '/d', '/c', str(BACKEND / 'gradlew.bat'), 'bootTestRun',
                                    '--args=--spring.profiles.active=test --server.port=18082 --server.address=127.0.0.1'],
                                   cwd=BACKEND, env=env, stdout=stdout, stderr=stderr,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
    state['backend_pid'] = process.pid
    save(state)
    deadline = time.monotonic() + 100
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise RuntimeError('Isolated backend exited; inspect private startup logs')
        try:
            if request(client(), '/actuator/health/readiness')['status'] == 'UP':
                break
        except (OSError, RuntimeError):
            time.sleep(1)
    else:
        raise RuntimeError('Isolated backend readiness timed out')
    print('Isolated H2/MinIO backend ready.', flush=True)
    opener = client()
    form(opener, '/signup', {'forename': 'Notebook', 'surname': 'Acceptance', 'username': state['username'],
         'email': state['username'] + '@example.invalid', 'password': state['password'],
         'passwordConfirmation': state['password']}, '/signup')
    form(opener, '/login', {'username': state['username'], 'password': state['password']}, '/login')
    state['glazes'] = [request(opener, '/api/glaze', {'title': title})['data']['id']
                       for title in ['Ocean blue', 'Warm white']]
    save(state)
    deadline = time.monotonic() + 90
    while time.monotonic() < deadline:
        try:
            if adb('shell', 'getprop', 'sys.boot_completed').strip() == b'1':
                break
        except RuntimeError:
            pass
        time.sleep(1)
    command([ADB, '-s', SERIAL, 'install', '-r', apk], timeout=90)
    # Only the explicitly launched read-only copy is reset; original AVD state survives.
    adb('shell', 'pm', 'clear', PACKAGE)
    adb('shell', 'monkey', '-p', PACKAGE, '1')
    wait('Welcome back')
    enter(state['username'], 0)
    enter(state['password'], 1)
    adb('shell', 'input', 'keyevent', '4')
    tap('Log in')
    wait('Ceramic journal', 45)
    print('Current APK installed and authenticated on the disposable emulator.', flush=True)


def stop():
    state = load()
    # The Gradle daemon can own the app process outside the client process tree.
    command(['powershell.exe', '-NoProfile', '-Command',
             "$ids=@(Get-NetTCPConnection -LocalPort 18082 -State Listen -ErrorAction SilentlyContinue | "
             "Select-Object -ExpandProperty OwningProcess -Unique); foreach($id in $ids){"
             "$p=Get-CimInstance Win32_Process -Filter ('ProcessId='+$id); "
             "if($p.Name -ne 'java.exe' -or $p.CommandLine -notmatch 'server.port=18082' -or "
             "$p.CommandLine -notmatch 'spring.profiles.active=test'){throw 'Acceptance process mismatch'}; "
             "Stop-Process -Id $id}"])
    if state.get('backend_pid'):
        subprocess.run(['taskkill', '/PID', str(state['backend_pid']), '/T', '/F'],
                       capture_output=True, creationflags=subprocess.CREATE_NO_WINDOW)
    info = json.loads(command(['docker', 'inspect', state['container']]))[0]
    if info['Config']['Labels'].get('keramik.acceptance') != 'notebook-android-disposable':
        raise RuntimeError('Disposable storage cleanup ownership mismatch')
    command(['docker', 'rm', '--force', state['container']])
    verify_emulator()
    adb('emu', 'kill')
    (OUT / 'results.json').write_text(json.dumps({'checks': state['checks']}, indent=2), encoding='utf-8')
    (OUT / 'state.dpapi').unlink()
    print('Disposable backend, storage and read-only emulator stopped; original app data preserved.')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['build', 'emulator', 'start', 'labels', 'tap', 'text', 'back', 'scroll', 'capture', 'stop', 'api'])
    parser.add_argument('value', nargs='?')
    parser.add_argument('--index', type=int, default=0)
    args = parser.parse_args()
    if args.action == 'build':
        build()
    elif args.action == 'emulator':
        emulator()
    elif args.action == 'start':
        start()
    elif args.action == 'stop':
        stop()
    elif args.action == 'labels':
        print(json.dumps(labels(), ensure_ascii=True))
    elif args.action == 'tap':
        tap(args.value, occurrence=args.index)
    elif args.action == 'text':
        enter(args.value, args.index)
    elif args.action == 'back':
        adb('shell', 'input', 'keyevent', '4')
    elif args.action == 'scroll':
        width, height = map(int, re.findall(rb'(\d+)x(\d+)', adb('shell', 'wm', 'size'))[-1])
        adb('shell', 'input', 'swipe', str(width // 2), str(height * 3 // 4), str(width // 2), str(height // 3), '400')
    elif args.action == 'capture':
        capture(args.value)
    elif args.action == 'api':
        state = load()
        # Notebook-only data belongs solely to the ephemeral acceptance account.
        if not args.value.startswith(('/api/glaze-combinations', '/api/test-tiles')):
            raise ValueError('Only disposable notebook reads are allowed')
        print(json.dumps(request(session(state), args.value), ensure_ascii=True))


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(f'Acceptance stopped: {type(error).__name__}: {error}', flush=True)
        raise SystemExit(1)
