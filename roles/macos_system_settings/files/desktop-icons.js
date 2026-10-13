// Values captured from Finder's desktop View Options on macOS 27.
// Merge only our settings, retaining previews, item info, and other preferences.
ObjC.import('Foundation');

function run(args) {
    var defaults = $.NSUserDefaults.alloc.initWithSuiteName('com.apple.finder');
    var saved = defaults.objectForKey('DesktopViewSettings');
    var current = saved ? ObjC.deepUnwrap(saved) : {};
    var desired = JSON.parse(JSON.stringify(current));
    desired.GroupBy = 'Kind';
    var icons = desired.IconViewSettings || {};
    icons.arrangeBy = 'dateAdded';
    icons.iconSize = 16;
    icons.gridSpacing = 1; // Smallest spacing from Finder's slider.
    icons.textSize = 12;
    icons.labelOnBottom = false; // Labels on the right.
    desired.IconViewSettings = icons;

    if (JSON.stringify(current) === JSON.stringify(desired)) return 'ok';
    if (args.indexOf('--check') !== -1) return 'changed';

    defaults.setObjectForKey($(desired), 'DesktopViewSettings');
    if (!defaults.synchronize) throw Error('Could not save Finder desktop preferences.');
    return 'changed';
}
