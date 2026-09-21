import json
import re

with open('lib/core/database/questions/questions.json', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace any missing comma between string values
# E.g. ""options"" -> "",\n"options""
text = re.sub(r'\"\"options\"', '",\n"options"', text)

# Just in case, replace trailing comma at the end of the file or incomplete end
# We'll use a regex to extract all valid objects.
pattern = re.compile(r'\{\s*"question_id".*?"explanation"\s*:\s*"[^"]*"\s*\}', re.DOTALL)
matches = pattern.findall(text)

valid_json = '[\n' + ',\n'.join(matches) + '\n]'

with open('lib/core/database/questions/questions_fixed.json', 'w', encoding='utf-8') as f:
    f.write(valid_json)

try:
    questions = json.loads(valid_json)
    print(f'Successfully recovered {len(questions)} questions.')
except Exception as e:
    print('Still invalid JSON:', e)
