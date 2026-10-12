"""Regression tests for the release boundary; addon behavior lives in spec.lua."""
from pathlib import Path
import hashlib
import importlib.util
import shutil
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('fishcraft_package', ROOT / 'tools/package.py')
package = importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)


class PackagingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / 'Fishcraft'
        shutil.copytree(ROOT, self.root, ignore=shutil.ignore_patterns(
            '.git', 'dist', '__pycache__', '.venv'))

    def test_clean_runtime_and_matching_source(self):
        private = self.root / 'SavedVariables'
        private.mkdir()
        (private / 'Character.lua').write_text('private fixture', encoding='utf8')
        (self.root / '.env').write_text('private fixture', encoding='utf8')
        install, source, _, _ = package.build(self.root)
        with zipfile.ZipFile(install) as z:
            self.assertIn('Fishcraft/Fishcraft.toc', z.namelist())
            self.assertIn('Fishcraft/LICENSE', z.namelist())
            self.assertIn('Fishcraft/SOURCE.txt', z.namelist())
            self.assertFalse(any('/tests/' in n or '/tools/' in n or '/docs/' in n
                                 or '/.github/' in n for n in z.namelist()))
            for name in z.namelist():
                if name.endswith(('.lua', '.tga')):
                    self.assertEqual(z.read(name), (self.root / name.removeprefix('Fishcraft/')).read_bytes())
        with zipfile.ZipFile(source) as z:
            self.assertIn('Fishcraft/tools/build_media.py', z.namelist())
            self.assertIn('Fishcraft/.github/workflows/validate.yml', z.namelist())
            self.assertFalse(any('SavedVariables' in n or '.env' in n or '/.git/' in n for n in z.namelist()))

    def test_reproducible_archives(self):
        paths = package.build(self.root)[:2]
        before = [hashlib.sha256(p.read_bytes()).hexdigest() for p in paths]
        package.build(self.root)
        self.assertEqual(before, [hashlib.sha256(p.read_bytes()).hexdigest() for p in paths])

    def test_release_tag_must_match_version(self):
        with self.assertRaisesRegex(ValueError, 'Tag must match'):
            package.build(self.root, tag='v9.9.9')

    def test_missing_texture_rejected(self):
        (self.root / 'Media/SessionStart.tga').unlink()
        with self.assertRaisesRegex(ValueError, 'Missing/linked file'):
            package.validate(self.root)

    def test_escaping_toc_path_rejected(self):
        toc = self.root / 'Fishcraft.toc'
        toc.write_text(toc.read_text(encoding='utf8') + '\n../outside.lua\n', encoding='utf8')
        with self.assertRaisesRegex(ValueError, 'Unexpected TOC entry'):
            package.validate(self.root)

    def test_credential_in_source_rejected_without_echo(self):
        fixture = 'gh' + 'p_' + 'a' * 36
        (self.root / 'tools/fixture.py').write_text('value = "' + fixture + '"', encoding='utf8')
        with self.assertRaisesRegex(ValueError, 'Potential credential') as failure:
            package.validate(self.root)
        self.assertNotIn(fixture, str(failure.exception))

    def test_personal_path_in_source_rejected(self):
        path = 'C:' + '/' + 'Users/' + 'PrivatePerson/project'
        (self.root / 'docs/fixture.md').write_text(path, encoding='utf8')
        with self.assertRaisesRegex(ValueError, 'personal path'):
            package.validate(self.root)


if __name__ == '__main__':
    unittest.main()
