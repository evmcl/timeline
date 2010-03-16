#!/bin/sh

###############################################################################
#
# By Evan McLean http://evanmclean.com/ and http://www.michevan.id.au/
#
# Collects screen captures and (optionally) webcam captures and builds a daily
# time-lapsed video of the day's activity. Read below for requirements and
# customisation.
#
###############################################################################
#
# MIT License
#
# Copyright (c) 2010 Evan McLean
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# Except as contained in this notice, the name(s) of the above copyright
# holders shall not be used in advertising or otherwise to promote the sale,
# use or other dealings in this Software without prior written authorisation.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
###############################################################################
#
# Inspired by the public domain script at http://gist.github.com/311181
# by Dan Paluska.
#
# This version is an endeavour to clean things up a bit, isolate all the
# tweaking to the top of the script and document them, and add a few other
# refinements, like no screen grabbing when the screen saver is running.
#
# Requirements:
#
# ffmpeg for producing the video.
#
# imagemagick to do post image processing (e.g. adding time stamp or resizing.)
#
# For screen capture:
# A program such as the unfortunately named "scrot" that will produce an image
# file on your desktop.
#
# For webcam capture:
# A program to capture a single frame from your webcam, such as "streamer" or
# "v4lctl" which you might find in a package such as v4l-tools or xawtv for
# Linux.
#
# For macs there is something called wacaw I believe.
#
# Onward...
#
###############################################################################
# CUSTOMISE HERE
#
# WINDOW_MANAGER
# Expected values: KDE4, KDE3, GNOME, Other
# TODO: Currently only KDE4 is tested, anybody want to add support for the
# rest?
#
WINDOW_MANAGER=KDE4
#
# USE_DESKTOP
# Expected values: 1 or 0
# Whether we grab desktop images. Usually set to one, but can be zero if you
# only want to grab webcam images.
#
USE_DESKTOP=1
#
# USE_WEBCAM
# Expected values: 1 or 0
# Whether we grab web-cam images while we are getting the desktop.
#
USE_WEBCAM=1
#
# DETECT_SCREEN_SAVER
# Expected values: 1 or 0
# Detect if the screen saver is running and don't bother taking a screen grab
# if so.
#
DETECT_SCREEN_SAVER=1
#
# SCREEN_SAVER_WEBCAM_ANYWAY
# Expected values: 1 or 0
# Take webcam picture even if the screen saver is running (assuming
# USE_WEBCAM=1 and DETECT_SCREEN_SAVER=1).
#
SCREEN_SAVER_WEBCAM_ANYWAY=0
#
# FRAMERATE
# Expected values: 10, 15, 20, 24 (NTSC), 25 (PAL)
# See GRAB_INTERVAL below on how to calculate your frame rate and/or grab
# interval.
#
FRAME_RATE=20
#
# GRAB_INTERVAL
# Number of seconds between each screen/webcam grab.
#
# Is a reasonably simple formulate. Take the following variables:
#
#   ELAPSED_TIME: The length of time over which we are capturing images in
#                 seconds.  e.g., 24 hours = 24 * 60 * 60 = 86400 seconds.
#                 8 hours = 8 * 60 * 60 = 28800
#
#   FILM_TIME: The desired length of the resultant video in seconds.
#              e.g., If you want the elapsed time compressed down into two
#              minutes then FILM_TIME would be 120 seconds.
#
#   FRAME_RATE: The number of frames per second in the final movie, specified
#               above.
#
#   GRAB_INTERVAL: How long to wait between each shot.
#
# The general formulae is:
#
#   GRAB_INTERVAL = ELAPSED_TIME / ( FILM_TIME * FRAME_RATE )
#
# For example, a grab interval of 12 seconds will compress 10 hours of image
# capture down to 2 minutes of video at a frame rate of 25 frames per second.
#
GRAB_INTERVAL=15
#
# KEEP_PICTURES
# Expected values: 1 or 0
# Decides if we keep the pictures after we've make the video for the day.
# Note that the folder for the current days pictures will never be deleted or
# renamed. This option only effects the daemon process when it produces the
# video when midnight ticks over. When producing video from a command line
# operation the folder is never touched.
#
KEEP_PICTURES=0
#
# PICTURES_FOLDER
# Folder to store pictures. Will use a sub-folder for each day. The sub-folder
# for screen grabs will be timeline-desktop-YYYY-MM-DD and for webcam,
# timeline-webcam-YYYY-MM-DD. Once a folder is processed, it will be deleted if
# KEEP_PICTURES is zero, or renamed to processed-timeline-... so we don't try
# and process it again.
#
PICTURES_FOLDER=$HOME/Pictures/timeline
#
# VIDEO_FOLDER
# Folder to store videos, which are produced each day as midnight ticks over,
# or on demand from the command line.
#
VIDEO_FOLDER=$HOME/Videos/timeline
#
# SCREEN_GRAB_EXT
# Expected values: png, jpg, jpeg, gif, ...
# The file extension of the type of image file produced by the screen capture
# program. Lossless format preferred (i.e. not jpg).
#
SCREEN_GRAB_EXT=png
#
# WEBCAM_GRAB_EXT
# Expected values: png, jpg, jpeg, gif, ...
# The file extension of the type of image file produced by the webcam capture
# program. Lossless format preferred (i.e. not jpg).
#
WEBCAM_GRAB_EXT=jpeg
#
# VIDEO_EXT
# Expected values: mp4, others?
# The file extension for producing the video.
VIDEO_EXT=mp4
#
# TIMESTAMP_FORMAT
# Format to use for the (optional) timestamp.
#
TIMESTAMP_FORMAT="%a %-e %b %Y %-l:%M%#p"
#
# LOG_FILE
# Full path and name of the log file to write when running in the background.
#
LOG_FILE=/usr/tmp/timeline_$(whoami).log
#
# ---------
# FUNCTIONS
# ---------
#
# The following functions provide various bits of functionality that may need
# to be tweaked for your system.
#
# DoScreenGrab
#
# Performs the screen capture of your desktop. The argument $1 will be the full
# path and name of the file you want to save to.
#
if (( $USE_DESKTOP != 0 )) ; then
DoScreenGrab() {
  scrot "$1"
}
fi
#
# DoWebcamGrab
#
# Performs the capture of a single frame from your webcam. The argument $1 will
# be the full path and name of the file you want to save to.
# In particular, you might have to cusomise the name of the video device to
# capture from.
#
if (( $USE_WEBCAM != 0 )) ; then
DoWebcamGrab() {
  # On my system the video device seems to jump around a bit.
  DEV=none
  if [[ -e /dev/video0 ]] ; then
    DEV=/dev/video0
  elif [[ -e /dev/video1 ]] ; then
    DEV=/dev/video1
  elif [[ -e /dev/video2 ]] ; then
    DEV=/dev/video2
  elif [[ -e /dev/video3 ]] ; then
    DEV=/dev/video3
  fi
  if [[ "$DEV" != "none" ]] ; then
    Log "Webcam capture with $DEV"
    #streamer -c "$DEV" -o "$1"
    v4lctl -c "$DEV" snap jpeg full "$1"
    echo
  fi
}
fi
#
# MakeVideo
#
# Convert the set of still images to a video. The argument $1 will be the full
# path and name mask of the image files, and $2 will be the full path and name
# of the video file to produce.
#
MakeVideo() {
  ffmpeg -r $FRAME_RATE -b 5000 -i "$1" "$2"
}
#
# PostScreenGrab
#
# Do post processing on the screen grab file.  This could be resizing the
# image or putting in the date and time. The arguments to this function are:
#
#  $1 Full path and and name of file to process.
#  $2 Full path and and name of where to write the result file.
#  $3 Date and time of the screen grab in the format specified by
#     TIMESTAMP_FORMAT above.
#
# Even if you don't want to do any post processing, run through imagemagicks
# convert as the image format of the file to process and the target may not
# be the same.
#
PostScreenGrab() {
  # Simplest version, does no real processing
  # convert "$1" "$2"

  # Simple resizing of the image
  # convert "$1" -resize "60%" "$2"

  # Resize and write the timestamp in blue
  convert "$1" -resize "60%" -font "Andale-Mono-Regular" -pointsize 20 -fill blue -draw "text 20 20 \"$3\"" "$2"
}
#
# PostWebcamGrab
#
# Do post processing on the webcam grab file.  This could be resizing the
# image or putting in the date and time. The arguments to this function are:
#
#  $1 Full path and and name of file to process.
#  $2 Full path and and name of where to write the result file.
#  $3 Date and time of the screen grab in the format specified by
#     TIMESTAMP_FORMAT above.
#
# Even if you don't want to do any post processing, run through imagemagicks
# convert as the image format of the file to process and the target may not
# be the same.
#
PostWebcamGrab() {
  # Simplest version, does no real processing
  # convert "$1" "$2"

  # Write the timestamp in blue
  convert "$1" -font "Andale-Mono-Regular" -pointsize 20 -fill blue -draw "text 20 20 \"$3\"" "$2"
}
#
# IsScreenSaverActive
#
# Must set the value SCREEN_SAVER_ACTIVE to "0" or "1". If in doubt, set to
# "0".
#
if (( $DETECT_SCREEN_SAVER != 0 )) ; then
IsScreenSaverActive() {
  SCREEN_SAVER_ACTIVE=0
  if [[ $WINDOW_MANAGER == "KDE4" ]] ; then
    if [[ $(dbus-send --session --dest=org.freedesktop.ScreenSaver --type=method_call --print-reply /ScreenSaver org.freedesktop.ScreenSaver.GetActive | fgrep 'boolean true' | wc -l) -gt 0 ]] ; then
      SCREEN_SAVER_ACTIVE=1
    fi
  elif [[ $WINDOW_MANAGER == "KDE3" ]] ; then
    [[ "a$(dcop kdesktop KScreensaverIface isBlanked)" != "afalse" ]] && SCREEN_SAVER_ACTIVE=1
  fi
  # TODO Implement for other window managers
  # ELSE Leave SCREEN_SAVER_ACTIVE equal to 0
}
fi
#
###############################################################################
# SHOULD NOT NEED TO MODIFY ANYTHING FROM HERE ONWARDS
###############################################################################
PROG="$0"

