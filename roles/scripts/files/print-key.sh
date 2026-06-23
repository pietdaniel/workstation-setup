#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'print-key.sh needs macOS to read Cmd/Option/Ctrl modifier events.\n' >&2
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  printf 'print-key.sh needs the Swift toolchain from Xcode Command Line Tools.\n' >&2
  exit 1
fi

swift_dir="$(mktemp -d "${TMPDIR:-/tmp}/print-key.XXXXXX")"
swift_file="$swift_dir/print-key.swift"
trap 'rm -rf "$swift_dir"' EXIT

cat >"$swift_file" <<'SWIFT'
import ApplicationServices
import CoreGraphics
import Darwin
import Foundation

let modifierKeyNames: [Int64: String] = [
    54: "Right Cmd",
    55: "Cmd",
    56: "Shift",
    57: "Caps Lock",
    58: "Option",
    59: "Ctrl",
    60: "Right Shift",
    61: "Right Option",
    62: "Right Ctrl",
    63: "Fn"
]

let keyNames: [Int64: String] = [
    0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
    8: "C", 9: "V", 10: "ISO Section", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
    16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
    24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O",
    32: "U", 33: "[", 34: "I", 35: "P", 36: "Return", 37: "L", 38: "J", 39: "'",
    40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
    48: "Tab", 49: "Space", 50: "`", 51: "Delete", 52: "Enter", 53: "Escape",
    54: "Right Cmd", 55: "Cmd", 56: "Shift", 57: "Caps Lock", 58: "Option", 59: "Ctrl",
    60: "Right Shift", 61: "Right Option", 62: "Right Ctrl", 63: "Fn",
    64: "F17", 65: "Keypad .", 67: "Keypad *", 69: "Keypad +", 71: "Clear",
    72: "Volume Up", 73: "Volume Down", 74: "Mute", 75: "Keypad /", 76: "Keypad Enter",
    78: "Keypad -", 79: "F18", 80: "F19", 81: "Keypad =", 82: "Keypad 0", 83: "Keypad 1",
    84: "Keypad 2", 85: "Keypad 3", 86: "Keypad 4", 87: "Keypad 5", 88: "Keypad 6",
    89: "Keypad 7", 90: "F20", 91: "Keypad 8", 92: "Keypad 9", 96: "F5", 97: "F6",
    98: "F7", 99: "F3", 100: "F8", 101: "F9", 103: "F11", 105: "F13", 106: "F16",
    107: "F14", 109: "F10", 111: "F12", 113: "F15", 114: "Help", 115: "Home",
    116: "Page Up", 117: "Forward Delete", 118: "F4", 119: "End", 120: "F2", 121: "Page Down",
    122: "F1", 123: "Left Arrow", 124: "Right Arrow", 125: "Down Arrow", 126: "Up Arrow"
]

var pressedModifierKeyCodes = Set<Int64>()

func keyName(for keyCode: Int64) -> String {
    keyNames[keyCode] ?? "KeyCode \(keyCode)"
}

func characters(from event: CGEvent) -> String? {
    var length = 0
    var chars = [UniChar](repeating: 0, count: 16)

    event.keyboardGetUnicodeString(
        maxStringLength: chars.count,
        actualStringLength: &length,
        unicodeString: &chars
    )

    guard length > 0 else { return nil }

    return chars.withUnsafeBufferPointer { buffer in
        String(utf16CodeUnits: buffer.baseAddress!, count: length)
    }
}

func printableCharacters(from event: CGEvent) -> String {
    guard let value = characters(from: event), !value.isEmpty else { return "" }

    switch value {
    case "\r", "\n": return " char=Enter"
    case "\t": return " char=Tab"
    case " ": return " char=Space"
    default: return " char=\"\(value)\""
    }
}

func modifiers(from flags: CGEventFlags) -> String {
    var names = [String]()

    if flags.contains(.maskControl) { names.append("Ctrl") }
    if flags.contains(.maskAlternate) { names.append("Option") }
    if flags.contains(.maskCommand) { names.append("Cmd") }
    if flags.contains(.maskShift) { names.append("Shift") }
    if flags.contains(.maskSecondaryFn) { names.append("Fn") }
    if flags.contains(.maskAlphaShift) { names.append("CapsLock") }

    return names.isEmpty ? "" : " modifiers=[\(names.joined(separator: "+"))]"
}

func printEvent(_ action: String, _ name: String, _ event: CGEvent, includeCharacters: Bool) {
    let chars = includeCharacters ? printableCharacters(from: event) : ""
    print("\(action): \(name)\(chars)\(modifiers(from: event.flags))")
    fflush(stdout)
}

if #available(macOS 10.15, *) {
    if !CGPreflightListenEventAccess() {
        fputs("macOS Input Monitoring permission is required. Approve it when prompted, then rerun this script if no events print.\n", stderr)
        _ = CGRequestListenEventAccess()
    }
}

let callback: CGEventTapCallBack = { _, type, event, _ in
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

    switch type {
    case .keyDown:
        printEvent("down", keyName(for: keyCode), event, includeCharacters: true)
    case .keyUp:
        printEvent("up", keyName(for: keyCode), event, includeCharacters: false)
    case .flagsChanged:
        let name = modifierKeyNames[keyCode] ?? keyName(for: keyCode)
        let action: String

        if pressedModifierKeyCodes.contains(keyCode) {
            pressedModifierKeyCodes.remove(keyCode)
            action = "up"
        } else {
            pressedModifierKeyCodes.insert(keyCode)
            action = "down"
        }

        printEvent(action, name, event, includeCharacters: false)
    default:
        break
    }

    return Unmanaged.passUnretained(event)
}

let eventMask =
    (CGEventMask(1) << CGEventType.keyDown.rawValue) |
    (CGEventMask(1) << CGEventType.keyUp.rawValue) |
    (CGEventMask(1) << CGEventType.flagsChanged.rawValue)

guard let eventTap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .listenOnly,
    eventsOfInterest: eventMask,
    callback: callback,
    userInfo: nil
) else {
    fputs("Could not create keyboard event tap. Grant Input Monitoring or Accessibility permission to Terminal/iTerm, then rerun.\n", stderr)
    exit(1)
}

guard let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0) else {
    fputs("Could not create event tap run loop source.\n", stderr)
    exit(1)
}

print("Printing macOS keyboard events. Press Ctrl-C to quit.")
fflush(stdout)

CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)
CFRunLoopRun()
SWIFT

exec swift "$swift_file"
