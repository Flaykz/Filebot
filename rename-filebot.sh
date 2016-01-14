#!/bin/sh

echo " "
SCRIPT_PATH="$0"
DIR_SCRIPT_PATH=`dirname "$SCRIPT_PATH"`

TR_TORRENT="$1"
TR_TORRENT_DIR=`dirname "$TR_TORRENT"`
TR_TORRENT_NAME=`basename "$TR_TORRENT"`

# Récupération du fichier de config
. "$DIR_SCRIPT_PATH/filebot.conf"


if [ -z `echo "$TR_TORRENT_NAME" |grep -i "VOSTFR"` ] >/dev/null 2>&1
then
	#Pas de VOSTFR
	if [ -z `echo "$TR_TORRENT_NAME" |grep -i "FRENCH"` ] >/dev/null 2>&1
	then
		#no FRENCH
                TORRENT_SUBTITLES="en,fr"
	else
		#FRENCH
                TORRENT_SUBTITLES=""
	fi
	if ! [ -z `echo "$TR_TORRENT_NAME" |grep -i ".mkv"` ] >/dev/null 2>&1
	then
		#MKV
		TORRENT_SUBTITLES="en"
	fi
else
	#VOSTFR
	if ! [ -z `echo "$TR_TORRENT_NAME" |grep -i ".mkv"` ] >/dev/null 2>&1
	then
		#MKV
                TORRENT_SUBTITLES="en"
	fi
fi

echo $(date +"%d-%m-%y %T") "$SCRIPT_PATH" >> "$FILELOG"
#echo $(date +"%d-%m-%y %T") Parametres : "$@" >> "$FILELOG"
echo $(date +"%d-%m-%y %T") Nom : "$TR_TORRENT_NAME" >> "$FILELOG"
echo $(date +"%d-%m-%y %T") Chemin : "$TR_TORRENT_DIR" >> "$FILELOG"

if ! [ -z "$TORRENT_SUBTITLES" ] >/dev/null 2>&1
then
	#Avec sous-titres
	echo $(date +"%d-%m-%y %T") Sous-titres : "$TORRENT_SUBTITLES" >> "$FILELOG"
	sudo /usr/share/filebot/bin/filebot.sh -script fn:amc --output "$DIR_MEDIA" --log-file "$LOG_FILE" --action "$ACTION" --conflict "$CONFLICT" -non-strict --encoding "$ENCODING" --db xattr --def xbmc="$IP_KODI" music=y subtitles="$TORRENT_SUBTITLES" artwork="$ARTWORK" seriesFormat="$SERIE_FORMAT" movieFormat="$MOVIE_FORMAT" ut_dir="$TR_TORRENT_DIR" ut_file="$TR_TORRENT_NAME" ut_kind="$UT_KIND" ut_title="$TR_TORRENT_NAME" >> "$FILELOG" 2>&1
else
	#Sans sous-titres
	sudo /usr/share/filebot/bin/filebot.sh -script fn:amc --output "$DIR_MEDIA" --log-file "$LOG_FILE" --action "$ACTION" --conflict "$CONFLICT" -non-strict --encoding "$ENCODING" --db xattr --def xbmc="$IP_KODI" music=y artwork="$ARTWORK" seriesFormat="$SERIE_FORMAT" movieFormat="$MOVIE_FORMAT" ut_dir="$TR_TORRENT_DIR" ut_file="$TR_TORRENT_NAME" ut_kind="$UT_KIND" ut_title="$TR_TORRENT_NAME" >> "$FILELOG" 2>&1
fi
tail -n -38 "$FILELOG" |grep -A 38 "$SCRIPT_PATH" |head -n -1 |grep -B 1 "Process" |tail -n 2|grep "MOVE" 1>&2

