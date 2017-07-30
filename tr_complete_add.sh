#!/opt/bin/sh
echo " "
SCRIPT_PATH="$0"
DIR_SCRIPT_PATH=`dirname "$SCRIPT_PATH"`

# Récupération du fichier de config
. "$DIR_SCRIPT_PATH/filebot.conf"

echo $(date +"%d-%m-%y %T") "Transmission v$TR_APP_VERSION : Debut du telechargement de $TR_TORRENT_NAME dans $TR_TORRENT_DIR" >> $TRLOG
