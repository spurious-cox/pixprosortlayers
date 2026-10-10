-- PixProSortLayers — sort the selected layers by their position on canvas
--
-- property scriptVersion below is what the dialogs show.
--
-- Originally written by Shawn S. Rewritten 2026-09-19 so it behaves like the
-- rest of the PixPro family.
--
-- WHAT WAS WRONG. The original opened with `tell application "Pixelmator Pro"`,
-- a name resolved when the script was COMPILED. Since the Creator Studio
-- rebrand that name points at whichever build macOS prefers, and several
-- copies of one build can be installed besides — so it drove the wrong copy,
-- or launched one that had no document open. The running Pixelmator is now
-- found the same way every other PixPro app finds it: by asking `ps` for the
-- bundle PATH of each running process, preferring the frontmost, then any
-- with a document open. Both builds are accepted.
--
-- The sort itself is Shawn's and is unchanged: for each pass it finds the
-- visible selected layer furthest along the chosen axis, hides it, and moves
-- it to the front of its own parent — so the layer order ends up matching the
-- layout, left to right or top to bottom. Visibility is restored at the end.

property scriptVersion : "2.1.3"
property kPixIDs : {"com.apple.pixelmator", "com.pixelmatorteam.pixelmator.x"}
-- Set by pixTarget() before anything talks to Pixelmator. Every `tell
-- application pixApp` below depends on it.
property pixApp : ""

-- Update check, the same in every PixPro app: asks GitHub for the newest
-- release at most once a day, gives up after three seconds, says nothing when
-- this build is current or the network is away, and otherwise adds
-- "Update available" to what the app already shows. It never downloads or
-- replaces anything.
property kSlug : "pixprosortlayers"
property kDefaults : "$HOME/.pixprosortlayers_defaults"

on versionParts(v)
	set out to {}
	set AppleScript's text item delimiters to "."
	set pieces to text items of v
	set AppleScript's text item delimiters to ""
	repeat with piece in pieces
		set digits to ""
		repeat with c in (characters of (piece as text))
			if c is in "0123456789" then set digits to digits & c
		end repeat
		if digits is "" then set digits to "0"
		set end of out to digits as integer
	end repeat
	return out
end versionParts

on isNewer(tag, mine)
	-- Compared as integers, so 3.10.0 comes out above 3.9.0 rather than below.
	set a to my versionParts(tag)
	set b to my versionParts(mine)
	repeat with i from 1 to 3
		set x to 0
		set y to 0
		if i ≤ (count a) then set x to item i of a
		if i ≤ (count b) then set y to item i of b
		if x > y then return true
		if x < y then return false
	end repeat
	return false
end isNewer

on latestTag()
	set today to do shell script "/bin/date +%Y-%m-%d"
	set lastDay to ""
	try
		set lastDay to do shell script "defaults read " & kDefaults & " updateCheckedOn 2>/dev/null"
	end try
	if lastDay is today then
		try
			return do shell script "defaults read " & kDefaults & " updateLatestTag 2>/dev/null"
		end try
		return ""
	end if
	try
		set tag to do shell script "/usr/bin/curl -sL --max-time 3 -H \"Accept: application/vnd.github+json\" https://api.github.com/repos/spurious-cox/" & kSlug & "/releases/latest | /usr/bin/grep -o '\"tag_name\": *\"[^\"]*\"' | /usr/bin/head -1 | /usr/bin/cut -d'\"' -f4"
		do shell script "defaults write " & kDefaults & " updateLatestTag " & quoted form of tag
		do shell script "defaults write " & kDefaults & " updateCheckedOn " & quoted form of today
		return tag
	on error
		return ""
	end try
end latestTag

on updateNotice(mine)
	set tag to my latestTag()
	if tag is "" then return ""
	if not (my isNewer(tag, mine)) then return ""
	set t to tag
	if t starts with "v" then set t to text 2 thru -1 of t
	return return & return & "Update available: " & t & "  —  brew upgrade --cask " & kSlug
end updateNotice


on pixTarget()
	set rawPaths to {}
	try
		set psOut to do shell script "/bin/ps -Axo args= | /usr/bin/grep '/Contents/MacOS/Pixelmator' | /usr/bin/grep -v grep | /usr/bin/sed 's|/Contents/MacOS/.*||' | /usr/bin/sort -u"
		-- `do shell script` separates lines with RETURN, not linefeed. Split on
		-- the wrong one and every path arrives glued into a single string.
		set AppleScript's text item delimiters to return
		set rawPaths to text items of psOut
		set AppleScript's text item delimiters to ""
	end try

	-- Keep only genuine Pixelmator Pro builds, identified by the bundle id in
	-- each app's OWN Info.plist. Nothing here depends on what the app is
	-- called or where it lives, so this works on any Mac: renamed bundles,
	-- App Store or Setapp copies, apps in ~/Applications, all fine. It also
	-- excludes the classic Pixelmator (com.pixelmatorteam.pixelmator), whose
	-- dictionary is different and which would fail halfway through.
	set candidates to {}
	repeat with rp in rawPaths
		set p to rp as text
		if p is not "" then
			try
				set theID to do shell script "/usr/bin/defaults read " & quoted form of (p & "/Contents/Info") & " CFBundleIdentifier"
				if theID is in kPixIDs then set end of candidates to p
			end try
		end if
	end repeat
	if candidates is {} then return ""

	-- Which of them, if any, is frontmost. The frontmost process's pid maps
	-- back to its bundle path through ps.
	set frontPath to ""
	try
		-- Bounded: asking System Events which app is frontmost needs Automation
		-- permission, and on a first run that call sits there waiting for a
		-- consent prompt. If the prompt does not appear — and for a freshly
		-- built applet it may not — the app hangs with no window and nothing
		-- to click. Five seconds, then carry on: the frontmost check only
		-- orders the candidates, it does not find them.
		with timeout of 5 seconds
			tell application "System Events"
				set fpid to my topPixelmatorPID(unix id of (first application process whose frontmost is true))
			end tell
		end timeout
		set frontPath to do shell script "/bin/ps -p " & fpid & " -o args= | /usr/bin/sed 's|/Contents/MacOS/.*||'"
	end try

	set ordered to {}
	repeat with c in candidates
		set cc to c as text
		if cc is equal to frontPath then set end of ordered to cc
	end repeat
	repeat with c in candidates
		set cc to c as text
		if cc is not equal to frontPath then set end of ordered to cc
	end repeat

	repeat with c in ordered
		set cc to c as text
		try
			using terms from application "Pixelmator Pro"
				tell application cc
					if (count of documents) > 0 then return cc
				end tell
			end using terms from
		end try
	end repeat
	return item 1 of ordered
