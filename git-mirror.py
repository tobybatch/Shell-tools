import urllib2, base64, json
import pdb
from os import path
from subprocess import call
import os

url = 'https://github.com/api/v2/json/organizations/repositories?owned=1'
token = 'neontribe-pull-bot/token:b1b7abf86c52400f5221c4c82a87f749'
target = '/opt/git-backup'

req = urllib2.Request(url)

base64string = base64.encodestring(token)

authheader =  "Basic %s" % base64string
req.add_header("Authorization", authheader)
res = urllib2.urlopen(req)
headers = res.info().headers

jsondata = res.read()
data = json.loads(jsondata)
# pdb.set_trace()

for repositories in data['repositories']:
  _url = repositories['url']
  name = path.basename(_url)

  target_folder = target + '/' + name
  if path.exists(target_folder):
    # cd foleder & update
    os.chdir(target_folder)
    cmd = 'git fetch -q'
  else:
    # git clone url target_folder
    cmd = 'git clone ' + token + '@' + url + ' ' + target_folder

print cmd
os.system(cmd)
