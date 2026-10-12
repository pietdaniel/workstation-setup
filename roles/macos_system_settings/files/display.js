// macOS 27, English UI. More Space is the last of five scaling presets.
// JXA reads AXAttributedDescription, which System Events cannot decode here.
ObjC.import('AppKit');
ObjC.import('ApplicationServices');

function attribute(element, name) {
    var result = Ref();
    if ($.AXUIElementCopyAttributeValue(element, $(name), result) !== 0) return null;
    return ObjC.castRefToObject(result[0]);
}

function description(element) {
    var text = attribute(element, 'AXAttributedDescription');
    return text ? ObjC.unwrap(text.string) : '';
}

function matching(element, predicate) {
    var result = predicate(element) ? [element] : [];
    var children = attribute(element, 'AXChildren');
    if (children) {
        for (var i = 0; i < children.count; i++) {
            result = result.concat(matching(children.objectAtIndex(i), predicate));
        }
    }
    return result;
}

function run() {
    if (!$.AXIsProcessTrusted()) {
        throw Error('Enable Accessibility for the app running Ansible, then retry.');
    }
    var app = Application.currentApplication();
    app.includeStandardAdditions = true;
    app.doShellScript("/usr/bin/open 'x-apple.systempreferences:com.apple.Displays-Settings.extension'");

    var panel;
    for (var attempt = 0; attempt < 40; attempt++) {
        var settings = $.NSRunningApplication.runningApplicationsWithBundleIdentifier('com.apple.systempreferences');
        if (settings.count) {
            var root = $.AXUIElementCreateApplication(settings.firstObject.processIdentifier);
            panel = matching(root, function(e) { return description(e) === 'Display settings for Built-in Display'; })[0];
            if (panel) break;
            var builtIn = matching(root, function(e) { return description(e) === 'Built-in Display'; })[0];
            if (builtIn) $.AXUIElementPerformAction(builtIn, $('AXPress'));
        }
        delay(0.25);
    }
    if (!panel) throw Error('Cannot find Built-in Display settings. Close any settings dialog and retry.');

    var presets = matching(panel, function(e) { return /^\d+ × \d+( \(Default\))?$/.test(description(e)); });
    if (presets.length !== 5) {
        throw Error('Expected five display scaling presets. Switch Displays to thumbnail view and retry.');
    }
    var moreSpace = presets[4];
    var target = description(moreSpace).match(/^(\d+) × (\d+)/);
    var expected = target[1] + ' x ' + target[2];

    function currentResolution() {
        var gpus = JSON.parse(app.doShellScript('/usr/sbin/system_profiler SPDisplaysDataType -json')).SPDisplaysDataType;
        for (var i = 0; i < gpus.length; i++) {
            var displays = gpus[i].spdisplays_ndrvs || [];
            for (var j = 0; j < displays.length; j++) {
                if (displays[j].spdisplays_connection_type === 'spdisplays_internal') {
                    return (displays[j]._spdisplays_resolution || '').split(' @ ')[0];
                }
            }
        }
        throw Error('Cannot read the built-in display resolution.');
    }

    var changed = currentResolution() !== expected;
    if (changed && $.AXUIElementPerformAction(moreSpace, $('AXPress')) !== 0) {
        throw Error('Could not select More Space.');
    }
    for (var retry = 0; retry < 10; retry++) {
        if (currentResolution() === expected) {
            Application('System Settings').quit();
            return changed ? 'changed' : 'ok';
        }
        delay(0.5);
    }
    throw Error('More Space did not take effect; expected ' + expected + '.');
}
