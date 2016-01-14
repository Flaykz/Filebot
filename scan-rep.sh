#!/bin/bash
DIR_MEDIA="/media/odroid"
DIR_COMPLETE="/media/odroid/Multimedia/Torrents/Complete"
DIR_SCAN="/media/odroid/Multimedia/Torrents/Scan"
DIR_VIDEO="Video"
DIR_ISO="Iso"
DIR_EBOOK="Ebook"

sudo find "$DIR_COMPLETE" -mindepth 2 -type f -print0 |xargs -0 -I '{}' mv '{}' "$DIR_COMPLETE"
sudo find "$DIR_COMPLETE" -mindepth 1 -maxdepth 1 -type d -print0 |xargs -0 /bin/rm -Rf
sudo find "$DIR_COMPLETE" -type f -iname "*sample*" -size -100M -print0 |xargs -0 /bin/rm -f
sudo find "$DIR_COMPLETE" -type f -regextype posix-egrep -iregex '.*\.(html|nfo|txt|srt)' -size -100M -print0 |xargs -0 /bin/rm -f
sudo find "$DIR_COMPLETE" -type f -regextype posix-egrep -iregex '.*\.(mkv|avi|mp4|mpg)' -print0 |xargs -0 -I '{}' mv '{}' "$DIR_SCAN/$DIR_VIDEO"
sudo find "$DIR_COMPLETE" -type f -regextype posix-egrep -iregex '.*\.(pdf|epub|doc)' -print0 |xargs -0 -I '{}' mv '{}' "$DIR_SCAN/$DIR_EBOOK"
sudo find "$DIR_COMPLETE" -type f -regextype posix-egrep -iregex '.*\.(iso|rar|zip|7zip)' -print0 |xargs -0 -I '{}' mv '{}' "$DIR_SCAN/$DIR_ISO"

sudo find "$DIR_SCAN/$DIR_VIDEO" -type f -print0 -exec /usr/share/rename-filebot.sh {} \;

