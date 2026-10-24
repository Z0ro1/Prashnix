

import json
import re

with open('lib/core/database/questions/questions.json', 'r', encoding='utf-8') as f:
    text = f.read()

# Try to find the exact cut off.
# Or just regex extract the objects.
pattern = re.compile(r'\{\s*"question_id".*?"explanation"[^\}]*\}', re.DOTALL)
matches = pattern.findall(text)

valid_json = '[\n' + ',\n'.join(matches) + '\n]'

with open('lib/core/database/questions/questions.json', 'w', encoding='utf-8') as f:
    f.write(valid_json)

try:
    json.loads(valid_json)
    print(f'Successfully recovered {len(matches)} questions.')
except Exception as e:
    print('Still invalid JSON:', e)