end pixTarget

-- ============================================================
-- PICK THE PIXELMATOR BUILD
-- ============================================================
set pixApp to pixTarget()
if pixApp is "" then
	tell me to activate
	display dialog "Pixelmator Pro is not running. Open Pixelmator Pro and a document, select the layers to sort, and try again." buttons {"OK"} default button "OK" with title ("PixProSortLayers v" & scriptVersion)
	error number -128
end if

using terms from application "Pixelmator Pro"
	tell application pixApp
		if (count of documents) is 0 then
			tell me to activate
			display dialog "No document is open in Pixelmator Pro." buttons {"OK"} default button "OK" with title ("PixProSortLayers v" & scriptVersion)
			error number -128
		end if
	end tell
end using terms from

-- ============================================================
-- SORT
-- ============================================================
using terms from application "Pixelmator Pro"
	tell application pixApp
		tell its front document
			set sel_lays to selected layers
			if (count of sel_lays) < 2 then
				tell me to activate
				display dialog "Select two or more layers to sort." buttons {"OK"} default button "OK" with title ("PixProSortLayers v" & scriptVersion)
				error number -128
			end if

			tell me to activate
			set aButton to display dialog "Sort the selected layers by their position:" & return & return & "Horizontal puts the leftmost layer at the top of the list; Vertical puts the topmost one there." & return & return & "Original by Shawn S, who wrote it for me. It is still available on his Etsy site." & my updateNotice(scriptVersion) buttons {"Cancel", "Vertical", "Horizontal"} default button "Horizontal" with title ("PixProSortLayers v" & scriptVersion)
			set sort_direction to (button returned of aButton)

			repeat with iter from 1 to (count of sel_lays)
				set max_x_loc to -99000
				set max_x_layer to item iter in sel_lays
				set x_parent to parent of max_x_layer
				repeat with sort from 1 to (count of sel_lays)
					set clay to item sort in sel_lays
					if (visible of clay) then
						set this_pos to position of clay
						if (sort_direction = "Horizontal") then
							set sort_by to item 1 of this_pos
						else
							set sort_by to item 2 of this_pos
						end if
						if (sort_by > max_x_loc) then
							set max_x_loc to sort_by
							set max_x_layer to clay
						end if
					end if
				end repeat
				tell max_x_layer to set visible to false
				if (x_parent = missing value) then
					move max_x_layer to the beginning of layers
				else
					move max_x_layer to the beginning of layers in x_parent
				end if
			end repeat

			-- Hiding each layer is how the pass marks it done; they all come back.
			repeat with mysort in (sel_lays)
				tell mysort to set visible to true
			end repeat
		end tell
	end tell
end using terms from

display notification "Sorted " & (count of sel_lays) & " layers." with title ("PixProSortLayers v" & scriptVersion)


-- ============================================================
-- TOPMOST PIXELMATOR (v2.1.3, 2026-10-10)
-- ============================================================
-- Which Pixelmator Pro the person is looking at. "Frontmost application" is
-- no help when this applet was started from Stache, Flache or the Dock,
-- because the applet itself is then frontmost. The window list is ordered
-- front to back, so the first Pixelmator Pro window in it belongs to the build
-- on top. Visible windows are tried first, then all windows (a build on
-- another Space). Reading owner pid, name and size needs no Screen Recording
-- permission. Falls back to `fallback` when nothing is found.
on topPixelmatorPID(fallback)
	set js to "ObjC.import(\"CoreGraphics\");" & ¬
		"function top(o){var l=ObjC.deepUnwrap(ObjC.castRefToObject($.CGWindowListCopyWindowInfo(o,0)));" & ¬
		"for(var i=0;i<l.length;i++){var w=l[i];" & ¬
		"if(w.kCGWindowOwnerName==\"Pixelmator Pro\"&&w.kCGWindowLayer==0&&w.kCGWindowBounds.Height>100)return w.kCGWindowOwnerPID;}" & ¬
		"return \"\";}" & ¬
		"var r=top(17);if(r===\"\")r=top(16);r"
	try
		set r to do shell script "/usr/bin/osascript -l JavaScript -e " & quoted form of js
		if r is not "" then return r as integer
	end try
	return fallback
end topPixelmatorPID
