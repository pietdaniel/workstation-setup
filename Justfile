# Zips and copies latest alfred preferences to this repo
update-alfred-prefs:
  zip -r prefs.zip ~/Library/Application\ Support/Alfred/Alfred.alfredpreferences && \
  mv ./prefs.zip  roles/alfred/files/prefs.zip

run-tag tag:
  ansible-playbook -vvv -i localhost, playbook.yaml --connection=local --tags={{tag}}
