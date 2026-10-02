-- UI layout verified on macOS 27 with English System Settings.
-- Keep these brittle selectors here, separate from native preference tasks.
tell application "System Events"
    if not UI elements enabled then
        error "Enable Accessibility for the app running Ansible in System Settings > Privacy & Security > Accessibility, then retry."
    end if
end tell

do shell script "/usr/bin/open 'x-apple.systempreferences:com.apple.Keyboard-Settings.extension'"

set controlsReady to false
repeat 40 times
    tell application "System Events" to tell process "System Settings"
        try
            set keyboardControls to a reference to group 2 of scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of window 1
            if exists slider "Keyboard brightness" of keyboardControls then
                if exists checkbox "Adjust keyboard brightness in low light" of keyboardControls then
                    set controlsReady to true
                    exit repeat
                end if
            end if
        end try
    end tell
    delay 0.25
end repeat

if not controlsReady then
    error "Cannot find keyboard backlight controls. Close any open settings dialog and retry. This script expects a backlit keyboard and the English macOS Keyboard settings layout."
end if

set didChange to false
tell application "System Events"
    tell keyboardControls
        if value of checkbox "Adjust keyboard brightness in low light" is not 0 then
            click checkbox "Adjust keyboard brightness in low light"
            set didChange to true
            delay 0.25
        end if
        if value of slider "Keyboard brightness" is not 0 then
            set value of slider "Keyboard brightness" to 0
            set didChange to true
        end if
    end tell
end tell

delay 0.5
tell application "System Events" to tell keyboardControls
    if value of checkbox "Adjust keyboard brightness in low light" is not 0 or value of slider "Keyboard brightness" is not 0 then
        error "Keyboard backlight verification failed: automatic adjustment must be off and brightness must be zero."
    end if
end tell

tell application "System Settings" to quit

if didChange then return "changed"
return "ok"
