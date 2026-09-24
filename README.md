# PixProSortLayers 2.0.3

Reorders the selected Pixelmator Pro layers to match where they sit on the
canvas: **Horizontal** puts the leftmost layer at the top of the Layers list,
**Vertical** puts the topmost one there.

Original by **Shawn S**. Rewritten September 2026 so it behaves like the rest
of the PixPro family — the sorting itself is Shawn's and is unchanged.

Private repository: this app is not published and has no release download or
Homebrew cask. Build it from source, or ask Tim for a notarized copy.

Requires Pixelmator Pro. Both the 3.x build and the Creator Studio build work;
the app binds to whichever one is in front or has a document open.

## Using it

1. In Pixelmator Pro, select two or more layers.
2. Run PixProSortLayers.
3. Choose **Horizontal** or **Vertical**.

Layers are moved within their own parent, so a layer inside a group stays in
that group.

## How it works

Each pass finds the visible selected layer furthest along the chosen axis,
hides it, and moves it to the beginning of its parent's layer list. Repeating
that for every selected layer leaves the list in canvas order. Visibility is
restored at the end.

`index` is read-only in Pixelmator's dictionary, so reordering has to go
through the Standard Suite `move` command, which the app's dictionary inherits
from CocoaStandard.

## Building

```
./build.sh
```

Compiles the applet, installs the icon, restores the bundle identity that
`osacompile` drops each time, signs with Developer ID, and installs to
`/Applications`. Pass `--no-install` to stop before the copy.

To notarize and staple:

```
~/My_Applications/_signing/pixpro_release.sh all /Applications/PixProSortLayers.app
```

The icon is built from the master artwork with `pixpro_icon SortLayers`.
