import json
import requests

url = "http://peirene.disi.unitn.it:30002/api/clients"
observe_url = 'http://peirene.disi.unitn.it:30002/api/clients/{endpoint}/3303/0/5700/observe'

r = requests.get(url=url)
devices = r.json()
print(f'{len(devices)} registered devices')

for device in devices:
	r = requests.post(url=observe_url.format(endpoint=device['endpoint']))
	print(f'Endpoint {device["endpoint"]} observer activated for temperature sensor. Current value {r.json()["content"]["value"]}')

