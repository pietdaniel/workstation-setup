# Zips and copies latest alfred preferences to this repo
update-alfred-prefs:
  cd ~/Library/Application\ Support/Alfred && zip -r {{justfile_directory()}}/prefs.zip Alfred.alfredpreferences

# Restores alfred preferences from this repo to the local machine
sync-alfred-prefs:
  unzip -o ./prefs.zip -d ~/Library/Application\ Support/Alfred/

run-tag tag:
  ansible-playbook -vvv -i localhost, playbook.yaml --connection=local --tags={{tag}}

setup:
  brew install pre-commit
  pre-commit install
