import json
import os

apps_json_path = r'd:\04_DEVELOPMENT\GandiWin\Win11Debloat-master\Config\Apps.json'
out_path = r'd:\04_DEVELOPMENT\GandiWin\wintweaker\data\uwp_apps.py'

with open(apps_json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

apps = data['Apps']

output = "UWP_APPS = [\n"
for app in apps:
    app_id = app.get('AppId', '')
    name = app.get('FriendlyName', '')
    desc = app.get('Description', '').replace('"', '\\"')
    # Using python boolean
    selected = app.get('SelectedByDefault', False)
    
    output += f'    {{"id": "{app_id}", "name": "{name}", "desc": "{desc}", "selected": {selected}}},\n'

output += "]\n"

with open(out_path, 'w', encoding='utf-8') as f:
    f.write(output)

print("Done generating uwp_apps.py")
