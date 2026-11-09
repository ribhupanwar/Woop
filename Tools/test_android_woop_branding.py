"""Visible Android branding must not drift back to the upstream product name."""
import pathlib
import re
import unittest
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]


class AndroidWoopBrandingTests(unittest.TestCase):
    def test_localized_product_copy_uses_woop(self):
        for path in (ROOT / 'android/app/src').glob('*/res/values*/strings.xml'):
            for node in ET.parse(path).getroot().iter('string'):
                # A technical component diagnostic is an identifier, not a product name.
                if node.attrib.get('name') == 'l10n_noop_button_noopbutton_scale_1bee88be':
                    continue
                value = ''.join(node.itertext())
                self.assertIsNone(re.search(r'\b(?:NOOP|Noop)\b|NOOPs\b', value),
                                  f'{path.name}: {node.attrib.get("name")}')

    def test_manifest_exposes_product_name_without_renaming_components(self):
        path = ROOT / 'android/app/src/main/AndroidManifest.xml'
        namespace = '{http://schemas.android.com/apk/res/android}'
        for node in ET.parse(path).getroot().iter():
            label = node.attrib.get(namespace + 'label', '')
            self.assertNotIn('NOOP', label)
        self.assertIn('com.noop.ui.MainActivity', path.read_text())

    def test_forge_wordmark_uses_only_woop(self):
        source = (ROOT / 'android/app/src/main/java/com/noop/ui/forge/ForgeMark.kt').read_text()
        self.assertIn('BRAND = "Woop"', source)
        self.assertIn('BRAND_LETTERS = "WOOP"', source)
        self.assertNotIn('ForgeMark(14.dp)', source)


if __name__ == '__main__':
    unittest.main()
