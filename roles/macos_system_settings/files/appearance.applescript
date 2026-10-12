-- System Events exposes an appearance API; no UI selectors are needed.
tell application "System Events" to tell appearance preferences
    set didChange to not dark mode
    set dark mode to true
    if not dark mode then error "Dark appearance did not take effect."
end tell

if application "System Settings" is running then
    tell application "System Settings" to quit
end if

if didChange then return "changed"
return "ok"
