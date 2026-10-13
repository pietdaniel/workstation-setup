// Native Keyboard > Keyboard Shortcuts > Screenshots preferences.
ObjC.import('Foundation');

function run(args) {
    var defaults = $.NSUserDefaults.alloc.initWithSuiteName('com.apple.symbolichotkeys');
    var saved = defaults.objectForKey('AppleSymbolicHotKeys');
    var current = saved ? ObjC.deepUnwrap(saved) : {};
    var desired = JSON.parse(JSON.stringify(current));
    // 30: save selected area as a file; 31: copy selected area to clipboard.
    // 52 is '4', 21 is its virtual keycode. Masks: Cmd | Shift [| Control].
    desired['30'] = {
        enabled: true,
        value: { type: 'standard', parameters: [52, 21, 1441792] }
    };
    desired['31'] = {
        enabled: true,
        value: { type: 'standard', parameters: [52, 21, 1179648] }
    };

    // Compare the two managed entries; leave all other shortcuts untouched.
    function matches(id) {
        var entry = current[id];
        return entry && entry.enabled === true && entry.value &&
            entry.value.type === 'standard' &&
            JSON.stringify(entry.value.parameters) === JSON.stringify(desired[id].value.parameters);
    }
    if (matches('30') && matches('31')) return 'ok';
    if (args.indexOf('--check') !== -1) return 'changed';

    defaults.setObjectForKey($(desired), 'AppleSymbolicHotKeys');
    if (!defaults.synchronize) throw Error('Could not save screenshot shortcuts.');
    return 'changed';
}
