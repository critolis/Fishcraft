"""Read-only privacy audit of the Fishcraft tree and every local Git blob.

Reports file names or object IDs, never matching values. This is a focused
heuristic scan and manual-review aid, not proof that all possible secrets are absent.
"""
from pathlib import Path
import re
import subprocess
import sys
import package

ROOT = Path(__file__).resolve().parents[1]
SIGNATURES = [
    rb'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----',
    rb'\bgh[pousr]_[A-Za-z0-9]{20,}\b',
    rb'\bgithub_pat_[A-Za-z0-9_]{30,}\b',
    rb'\bAKIA[A-Z0-9]{16}\b',
    rb'\bxox[baprs]-[A-Za-z0-9-]{16,}\b',
    rb'(?i)(?:api[_-]?key|password|passwd|client[_-]?secret|access[_-]?token)\s*[:=]\s*["\'][^"\'\n]{8,}["\']',
    rb'(?i)[A-Z]:[\\/]+Users[\\/]+[^\s"\']+',
    rb'/(?:Users|home)/[A-Za-z0-9_.-]+/',
]


def git(*args, allow_failure=False):
    result = subprocess.run(['git', '-C', str(ROOT), *args], capture_output=True)
    if result.returncode and not allow_failure:
        raise RuntimeError('Git audit command failed: ' + args[0])
    return result.stdout


def suspicious(data):
    return any(re.search(pattern, data) for pattern in SIGNATURES)


def main():
    failures = []
    public = package.source_files(ROOT)
    package.scan_public_files(ROOT, public)
    for name in public:
        if suspicious((ROOT / name).read_bytes()):
            failures.append('Potential sensitive content: ' + name)
    top = Path(git('rev-parse', '--show-toplevel').decode().strip()).resolve()
    if top != ROOT:
        raise RuntimeError('Run against the standalone Fishcraft repository, not its parent')
    indexed = set(git('ls-files', '-z').decode().split('\0')) - {''}
    for name in indexed - set(public):
        failures.append('Unexpected indexed file: ' + name)
    untracked = set(git('ls-files', '--others', '--exclude-standard', '-z').decode().split('\0')) - {''}
    for name in untracked - set(public):
        failures.append('Unexpected untracked file: ' + name)
    # All local objects includes objects reachable only through deleted refs or
    # reflogs, as well as unreachable objects that have not been pruned.
    objects = git('cat-file', '--batch-all-objects', '--batch-check=%(objectname) %(objecttype)').decode().splitlines()
    blobs = 0
    for line in objects:
        object_id, kind = line.split()
        if kind == 'blob':
            blobs += 1
            if suspicious(git('cat-file', 'blob', object_id)):
                failures.append('Potential sensitive content in Git blob: ' + object_id)
        elif kind in {'commit', 'tag'}:
            content = git('cat-file', kind, object_id)
            if suspicious(content):
                failures.append('Potential sensitive content in Git metadata: ' + object_id)
            # Personal identities belong in an explicit review, including deleted history.
            for address in re.findall(rb'<([^<>\s]+@[^<>\s]+)>', content):
                if not address.endswith(b'@users.noreply.github.com'):
                    failures.append('Review author email in Git object: ' + object_id)
    commits = git('rev-list', '--all', '--count').decode().strip() or '0'
    remotes = git('remote', '-v')
    if re.search(rb'https?://[^/\s]+@', remotes):
        failures.append('Credential-like remote URL; value withheld')
    workflow = (ROOT / '.github/workflows/validate.yml').read_text(encoding='utf8')
    for forbidden in ['pull_request_target:', 'secrets.', 'contents: write', 'write-all', 'gh release', 'curl ']:
        if forbidden in workflow:
            failures.append('Workflow needs security review: ' + forbidden)
    package.require('persist-credentials: false' in workflow, 'Checkout credentials would persist')
    for ref in re.findall(r'uses: ([^\s]+)', workflow):
        package.require(re.fullmatch(r'actions/[a-z-]+@[a-f0-9]{40}', ref), 'Unpinned/unexpected Action')
    print(f'Audited {len(public)} allowlisted source files; {len(indexed)} indexed files; '
          f'{commits} reachable commits; {blobs} local Git blobs including unreachable objects.')
    if failures:
        print('\n'.join(failures))
        return 1
    print('PASS: no detected credential signatures or personal paths; source scope and workflow checks passed.')
    print('Review limitation: uncommon secrets, authorship and personal meaning require human judgment.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
