#!/usr/bin/env bash
# Keep the redesign constraints in the normal test command.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
python3 - <<'PY'
from pathlib import Path
import re,sys
root=Path('lib')
errors=[]
for path in sorted(root.rglob('*.dart')):
    name=path.as_posix();text=path.read_text();lines=text.splitlines()
    for i,line in enumerate(lines):
        def fail(reason):errors.append(f'{name}:{i+1}: {reason}')
        if re.search(r'\b(?:Icons|FluentIcons)\.',line) and not name.endswith('/theme/app_icons.dart'):
            fail('Use the central icon map')
        if re.search(r'Color\s*\(\s*0x|Color\.from(?:RGBO|ARGB)\s*\(|Colors\.(?!transparent\b)[a-z]',line) and not name.endswith('/theme/tokens.dart'):
            fail('Use a color token')
        if 'withOpacity(' in line or 'MaterialStateProperty' in line:
            fail('Use the current Flutter color and state APIs')
        if 'DropdownButton' in line and '/screens/' in name and '/screens/usage/' not in name:
            fail('Use the shared select control in redesigned screens')
        if re.search(r'\.(?:brand\w*|onBrand)\b',line) and not name.endswith('/theme/tokens.dart'):
            context='\n'.join(lines[max(0,i-3):i+2])
            # The theme and the shared widgets implement the Fluent brand places
            # (primary button, switch on, checkbox, progress, input focus,
            # selected card); screens may use brand only for selected markers.
            allowed=(name.endswith('/theme/theme.dart') or '/widgets/common/' in name
                or name.endswith('/screens/memory/graph_canvas.dart') and 'n.id == selected' in context
                or name.endswith('/screens/chat/chat_list.dart') and re.search(r'selected\s*\?', context)
                or name.endswith('/shell/app_shell.dart') and re.search(r'selected\s*\?', context)
                or name.endswith('/shell/settings_page.dart') and re.search(r'selected\s*\?', context)
                or name.endswith('/screens/chat/composer.dart') and '_focus.hasFocus' in context)
            if not allowed:fail('Brand is reserved for the Fluent brand places (issue #59, section 2)')
if errors:
    print('\n'.join(errors));sys.exit(1)
print('Design checks passed')
PY
