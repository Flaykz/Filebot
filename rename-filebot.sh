#!/bin/sh
echo " "
FILELOG=/var/log/filebot.log
SCRIPT_PATH="$0"
TR_TORRENT="$1"
DIR_MEDIA="/media/odroid"
IP_KODI="localhost"
USER_KODI="###"
PASSWORD_KODI="###"
RPC_PORT_KODI="8081"
LOG_FILE="amc.log"
ACTION="MOVE"
CONFLICT="skip" #skip override auto
ENCODING="utf8"
SERIE_FORMAT="Multimedia 2/Series/{primaryTitle}/Saison {s}/{primaryTitle} - {s00e00.replaceAll(\"S\",\"\").replaceAll(\"E\",\"X\")} - {t}{if (ext == 'srt') '.'}{if (ext == 'srt') lang}"
MOVIE_FORMAT="Multimedia/Films/{primaryTitle} ({y})/{primaryTitle} ({y}) {vf}{if (ext == 'srt') '.'}{if (ext == 'srt') lang}"
UT_KIND="single" #multi
TR_TORRENT_DIR=`dirname "$TR_TORRENT"`
TR_TORRENT_NAME=`basename "$TR_TORRENT"`
TORRENT_SUBTITLES=""
SUBTITLES=""

if echo "$TR_TORRENT_NAME" |grep -i "VOSTFR" >/dev/null 2>&1
	then
	if echo "$TR_TORRENT_NAME" |grep -i ".mkv" >/dev/null 2>&1
		then
		TORRENT_SUBTITLES="en"
	fi
else 
	if echo "$TR_TORRENT_NAME" |grep -i "FRENCH" >/dev/null 2>&1
		then
		TORRENT_SUBTITLES=""
	else
		TORRENT_SUBTITLES="en,fr"
	fi
fi

if not "$TORRENT_SUBTITLES" == "" >/dev/null 2>&1
	then
	SUBTITLES="subtitles=\"$TORRENT_SUBTITLES\""
fi

echo $(date +"%d-%m-%y %T") "$SCRIPT_PATH" >> "$FILELOG"
#echo $(date +"%d-%m-%y %T") Parametres : "$@" >> "$FILELOG"
echo $(date +"%d-%m-%y %T") Nom : "$TR_TORRENT_NAME" >> "$FILELOG"
echo $(date +"%d-%m-%y %T") Chemin : "$TR_TORRENT_DIR" >> "$FILELOG"
echo $(date +"%d-%m-%y %T") Sous-titres : "$TORRENT_SUBTITLES" >> "$FILELOG"

sudo /usr/share/filebot/bin/filebot.sh -script fn:amc --output "$DIR_MEDIA" --log-file "$LOG_FILE" --action "$ACTION" --conflict "$CONFLICT" -non-strict --encoding "$ENCODING" --db xattr --def xbmc="$IP_KODI" music=y $SUBTITLES artwork=n seriesFormat="$SERIE_FORMAT" movieFormat="$MOVIE_FORMAT" ut_dir="$TR_TORRENT_DIR" ut_file="$TR_TORRENT_NAME" ut_kind="$UT_KIND" ut_title="$TR_TORRENT_NAME" >> "$FILELOG" 2>&1
tail -n -38 "$FILELOG" |grep -A 38 "$SCRIPT_PATH" |head -n -1 |grep -i -B 1 "Process" |tail -n 2 1>&2

if tail -n 38 "$FILELOG" |grep -A 38 "$SCRIPT_PATH" |grep "already exists" > /dev/null 2>&1
	then
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

TR_ID = `transmission-remote "$IP_KODI":"$RPC_PORT_KODI" -n "$USER_KODI":"$PASSWORD_KODI" -l |grep -F "$TR_TORRENT_NAME" |cut -d "*" -f 1 |sed 's/ //g'`
transmission-remote "$IP_KODI":"$RPC_PORT_KODI" -n "$USER_KODI":"$PASSWORD_KODI" -t "$TR_ID" -r

echo $(date +"%d-%m-%y %T") Statut : "$?" >> "$FILELOG"
echo "********************************************************" >> "$FILELOG"
#tail -n -50 "$FILELOG" |sed -n '/$SCRIPT_PATH/,/Statut/p'

if tail -n -38 "$FILELOG" |grep -A 38 "$SCRIPT_PATH" |head -n -1 |grep "MOVE" |tail -n 1 != ""  > /dev/null 2>&1
	then
	DIR_PATH=`tail -n -38 "$FILELOG" |grep -A 38 "$SCRIPT_PATH" |head -n -1 |grep "MOVE" |tail -n 1 |awk -Fto '{print $2}'|cut -d '[' -f 2 |cut -d ']' -f 1`
	DIR_PATH=`dirname "$DIR_PATH"`
	echo sudo chown -R "$USER_KODI":"$USER_KODI" "$DIR_PATH" >> "$FILELOG"
	sudo chown -R "$USER_KODI":"$USER_KODI" "$DIR_PATH"
	sudo chmod -R 777 "$DIR_PATH"
fi
