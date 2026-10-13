-- macOS 27, English UI. This switch also disables other interface sound effects.
tell application "System Events"
    if not UI elements enabled then
        error "Enable Accessibility for the app running Ansible in System Settings > Privacy & Security > Accessibility, then retry."
    end if
end tell

do shell script "/usr/bin/open 'x-apple.systempreferences:com.apple.Sound-Settings.extension'"

set controlsReady to false
repeat 40 times
    tell application "System Events" to tell process "System Settings"
        try
            set effectsToggle to a reference to checkbox "Play user interface sound effects" of group 1 of scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of window "Sound"
            if exists effectsToggle then
                set controlsReady to true
                exit repeat
            end if
        end try
    end tell
    delay 0.25
end repeat

if not controlsReady then
    error "Cannot find the interface sound effects switch. Close any settings dialog and retry. This script expects the English macOS Sound settings layout."
end if

set didChange to false
tell application "System Events"
    if value of effectsToggle is not 0 then
        click effectsToggle
        set didChange to true
    end if
    delay 0.5
    if value of effectsToggle is not 0 then
        error "Sound settings verification failed: user interface sound effects must be off."
    end if
end tell

tell application "System Settings" to quit
if didChange then return "changed"
return "ok"
