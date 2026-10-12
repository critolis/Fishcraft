"""Validate and build Fishcraft installable and corresponding-source ZIPs.

Python standard library only. Run from any directory; outputs are deterministic.
"""
from pathlib import Path, PurePosixPath
import argparse
import hashlib
import re
import struct
import zipfile

ROOT = Path(__file__).resolve().parents[1]
MODULE_DIRS = {
    'Compatibility', 'Cooking', 'Core', 'Data', 'Equipment', 'Fishing',
    'Journal', 'Localization', 'Locations', 'Lures', 'UI',
}
ROOT_FILES = {
    '.gitignore', '.gitattributes', 'Fishcraft.toc', 'README.md', 'LICENSE',
    'COPYRIGHT', 'THIRD_PARTY_NOTICES.md', 'CONTRIBUTING.md', 'CHANGELOG.md',
    'INSTALL.txt', 'requirements-dev.txt',
}
EXTRA_SOURCE = {
    'docs': {'.md', '.sha256'}, 'tests': {'.lua', '.py'}, 'tools': {'.py'},
    '.github': {'.yml'},
}
PRIVATE_PARTS = {
    '.git', '.env', '.aws', '.ssh', '.codex', '.agents', '.venv', 'venv',
    '__pycache__', 'savedvariables', 'wtf', 'logs', 'local', 'work', 'tmp', 'dist',
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def resolve_file(root, name):
    rel = PurePosixPath(name)
    require(not rel.is_absolute() and '..' not in rel.parts and ':' not in name,
            f'Unsafe relative path: {name}')
    path = root.joinpath(*rel.parts)
    require(path.resolve().is_relative_to(root.resolve()), f'Escaping path: {name}')
    require(not path.is_symlink() and path.is_file(), f'Missing/linked file: {name}')
    # Enforce case even on a case-insensitive host.
    parent = root
    for part in rel.parts:
        require(part in {p.name for p in parent.iterdir()}, f'Path case mismatch: {name}')
        parent /= part
    return path


def toc_info(root):
    toc = resolve_file(root, 'Fishcraft.toc').read_text(encoding='utf-8-sig')
    version = re.search(r'^## Version: (.+)$', toc, re.M)
    require(version is not None, 'TOC version missing')
    version = version[1].strip()
    require(re.fullmatch(r'\d+\.\d+\.\d+(?:-[A-Za-z0-9.]+)?', version), 'Invalid version')
    require('## Interface: 16001' in toc, 'Unexpected client interface')
    require('## X-License: GPL-3.0-only' in toc, 'Missing GPLv3-only metadata')
    entries = [s.strip().replace('\\', '/') for s in toc.splitlines()
               if s.strip() and not s.lstrip().startswith('#')]
    require(len(entries) == len(set(entries)), 'Duplicate TOC entries')
    for name in entries:
        require(PurePosixPath(name).parts[0] in MODULE_DIRS and name.endswith('.lua'),
                f'Unexpected TOC entry: {name}')
        resolve_file(root, name)
    actual = {p.relative_to(root).as_posix() for directory in MODULE_DIRS
              for p in (root / directory).rglob('*.lua')}
    require(set(entries) == actual, 'Runtime Lua files and TOC do not match')
    bootstrap = (root / 'Core/Bootstrap.lua').read_text(encoding='utf-8')
    require(f'F.name, F.version = name, "{version}"' in bootstrap,
            'Bootstrap and TOC version differ')
    return version, entries


def source_files(root):
    names = set(ROOT_FILES)
    for directory in MODULE_DIRS:
        names.update(p.relative_to(root).as_posix() for p in (root / directory).rglob('*.lua'))
    names.update(p.relative_to(root).as_posix() for p in (root / 'Media').glob('*.tga'))
    for directory, suffixes in EXTRA_SOURCE.items():
        for p in (root / directory).rglob('*'):
            rel = p.relative_to(root)
            if p.is_file() and p.suffix in suffixes:
                if not any(s.lower() in PRIVATE_PARTS for s in rel.parts):
                    names.add(rel.as_posix())
    return sorted(names)


def scan_public_files(root, names):
    # Report only file names, never a matching credential's value.
    patterns = [
        r'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----',
        r'\bgh[pousr]_[A-Za-z0-9]{20,}\b',
        r'\bgithub_pat_[A-Za-z0-9_]{30,}\b',
        r'\bAKIA[A-Z0-9]{16}\b',
        r'\bxox[baprs]-[A-Za-z0-9-]{16,}\b',
        r'(?i)(?:api[_-]?key|password|passwd|client[_-]?secret|access[_-]?token)\s*[:=]\s*["\'][^"\'\n]{8,}["\']',
        r'(?i)[A-Z]:[\\/]+Users[\\/]+[^\s"\']+',
        r'/(?:Users|home)/[A-Za-z0-9_.-]+/',
    ]
    for name in names:
        rel = PurePosixPath(name)
        require(not any(s.lower() in PRIVATE_PARTS or s.lower().startswith('.env')
                        for s in rel.parts), f'Private path included: {name}')
        require(rel.suffix.lower() not in {'.log', '.zip', '.pem', '.key', '.p12', '.pfx'},
                f'Private/generated file included: {name}')
        data = resolve_file(root, name).read_bytes()
        if rel.suffix == '.tga':
            continue
        text = data.decode('utf-8-sig')
        require(not any(re.search(p, text) for p in patterns),
                f'Potential credential or personal path: {name}')


def validate(root=ROOT):
    version, entries = toc_info(root)
    media = sorted(p.relative_to(root).as_posix() for p in (root / 'Media').glob('*.tga'))
    require(bool(media), 'No bundled media')
    for name in media:
        data = resolve_file(root, name).read_bytes()
        require(len(data) >= 18, f'Invalid TGA: {name}')
        width, height = struct.unpack_from('<HH', data, 12)
        require(data[2] == 2 and (width, height, data[16]) == (128, 128, 32),
                f'Unexpected TGA format: {name}')
    # Resolve literal addon paths, including names appended to Theme.media.
    for name in entries:
        code = resolve_file(root, name).read_text(encoding='utf-8')
        require(not code.startswith('\ufeff'), f'Lua BOM: {name}')
        decoded = code.replace('\\\\', '/')
        refs = re.findall(r'Interface/AddOns/Fishcraft/(Media/[A-Za-z0-9_./-]+)', decoded)
        refs += ['Media/' + s for s in re.findall(
            r'\b(?:T|F\.Theme)\.media\s*\.\.\s*["\']([A-Za-z0-9_]+)["\']', code)]
        for ref in refs:
            resolve_file(root, ref if ref.endswith('.tga') else ref + '.tga')
    toc = (root / 'Fishcraft.toc').read_text(encoding='utf-8')
    icon = re.search(r'^## IconTexture: Interface\\AddOns\\Fishcraft\\(.+)$', toc, re.M)
    require(icon is not None, 'Missing addon icon')
    resolve_file(root, icon[1].strip().replace('\\', '/') + '.tga')
    license_text = (root / 'LICENSE').read_text(encoding='utf-8')
    require('Version 3, 29 June 2007' in license_text and
            'END OF TERMS AND CONDITIONS' in license_text and len(license_text) > 34000,
            'Missing full GPLv3 text')
    # Local links in the entry documentation must resolve (external links audited separately).
    for doc in ['README.md', 'CONTRIBUTING.md', 'THIRD_PARTY_NOTICES.md']:
        for target in re.findall(r'\]\(([^)]+)\)', (root / doc).read_text(encoding='utf-8')):
            if '://' not in target and not target.startswith('#'):
                resolve_file(root, target.split('#')[0])
    names = source_files(root)
    scan_public_files(root, names)
    return version, entries, media, names


def write_zip(path, files):
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(files.items()):
            info = zipfile.ZipInfo('Fishcraft/' + name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data)
    with zipfile.ZipFile(path) as archive:
        require(archive.testzip() is None, 'Corrupt archive')
        require(set(archive.namelist()) == {'Fishcraft/' + n for n in files},
                'Unexpected archive member')


def build(root=ROOT, output=None, tag=None):
    version, entries, media, names = validate(root)
    require(tag is None or tag == 'v' + version, 'Tag must match v<TOC version>')
    output = output or root / 'dist'
    output.mkdir(parents=True, exist_ok=True)
    runtime_names = entries + media + ['Fishcraft.toc', 'LICENSE', 'COPYRIGHT',
                                      'THIRD_PARTY_NOTICES.md', 'INSTALL.txt']
    runtime = {name: (root / name).read_bytes() for name in runtime_names}
    runtime['SOURCE.txt'] = (
        f'Fishcraft {version} — corresponding source\n\n'
        f'The matching Fishcraft-{version}-source.zip accompanies this build.\n'
        'It includes original Lua, the editable texture generator, tests, build\n'
        'scripts and licensing documentation. Distribute it beside this addon ZIP.\n'
        'After extracting the source, follow README.md to rebuild.\n'
    ).encode('utf-8')
    install_zip = output / f'Fishcraft-{version}.zip'
    source_zip = output / f'Fishcraft-{version}-source.zip'
    write_zip(install_zip, runtime)
    write_zip(source_zip, {name: (root / name).read_bytes() for name in names})
    hashes = ''.join(f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}\n'
                     for p in [install_zip, source_zip])
    (output / 'SHA256SUMS.txt').write_text(hashes, encoding='utf-8')
    return install_zip, source_zip, len(runtime), len(names)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--tag', help='Require this release tag to match the TOC')
    args = parser.parse_args()
    if args.check:
        version, entries, media, names = validate()
        require(args.tag is None or args.tag == 'v' + version, 'Tag/version mismatch')
        print(f'PASS: Fishcraft {version}; {len(entries)} Lua modules, {len(media)} textures, '
              f'{len(names)} reviewed source files; paths, license, local links and privacy scan.')
    else:
        install, source, count, source_count = build(tag=args.tag)
        print(f'PASS: {install.name}: {count} runtime/legal files; {source.name}: {source_count} source files.')