if ! [ -z `tail -n 38 "$FILELOG" |grep -A 38 "$SCRIPT_PATH" |grep "already exists"` ] > /dev/null 2>&1
then
	#fichier deja existant
	#tester si c'est du mkv ou du mp4 = facilement modifiable
	TR_TORRENT_LENGTH=`stat -c "%s" "$TR_TORRENT_DIR/$TR_TORRENT_NAME"`
	EXISTING_FILE=`tail -n 38 "$FILELOG" |grep -A 38 "$SCRIPT_PATH" |grep "already exists" |awk -Fbecause '{print $2}' |cut -d '[' -f 2 |cut -d ']' -f 1`
	EXISTING_FILE_LENGTH=`stat -c "%s" "$EXISTING_FILE"`
	if [ "$TR_TORRENT_LENGTH" -eq "$EXISTING_FILE_LENGTH" ] >/dev/null 2>&1
	then
		#A voir pour tester  si il est possible de récupérer la bande audio
		rm -f "$TR_TORRENT_DIR/$TR_TORRENT_NAME" 1>&2
		echo $(date +"%d-%m-%y %T") "Suppression de $TR_TORRENT_DIR/$TR_TORRENT_NAME : $TR_TORRENT_LENGTH (Ancien : $EXISTING_FILE_LENGTH)" >> "$FILELOG"
		echo "Suppression de $TR_TORRENT_DIR/$TR_TORRENT_NAME" 1>&2
	else
		#A voir pour tester si c'est du HD ou pas, lequel faut remplacer etc
		echo $(date +"%d-%m-%y %T") Une action doit être effectuée pour le fichier suivant :  "$TR_TORRENT_DIR/$TR_TORRENT_NAME" >> "$FILELOG"
		echo "Une action doit être effectuée pour le fichier suivant : $TR_TORRENT_DIR/$TR_TORRENT_NAME" 1>&2
	fi
fi

#On enleve le torrent de transmission
TR_ID=`transmission-remote "$IP_KODI":"$RPC_PORT_KODI" -n "$USER_KODI":"$PASSWORD_KODI" -l |grep -F "${TR_TORRENT_NAME%.*}" |awk '{print $1}'`
if ! [ -z "$TR_ID" ] > /dev/null 2>&1
then
        echo $(date +"%d-%m-%y %T") "transmission-remote $IP_KODI:$RPC_PORT_KODI -n $USER_KODI:$PASSWORD_KODI -t $TR_ID -r : " `transmission-remote "$IP_KODI":"$RPC_PORT_KODI" -n "$USER_KODI":"$PASSWORD_KODI" -t "$TR_ID" -r` >> "$FILELOG"
else
        echo $(date +"%d-%m-%y %T") "NO TR_ID ! transmission-remote $IP_KODI:$RPC_PORT_KODI -n $USER_KODI:$PASSWORD_KODI -l |grep -F ${TR_TORRENT_NAME%.*} |awk '{print "'$1'"}' : $TR_ID" >> "$FILELOG"
fi

#On modifie les droits si un fichier est rajouté
if ! [ -z `tail -n -38 "$FILELOG" |grep -A 38 "$SCRIPT_PATH" |head -n -1 |grep -B 1 "Process" |tail -n 2|grep "MOVE"` ] > /dev/null 2>&1
then
	#On modifie les droits sur les fichiers téléchargés
        DIR_PATH=`tail -n -38 "$FILELOG" |grep -A 38 "$SCRIPT_PATH" |head -n -1 |grep -B 1 "Process" |tail -n 2|grep "MOVE"|awk -Fto '{print $2}'|cut -d '[' -f 2 |cut -d ']' -f 1`
        DIR_PATH=`dirname "$DIR_PATH"`
	#On s'assure que le chemin ou on change les droits correspond bien au chemin ou on stocke les films et séries
        if [ -z `echo "$DIR_PATH" |grep "$DIR_MEDIA"` ] >/dev/null 2>&1
	then
        	echo $(date +"%d-%m-%y %T") "Le script a voulu changer les droits du dossier $DIR_PATH : refusé pour prévenir d'une mauvaise manipulation" 1>&2
	else
        	sudo chown -R "$USER_KODI":"$USER_KODI" "$DIR_PATH"
        	sudo chmod -R 777 "$DIR_PATH"
		echo $(date +"%d-%m-%y %T") "Modification des droits pour le dossier $DIR_PATH" >> "$FILELOG"
	fi
fi
#echo $(date +"%d-%m-%y %T") "Statut : $?" >> "$FILELOG"
echo "********************************************************" >> "$FILELOG"
