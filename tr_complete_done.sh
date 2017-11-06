#!/opt/bin/sh

echo " "
SCRIPT_PATH="$0"
DIR_SCRIPT_PATH=`dirname "$SCRIPT_PATH"`

# Récupération du fichier de config
. "$DIR_SCRIPT_PATH/filebot.conf"

echo "Subject: Filebot from QFLAYKZ" > $FILETOSEND
echo "From: david.brouste.perso@gmail.com" >> $FILETOSEND
echo "To: david.brouste.perso@gmail.com" >> $FILETOSEND
echo "" >> $FILETOSEND

echo $(date +"%d-%m-%y %T") "Transmission v$TR_APP_VERSION : Fin du telechargement de $TR_TORRENT_NAME " >> $TRLOG

sudo find "$DIR_COMPLETE" -mindepth 2 -type f -print0 |xargs -0 -I '{}' mv '{}' "$DIR_COMPLETE"
sudo find "$DIR_COMPLETE" -mindepth 1 -maxdepth 1 -type d -print0 |xargs -0 /bin/rm -Rf
sudo find "$DIR_COMPLETE" -type f -iname "*sample*" -size -100M -print0 |xargs -0 /bin/rm -f
sudo find "$DIR_COMPLETE" -type f -iname "*thumb*" -size -10M -print0 |xargs -0 /bin/rm -f
sudo find "$DIR_COMPLETE" -type f -regextype posix-egrep -iregex '.*\.(html|nfo|txt|srt)' -size -100M -print0 |xargs -0 /bin/rm -f
sudo find "$DIR_COMPLETE" -type f -regextype posix-egrep -iregex '.*\.(mkv|avi|mp4|mpg)' -print0 |xargs -0 -I '{}' mv '{}' "$DIR_SCAN/$DIR_VIDEO"
sudo find "$DIR_COMPLETE" -type f -regextype posix-egrep -iregex '.*\.(pdf|epub|doc)' -print0 |xargs -0 -I '{}' mv '{}' "$DIR_SCAN/$DIR_EBOOK"
sudo find "$DIR_COMPLETE" -type f -regextype posix-egrep -iregex '.*\.(iso|rar|zip|7zip)' -print0 |xargs -0 -I '{}' mv '{}' "$DIR_SCAN/$DIR_ISO"
sudo find "$DIR_SCAN/$DIR_VIDEO" -mindepth 1 -maxdepth 1 -type d -print0 |xargs -0 /bin/rm -Rf
sudo find "$DIR_SCAN/$DIR_VIDEO" -type f -print0 -exec /opt/share/filebot/rename-filebot.sh {} \;

NBLINE=`wc -l $FILETOSEND |cut -f1 -d' '`
echo $NBLINE
cat $FILETOSEND
if [ $NBLINE -ne 4 ]
then
    echo "envoi du mail"
    cat $FILETOSEND |sendmail -t
fi
rm $FILETOSEND
