-- macOS 27, English UI: rightmost positions are Fastest and Shortest.
-- Writing defaults alone does not reliably update the active keyboard settings.
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
            set repeatControls to a reference to group 1 of scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of window "Keyboard"
            if (exists slider 1 of repeatControls) and (exists slider 2 of repeatControls) then
                set controlsReady to true
                exit repeat
            end if
        end try
    end tell
    delay 0.25
end repeat

if not controlsReady then
    error "Cannot find key-repeat controls. Close any settings dialog and retry. This script expects the English macOS Keyboard settings layout."
end if

set didChange to false
tell application "System Events"
    repeat with sliderIndex from 1 to 2
        set targetSlider to a reference to slider sliderIndex of repeatControls
        repeat 10 times
            if value of targetSlider is maximum value of targetSlider then exit repeat
            -- AXValue writes snap back on these sliders; use their real UI action.
            perform action "AXIncrement" of targetSlider
            set didChange to true
            delay 0.2
        end repeat
        if value of targetSlider is not maximum value of targetSlider then
            error "Key-repeat verification failed: both sliders must be at their rightmost positions."
        end if
    end repeat
end tell

tell application "System Settings" to quit
if didChange then return "changed"
return "ok"
