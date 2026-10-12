-- macOS 27, English UI: Point & Click tab, Tracking speed slider.
tell application "System Events"
    if not UI elements enabled then
        error "Enable Accessibility for the app running Ansible in System Settings > Privacy & Security > Accessibility, then retry."
    end if
end tell

do shell script "/usr/bin/open 'x-apple.systempreferences:com.apple.Trackpad-Settings.extension'"

set controlsReady to false
repeat 40 times
    tell application "System Events" to tell process "System Settings"
        try
            tell group 1 of group 3 of splitter group 1 of group 1 of window "Trackpad"
                -- Select Point & Click even if Settings remembered a different tab.
                if value of radio button 1 of tab group 1 is not 1 then
                    click radio button 1 of tab group 1
                end if
            end tell
            set speedSlider to a reference to slider "Tracking speed" of group 1 of scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of window "Trackpad"
            if exists speedSlider then
                set controlsReady to true
                exit repeat
            end if
        end try
    end tell
    delay 0.25
end repeat

if not controlsReady then
    error "Cannot find trackpad tracking speed. Close any settings dialog and retry. This script expects a connected trackpad and the English macOS Trackpad settings layout."
end if

set didChange to false
tell application "System Events"
    repeat 15 times
        if value of speedSlider is maximum value of speedSlider then exit repeat
        perform action "AXIncrement" of speedSlider
        set didChange to true
        delay 0.2
    end repeat
    if value of speedSlider is not maximum value of speedSlider then
        error "Trackpad verification failed: tracking speed must be at its maximum."
    end if
end tell

tell application "System Settings" to quit
if didChange then return "changed"
return "ok"