usage() {
  echo "Run program in background (default) or foreground to take snapshots."
  echo "  $PROG [--fg] [--quiet]"
  echo "    --fg     Run in the foreground."
  echo "    --quiet  No log info."
  echo
  echo "Kill running background process."
  echo "  $PROG --kill"
  echo
  echo "Process images in specified folder into a movie."
  echo "  $PROG <image_folder> <movie_file>"
  exit 1
}

ISBG=0
RUNFG=0
JUSTKILL=0
QUIET=0
PROC_IMAGES=0
PROC_IMAGE_DIR=
PROC_MOVIE_FILE=

if [[ "a$1" == "a--" ]] ; then
  ISBG=1
  shift
fi

while [[ "a$1" != "a" ]] ; do
  case "$1" in
  --kill)
    JUSTKILL=1
    ;;
  --fg)
    RUNFG=1
    ;;
  --quiet)
    QUIET=1
    ;;
  -*)
    usage
    ;;
  *)
    break
    ;;
  esac
  shift
done

(( $JUSTKILL != 0 && $RUNFG != 0 )) && usage

if (( $JUSTKILL != 0 || $RUNFG != 0 )) ; then
  (( $# != 0 )) && usage
elif (( $# == 2 )) ; then
  PROC_IMAGES=1
  PROC_IMAGE_DIR="$1"
  PROC_MOVIE_FILE="$2"
elif (( $# != 0 )) ; then
  usage
fi

KillTimeline() {
  PROC="${PROG##*/}"
  NPID="$$"
  pgrep -u $(whoami) "${PROC}" | grep -v "^${NPID}$" | xargs -r kill -TERM
  sleep 1
  pgrep -u $(whoami) "${PROC}" | grep -v "^${NPID}$" | xargs -r kill -KILL
}

if (( $JUSTKILL != 0 )) ; then
  KillTimeline
  exit 0
fi

if (( $ISBG == 0 && $RUNFG == 0 && $PROC_IMAGES == 0 )) ; then
  if (( $QUIET == 0 )) ; then
    nohup "$PROG" -- < /dev/null > $LOG_FILE 2>&1 &
  else
    nohup "$PROG" -- --quiet < /dev/null > /dev/null 2>&1 &
  fi
  exit 0
fi

# Process the folder full of PNG files.
#  $1 is folder
#  $2 is movie to make.
ProcessFolder() {
  IMAGES="$1"
  MOVIE="$2"
  WIMAGES="$IMAGES/working"
  MOVIE_EXT="${MOVIE##*.}"
  TMPMOVIE="${MOVIE%$MOVIE_EXT}$$.${MOVIE_EXT}"

  # Link all the files into the working folder with sequential numbering
  # for ffmpeg to do its thing.
  mkdir "$WIMAGES"
  CNTR=10000
  for FL in ${IMAGES}/*.png ; do
    let "CNTR+=1"
    ln "$FL" "${WIMAGES}/img${CNTR:1}.png"
  done

  ffmpeg -r $FRAME_RATE -b 5000 -i "${WIMAGES}/img%04d.png" "$TMPMOVIE"
  RET=$?
  if (( $RET == 0 )) ; then
    mv "$TMPMOVIE" "$MOVIE"
  else
    rm "$TMPMOVIE"
  fi
  rm -rf "$WIMAGES"
  return $RET
}

if (( $PROC_IMAGES != 0 )) ; then
  ProcessFolder "$PROC_IMAGE_DIR" "$PROC_MOVIE_FILE"
  exit 0
fi

# From here is the endless loop.
TODAY=$(date +%Y-%m-%d)

# Write to log file.
# $* is the message to log.
Log() {
  if (( $QUIET == 0 )) ; then
    echo "$(date "+%Y-%m-%d %H:%M:%S") $*"
  fi
}

ifmkdir() {
  [[ ! -d "$1" ]] && mkdir -p "$1"
}

# Process a folder, and then move or delete it as appropriate.
# $1 is folder to process
# $2 is video to produce
ProcessPreviousFolder() {
  IMAGES="$1"
  MOVIE="$2"
  IMAGES_DIR="${IMAGES%/*}"
  IMAGES_NAME="${IMAGES##*/}"
  PIMAGES="$IMAGES_DIR/processed-$IMAGES_NAME"
  BIMAGES="$IMAGES_DIR/bad-$IMAGES_NAME"

  Log "Processing $IMAGES => $MOVIE"
  ProcessFolder "$IMAGES" "$MOVIE"
  if (( $? != 0 )) ; then
    mv "$IMAGES" "$BIMAGES"
  else
    mv "$IMAGES" "$PIMAGES"
    if (( $KEEP_PICTURES == 0 )) ; then
      rm $PIMAGES/*.png
      rmdir "$PIMAGES"
    fi
  fi
}

# Process all previous folders, before TODAY
ProcessPreviousFolders() {
  Log "Checking for old folders to process."
  ifmkdir "$VIDEO_FOLDER"
  for FLDR in $PICTURES_FOLDER/timeline-desktop-* ; do
    if [[ -d "$FLDR" ]] ; then
      DAY="${FLDR:${#FLDR}-10}"
      if [[ "$DAY" < "$TODAY" ]] ; then
	ProcessPreviousFolder "$FLDR" "$VIDEO_FOLDER/timeline-desktop-$DAY.$VIDEO_EXT"
      fi
    fi
  done

  for FLDR in $PICTURES_FOLDER/timeline-webcam-* ; do
    if [[ -d "$FLDR" ]] ; then
      DAY="${FLDR:${#FLDR}-10}"
      if [[ "$DAY" < "$TODAY" ]] ; then
	ProcessPreviousFolder "$FLDR" "$VIDEO_FOLDER/timeline-webcam-$DAY.$VIDEO_EXT"
      fi
    fi
  done
}

KillTimeline
ProcessPreviousFolders

TODAY_DESKTOP="$PICTURES_FOLDER/timeline-desktop-$TODAY"
TODAY_WEBCAM="$PICTURES_FOLDER/timeline-webcam-$TODAY"

(( $USE_DESKTOP != 0 )) && ifmkdir "$TODAY_DESKTOP"
(( $USE_WEBCAM != 0 )) && ifmkdir "$TODAY_WEBCAM"

while true ; do
  START_AT=$(date +%s)
  NOW=$(date +%Y%m%d%H%M%S)
  TIMESTAMP="$(date "+$TIMESTAMP_FORMAT")"
  THIS_DAY=$(date +%Y-%m-%d)
  NEW_DAY=0
  if [[ $THIS_DAY != $TODAY ]] ; then
    NEW_DAY=1
    TODAY="$THIS_DAY"
    TODAY_DESKTOP="$PICTURES_FOLDER/timeline-desktop-$TODAY"
    TODAY_WEBCAM="$PICTURES_FOLDER/timeline-webcam-$TODAY"

    Log "Ticking over to a new day."
    (( $USE_DESKTOP != 0 )) && ifmkdir "$TODAY_DESKTOP"
    (( $USE_WEBCAM != 0 )) && ifmkdir "$TODAY_WEBCAM"
  fi

  if (( $DETECT_SCREEN_SAVER != 0 )) ; then
    IsScreenSaverActive
  else
    SCREEN_SAVER_ACTIVE=0
  fi

  DESKTOP_FILE_TMP="$TODAY_DESKTOP/desktop${NOW}.tmp.${SCREEN_GRAB_EXT}"
  DESKTOP_FILE="$TODAY_DESKTOP/desktop${NOW}.png"
  WEBCAM_FILE_TMP="$TODAY_WEBCAM/webcam${NOW}.tmp.${WEBCAM_GRAB_EXT}"
  WEBCAM_FILE="$TODAY_WEBCAM/webcam${NOW}.png"

  DID_DESKTOP=0
  DID_WEBCAM=0

  # Grab the two files as close together as we can.
  if (( $SCREEN_SAVER_ACTIVE == 0 )) ; then
    Log "Click!"
    if (( $USE_DESKTOP != 0 )) ; then
      DoScreenGrab "$DESKTOP_FILE_TMP"
      DID_DESKTOP=1
    fi
    if (( $USE_WEBCAM != 0 )) ; then
      DoWebcamGrab "$WEBCAM_FILE_TMP"
      DID_WEBCAM=1
    fi
  elif (( $USE_WEBCAM != 0 && $SCREEN_SAVER_WEBCAM_ANYWAY != 0 )) ; then
    Log "Click!"
    DoWebcamGrab "$WEBCAM_FILE_TMP"
    DID_WEBCAM=1
  fi

  # Now do any post processing.
  if (( $DID_DESKTOP != 0 )) ; then
    if [[ -f "$DESKTOP_FILE_TMP" ]] ; then
      PostScreenGrab "$DESKTOP_FILE_TMP" "$DESKTOP_FILE" "$TIMESTAMP"
      rm "$DESKTOP_FILE_TMP"
    fi
  fi
  if (( $DID_WEBCAM != 0 )) ; then
    if [[ -f "$WEBCAM_FILE_TMP" ]] ; then
      PostWebcamGrab "$WEBCAM_FILE_TMP" "$WEBCAM_FILE" "$TIMESTAMP"
      rm "$WEBCAM_FILE_TMP"
    fi
  fi

  # If a new day, then process any previous folders to make a movie.
  [[ $NEW_DAY != 0 ]] && ProcessPreviousFolders

  # Sleep
  let "NEXT_AT=$START_AT + $GRAB_INTERVAL"
  END_AT=$(date +%s)
  if (( $END_AT < $NEXT_AT )) ; then
    let "SLEEP_INTERVAL=$NEXT_AT - $END_AT"
    Log "zzzZZZ $SLEEP_INTERVAL"
    sleep $SLEEP_INTERVAL
  fi
done
