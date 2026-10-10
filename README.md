# PixProSortLayers 2.1.3

Reorders the selected Pixelmator Pro layers to match where they sit on the
canvas: **Horizontal** puts the leftmost layer at the top of the Layers list,
**Vertical** puts the topmost one there.

**Shawn S wrote the original of this for me, and it is still available on his
Etsy site.** I rewrote it in September 2026 so it behaves like the rest of the
PixPro family; the sorting itself is Shawn's and is unchanged.

### [⬇︎ Download the latest release](https://github.com/spurious-cox/pixprosortlayers/releases/latest)

Notarized and stapled by Apple — open the DMG and drag PixProSortLayers to
Applications, or install it with Homebrew:

```
brew install --cask spurious-cox/tap/pixprosortlayers
```

Requires Pixelmator Pro and macOS 26 or later. Both the 3.x build and the
Creator Studio build work; the app binds to whichever one is in front or has a
document open.

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

## Updates

When it opens, PixProSortLayers asks GitHub whether a newer release exists — at most
once a day, giving up after three seconds — and says nothing if you are up to
date or offline. If there is a newer one, it shows in its dialog:

    Update available: X.Y.Z  —  brew upgrade --cask pixprosortlayers

It only ever reports: nothing is downloaded and nothing replaces itself.

## Building

```
./build.sh
```

Compiles the applet, installs the icon, restores the bundle identity that
`osacompile` drops each time, signs with Developer ID, and installs to
`/Applications`. Pass `--no-install` to stop before the copy.

To notarize and staple, submit it with `xcrun notarytool` and staple the result with `xcrun stapler`.

## Problems or suggestions

Open an issue: https://github.com/spurious-cox/pixprosortlayers/issues

## License

MIT. See LICENSE.
