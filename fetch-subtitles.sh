#!/bin/sh
FILELOG=/var/log/filebot.log
FILEPATH=$1
SUBTITLES=$2
NAME=$(echo $FILEPATH |cut -f7 -d/)

echo ggggggggggggggggggggggggggggggggggggggggggggggggg >> $FILELOG
echo $0 >> $FILELOG
echo $(date) >> $FILELOG
echo Chemin: $FILEPATH >> $FILELOG
echo Sous-titres: $SUBTITLES >> $FILELOG
echo Nom du media a rechercher: $NAME >> $FILELOG
sudo /usr/share/filebot/bin/filebot.sh -get-missing-subtitles "$FILEPATH" --q "$NAME" --lang $SUBTITLES --output srt --encoding utf8 -non-strict
echo ggggggggggggggggggggggggggggggggggggggggggggggggg >> $FILELOG
echo  >> $FILELOG

