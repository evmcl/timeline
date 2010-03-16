Collects screen captures and (optionally) webcam captures and builds a daily
time-lapsed video of the day's activity. Read below for requirements and
customisation.

Inspired by the public domain script at
[http://gist.github.com/311181](http://gist.github.com/311181) by [Dan
Paluska](http://github.com/danpaluska).

This version is an endeavour to clean things up a bit, isolate all the tweaking
to the top of the script and document them, and add a few other refinements,
like no screen grabbing when the screen saver is running.

Requirements:

ffmpeg for producing the video.

imagemagick to do post image processing (e.g. adding time stamp or resizing.)

For screen capture:
A program such as the unfortunately named "scrot" that will produce an image
file on your desktop.

For webcam capture:
A program to capture a single frame from your webcam, such as "streamer" or
"v4lctl" which you might find in a package such as v4l-tools or xawtv for
Linux.

For macs there is something called wacaw I believe.

Review the script file to review and customise for your environment.

(MIT License)
