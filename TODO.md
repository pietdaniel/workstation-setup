# TODO

 - Handle Homebrew trust, locks, and visible progress.
 - Show GitHub login/SSO prompts; finish key registration and signing.

 - Install Neovim plugins/tools during setup, not first launch.
 - Keep reruns safe so failures don’t mean starting over.


# eleventh error

- So we made it through ansible
- Keyboard brightness is wrong
- Background is wrong (should be black
- Opening vim said ‘install packages Y/N’
    - It should of just installed all the packages in the setup scriptj
- escape as capslock!!!


# tenth error

- Maybe eight
- But I had to install chrome to a whole chrome fucking thing then SSO to GitHub then device login to get my id_rsa.rub up
- This was annoying
- I also don’t know if this just uploaded a ssh key to my GitHub account but that’s a whole thing to look into

# Ninth Error

- Mac escape swap
- This doesn’t need the weird script
- Also should be early in the process

# Eighth Error

Blocked here

<localhost> EXEC /bin/sh -c 'rm -f -r /Users/civil/.ansible/tmp/ansible-tmp-1790309623.931256-10376-192179053277956/ > /dev/null 2>&1'
ok: [localhost] => {
    "changed": false,
    "changed_when_result": false,
    "cmd": [
        "gh",
        "auth",
        "status",
        "--hostname",
        "github.com"
    ],
    "delta": "0:00:00.399990",
    "end": "2026-09-25 00:13:44.475786",
    "failed_when_result": false,
    "failed_when_suppressed_exception": "(traceback unavailable)",
    "msg": "The command exited with a non-zero return code.",
    "rc": 1,
    "start": "2026-09-25 00:13:44.075796",
    "stderr": "You are not logged into any GitHub hosts. To log in, run: gh auth login",
    "stderr_lines": [
        "You are not logged into any GitHub hosts. To log in, run: gh auth login"
    ],
    "stdout": "",
    "stdout_lines": []
}

TASK [git : Authenticate GitHub CLI in browser] *************************************************
task path: /Users/civil/workstation-setup/roles/git/tasks/main.yaml:58
<localhost> ESTABLISH LOCAL CONNECTION FOR USER: civil
<localhost> EXEC /bin/sh -c 'echo ~civil'
<localhost> EXEC /bin/sh -c '( umask 77 && mkdir -p "` echo /Users/civil/.ansible/tmp `"&& mkdir "` echo /Users/civil/.ansible/tmp/ansible-tmp-1790309624.517668-10390-223642263453051 `" && echo ansible-tmp-1790309624.517668-10390-223642263453051="` echo /Users/civil/.ansible/tmp/ansible-tmp-1790309624.517668-10390-223642263453051 `" )'
Using module file /opt/homebrew/Cellar/ansible/14.4.0/libexec/lib/python3.14/site-packages/ansible/modules/command.py
<localhost> PUT /Users/civil/.ansible/tmp/ansible-local-1640bi3sx4bg/tmpc760p5f_ TO /Users/civil/.ansible/tmp/ansible-tmp-1790309624.517668-10390-223642263453051/AnsiballZ_command.py
<localhost> EXEC /bin/sh -c 'chmod u+rwx /Users/civil/.ansible/tmp/ansible-tmp-1790309624.517668-10390-223642263453051/ /Users/civil/.ansible/tmp/ansible-tmp-1790309624.517668-10390-223642263453051/AnsiballZ_command.py'
<localhost> EXEC /bin/sh -c '/opt/homebrew/bin/python3.14 /Users/civil/.ansible/tmp/ansible-tmp-1790309624.517668-10390-223642263453051/AnsiballZ_command.py'



# Seventh Error

- Mouse speed
- Repeat key speed

# Sixth Error

- Ok, so I upgraded from 14 to 27 …
- That’s .. a lot of versions
- No maybe the whole pinentry thing was reasonable….
- We’ll find out

# Fifth Error

- Play a song when done

# Fourth error

On a Mac
- Disable smart quotes
- Make the default Mac background black
- Make desktop items tiny and sorted
- Make the display resolution the highest
- Install chrome
- Chrome default browser
- macOS version ??? This one seems hard
    - Perhaps like, Would you like to upgrade?
    - 

# Third Error

Just removed pin entry from the sciprt

# Second Error
Had to kill with CTRL-C
Undo lock
Trust the cask

The error log reveals two main issues causing the task to fail:
1. A Homebrew Lock Exists: The primary reason it failed at the end is because an active or stuck brew install pinentry-mac process has already locked /opt/homebrew/Cellar/pinentry-mac.
2. Tap Trust and macOS 14 Warnings: Homebrew also outputted warnings about nikitabobko/tap needing trust and a warning regarding macOS 14 (Sonoma) being an older, unsupported tier for that specific build configuration.
How to Fix This
1. Kill the Stuck Process and Remove the Lock
If another terminal window or a previous hanging Ansible run is still trying to install pinentry-mac, terminate it. If no process is running, you can manually remove the stale lock file:
Bash

rm -f /opt/homebrew/Cellar/pinentry-mac/.brew_lock
(Alternatively, check for running brew processes with ps aux | grep brew and kill them).
2. Address the Tap Trust Warning
Homebrew now requires explicit trust for third-party taps. Run this command in your terminal to trust the nikitabobkotap referenced in your playbook:
Bash

brew trust nikitabobko/tap
Once you have cleared the lock file and trusted the tap, re-run your Ansible playbook:
Bash

ansible-playbook your-playbook.yml
Are you managin


—

TASK [macos : Install pinentry-mac] ********************************************
task path: /Users/civil/workstation-setup/roles/macos/tasks/main.yaml:13
<localhost> ESTABLISH LOCAL CONNECTION FOR USER: civil
<localhost> EXEC /bin/sh -c 'echo ~civil'
<localhost> EXEC /bin/sh -c '( umask 77 && mkdir -p "` echo /Users/civil/.ansible/tmp `"&& mkdir "` echo /Users/civil/.ansible/tmp/ansible-tmp-1790306521.5632992-29933-191804642228843 `" && echo ansible-tmp-1790306521.5632992-29933-191804642228843="` echo /Users/civil/.ansible/tmp/ansible-tmp-1790306521.5632992-29933-191804642228843 `" )'
Using module file /opt/homebrew/Cellar/ansible/14.4.0/libexec/lib/python3.14/site-packages/ansible_collections/community/general/plugins/modules/homebrew.py
<localhost> PUT /Users/civil/.ansible/tmp/ansible-local-292787q8_tcpa/tmpy5bf7vx2 TO /Users/civil/.ansible/tmp/ansible-tmp-1790306521.5632992-29933-191804642228843/AnsiballZ_homebrew.py
<localhost> EXEC /bin/sh -c 'chmod u+rwx /Users/civil/.ansible/tmp/ansible-tmp-1790306521.5632992-29933-191804642228843/ /Users/civil/.ansible/tmp/ansible-tmp-1790306521.5632992-29933-191804642228843/AnsiballZ_homebrew.py'
<localhost> EXEC /bin/sh -c '/opt/homebrew/bin/python3.14 /Users/civil/.ansible/tmp/ansible-tmp-1790306521.5632992-29933-191804642228843/AnsiballZ_homebrew.py'


- This took a long time…
- Not sure why

# First Error

First install failed cause maybe Xcode
Second install didn’t home-brew, required

civil@MacBook-Pro ~ % /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"


— log below for why the above two failed

Last login: Thu Sep 24 23:11:41 on console
civil@MacBook-Pro ~ % curl https://piet.us/projects/bootstrap/a.sh | bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  4117  100  4117    0     0  39617      0 --:--:-- --:--:-- --:--:-- 39970
=== Workstation Bootstrap Script ===

Git is already installed

Cloning https://github.com/pietdaniel/workstation-setup into /Users/civil/workstation-setup...
xcode-select: note: No developer tools were found, requesting install.
If developer tools are located at a non-default location on disk, use `sudo xcode-select --switch path/to/Xcode.app` to specify the Xcode that you wish to use for command line developer tools, and cancel the installation dialog.
See `man xcode-select` for more details.
civil@MacBook-Pro ~ % curl https://piet.us/projects/bootstrap/a.sh | bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  4117  100  4117    0     0  77598      0 --:--:-- --:--:-- --:--:-- 79173
=== Workstation Bootstrap Script ===

Git is already installed

Cloning https://github.com/pietdaniel/workstation-setup into /Users/civil/workstation-setup...
Cloning into '/Users/civil/workstation-setup'...
remote: Enumerating objects: 1860, done.
remote: Counting objects: 100% (517/517), done.
remote: Compressing objects: 100% (314/314), done.
remote: Total 1860 (delta 281), reused 387 (delta 168), pack-reused 1343 (from 1)
Receiving objects: 100% (1860/1860), 5.06 MiB | 33.89 MiB/s, done.
Resolving deltas: 100% (917/917), done.

Running setup script...
Detected OS: darwin
Homebrew is not installed. Installing Homebrew...
Warning: Running in non-interactive mode because `stdin` is not a TTY.
==> Checking for `sudo` access...
Insufficient permissions to install Homebrew to "/opt/homebrew".
civil@MacBook-Pro ~ % curl https://piet.us/projects/bootstrap/a.sh | bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  4117  100  4117    0     0  64779      0 --:--:-- --:--:-- --:--:-- 65349
=== Workstation Bootstrap Script ===

Git is already installed

Directory /Users/civil/workstation-setup already exists
Updating existing repository...
Already up to date.

Running setup script...
Detected OS: darwin
Homebrew is not installed. Installing Homebrew...
Warning: Running in non-interactive mode because `stdin` is not a TTY.
==> Checking for `sudo` access...
Insufficient permissions to install Homebrew to "/opt/homebrew".
civil@MacBook-Pro ~ % sudo -s
Password:
sudo: a password is required
civil@MacBook-Pro ~ % /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
==> Checking for `sudo` access (which may request your password)...
Password:
==> You are using macOS 14.8.
==> We (and Apple) do not provide support for this old version.
This installation may not succeed.
After installation, you will encounter build failures with some formulae.
Please create pull requests instead of asking for help on Homebrew's GitHub,
Twitter or any other official channels. You are responsible for resolving any
issues you experience while you are running this old version.

==> This script will install:
/opt/homebrew/bin/brew
/opt/homebrew/share/doc/homebrew
/opt/homebrew/share/man/man1/brew.1
/opt/homebrew/share/zsh/site-functions/_brew
/opt/homebrew/etc/bash_completion.d/brew
/opt/homebrew
/etc/paths.d/homebrew
==> The following new directories will be created:
/opt/homebrew/bin
/opt/homebrew/etc
/opt/homebrew/include
/opt/homebrew/lib
/opt/homebrew/sbin
/opt/homebrew/share
/opt/homebrew/var
/opt/homebrew/opt
/opt/homebrew/share/zsh
/opt/homebrew/share/zsh/site-functions
/opt/homebrew/var/homebrew
/opt/homebrew/var/homebrew/linked
/opt/homebrew/Cellar
/opt/homebrew/Caskroom
/opt/homebrew/Frameworks

Press RETURN/ENTER to continue or any other key to abort:
==> /usr/bin/sudo /usr/bin/install -d -o civil -g admin -m 0755 /opt/homebrew
==> Found Git: /Library/Developer/CommandLineToo
