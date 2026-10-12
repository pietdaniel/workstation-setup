-- Use macOS's bundled solid color through the desktop API, not a downloaded image.
set blackWallpaper to "/System/Library/Desktop Pictures/Solid Colors/Black.png"
do shell script "test -f " & quoted form of blackWallpaper

set didChange to false
tell application "System Events"
    if (count of desktops) is 0 then error "No active desktops found. Run as the logged-in desktop user."
    repeat with currentDesktop in desktops
        if picture of currentDesktop is not blackWallpaper then
            set picture of currentDesktop to blackWallpaper
            set didChange to true
        end if
    end repeat
end tell

delay 0.5
tell application "System Events"
    repeat with currentDesktop in desktops
        if picture of currentDesktop is not blackWallpaper then
            error "Desktop wallpaper verification failed: expected the solid-black background."
        end if
    end repeat
end tell

if didChange then return "changed"
return "ok"
