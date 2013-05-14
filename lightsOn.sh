#!/bin/bash
# lightsOn.sh

# Copyright (c) 2011 iye.cba at gmail com, 2012 unhammer at fsfe org
# url: https://github.com/unhammer/lightsOn
# This script is licensed under GNU GPL version 2.0 or above

# Description: Bash script that prevents the screensaver and display power
# management (DPMS) to be activated when you are watching Flash Videos
# fullscreen on Firefox and Chromium.
# Can detect mplayer and VLC when they are fullscreen too but I have disabled
# this by default.
# lightsOn.sh needs xscreensaver or kscreensaver to work.

# USAGE: Start the script with the number of seconds you want the checks
# for fullscreen to be done. Example:
# "./lightsOn.sh 120 &" will check every 120 seconds if e.g. Mplayer,
# VLC, Firefox or Chromium are fullscreen and delay screensaver and Power Management if so.
# You want the number of seconds to be ~10 seconds less than the time it takes
# your screensaver or Power Management to activate.
# If you don't pass an argument, the checks are done every 50 seconds.


# Set the variable `screensaver' to the screensaver you use.
# Valid options are:
# * xscreensaver (default)
# * kscreensaver (the KDE screensaver)
screensaver=xscreensaver

# Modify these variables if you want this script to detect if Mplayer,
# VLC or Firefox Flash Video are Fullscreen and disable
# xscreensaver/kscreensaver and PowerManagement.
mplayer_detection=true
vlc_detection=true
parole_detection=true
firefox_flash_detection=true
firefox_mplayer_detection=true
chromium_flash_detection=true

# Set to true to be verbose, false to be quiet:
verbose=true


# YOU SHOULD NOT NEED TO MODIFY ANYTHING BELOW THIS LINE


xprop_active_info () {
    xprop -id $(xprop -root _NET_ACTIVE_WINDOW | awk '{print $5}')
}

maybe_delay_screensaver () {
    if xprop_active_info | grep -q _NET_WM_STATE_FULLSCREEN; then
	$verbose && echo "detected fullscreen"
        if app_is_running; then
	    $verbose && echo "delaying"
            delay_screensaver
	else
	    $verbose && echo "no relevant app detected"
        fi
    fi
}

app_is_running () {
    active_win_title=$(xprop_active_info | grep "WM_CLASS(STRING)")
    $verbose && echo "active window title: $active_win_title"

    if $firefox_flash_detection && [[ x"$active_win_title" = x*unknown* || x"$active_win_title" = x*plugin-container* ]]; then
	$verbose && echo "active win seems to firefox flash"
	pgrep plugin-containe &>/dev/null && return 0
    fi

    if $firefox_mplayer_detection && [[ x"$active_win_title" = x*mplayer* || x"$active_win_title" = x*MPlayer* ]]; then
	$verbose && echo "active win seems to firefox mplayer"
        pgrep plugin-containe &>/dev/null && return 0
    fi

    if $chromium_flash_detection && [[ x"$active_win_title" = x*chromium* ]]; then
	# TODO: the hardcoded path probably doesn't always work
	$verbose && echo "active win seems to be chromium"
        pgrep -f "chromium-browser --type=plugin --plugin-path=/usr/lib/adobe-flashplugin" &>/dev/null && return 0
    fi

    if $mplayer_detection && [[ x"$active_win_title" = x*mplayer* || x"$active_win_title" = x*MPlayer* ]]; then
	$verbose && echo "active win seems to mplayer"
	pgrep mplayer &>/dev/null && return 0
    fi
    
    if $vlc_detection && [[ x"$active_win_title" = x*vlc* ]]; then
	$verbose && echo "active win seems to vlc"
        pgrep vlc &>/dev/null && return 0
    fi

    if $parole_detection && [[ x"$active_win_title" = x*parole* ]]; then
	$verbose && echo "active win seems to parole"
        pgrep parole &>/dev/null && return 0
    fi

    return 1
}

delay_screensaver () {
    if [ x"$screensaver" = x"kscreensaver" ]; then
	qdbus org.freedesktop.ScreenSaver /ScreenSaver SimulateUserActivity > /dev/null
    else
	xscreensaver-command -deactivate > /dev/null
    fi

    if xset -q | grep -q 'DPMS is Enabled'; then
        # reset (deactivate and reactivate) DPMS status:
        xset -dpms
        xset dpms
    fi
}


delay=$1
if [ -z "$delay" ]; then
    delay=50
fi

if [[ x$1 = x*[^0-9]* || x$1 = x0 ]]; then
    echo "The argument \"$1\" is invalid, expecting a positive integer"
    echo "Please use the time in seconds you want the checks to repeat."
    echo "You want it to be less than the time it takes your screensaver or DPMS to activate"
    exit 1
fi

while true; do
    maybe_delay_screensaver
    sleep "$delay"
done
