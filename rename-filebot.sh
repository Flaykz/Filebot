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
	sudo filebot -script fn:amc --output "$DIR_MEDIA" --log-file "$LOG_FILE" --action "$ACTION" --conflict "$CONFLICT" -non-strict --encoding "$ENCODING" --db xattr --def kodi="$IP_KODI" music=y subtitles="$TORRENT_SUBTITLES" artwork="$ARTWORK" seriesFormat="$DIR_MEDIA$SERIE_FORMAT" movieFormat="$DIR_MEDIA$MOVIE_FORMAT" ut_dir="$TR_TORRENT_DIR" ut_file="$TR_TORRENT_NAME" ut_kind="$UT_KIND" ut_title="$TR_TORRENT_NAME" >> "$FILELOG" 2>&1
else
	#Sans sous-titres
	sudo filebot -script fn:amc --output "$DIR_MEDIA" --log-file "$LOG_FILE" --action "$ACTION" --conflict "$CONFLICT" -non-strict --encoding "$ENCODING" --db xattr --def kodi="$IP_KODI" music=y artwork="$ARTWORK" seriesFormat="$DIR_MEDIA$SERIE_FORMAT" movieFormat="$DIR_MEDIA$MOVIE_FORMAT" ut_dir="$TR_TORRENT_DIR" ut_file="$TR_TORRENT_NAME" ut_kind="$UT_KIND" ut_title="$TR_TORRENT_NAME" >> "$FILELOG" 2>&1
fi

LINE_LOG=`tail -n 150 "$FILELOG" |grep -n -F "********************************************************"|tail -n 2|head -n 1|cut -d: -f1`
NUMBER_LINE=`expr 150 - $LINE_LOG`

if ! [ -z `tail -n 150 "$FILELOG" |tail -n $NUMBER_LINE |grep "already exists"` ] > /dev/null 2>&1
then
	#fichier deja existant
	#tester si c'est du mkv ou du mp4 = facilement modifiable
	TR_TORRENT_LENGTH=`stat -c "%s" "$TR_TORRENT_DIR/$TR_TORRENT_NAME"`
	EXISTING_FILE=`tail -n 150 "$FILELOG" |tail -n $NUMBER_LINE |grep "already exists" |sed -E 's/(.*)\] because \[(.*)(\] already exists)/\2/'`
	EXISTING_FILE_LENGTH=`stat -c "%s" "$EXISTING_FILE"`
	if [ "$TR_TORRENT_LENGTH" -eq "$EXISTING_FILE_LENGTH" ] >/dev/null 2>&1
	then
		#A voir pour tester  si il est possible de récupérer la bande audio
		rm -f "$TR_TORRENT_DIR/$TR_TORRENT_NAME" 1>&2 >> $FILETOSEND
		echo $(date +"%d-%m-%y %T") "Suppression de $TR_TORRENT_DIR/$TR_TORRENT_NAME : $TR_TORRENT_LENGTH (Ancien : $EXISTING_FILE_LENGTH)" >> "$FILELOG"
		echo "Suppression de $TR_TORRENT_DIR/$TR_TORRENT_NAME" 1>&2 >> $FILETOSEND
	else
		#A voir pour tester si c'est du HD ou pas, lequel faut remplacer etc
		echo $(date +"%d-%m-%y %T") Une action doit être effectuée pour le fichier suivant :  "$TR_TORRENT_DIR/$TR_TORRENT_NAME" >> "$FILELOG"
		echo "Une action doit être effectuée pour le fichier suivant : $TR_TORRENT_DIR/$TR_TORRENT_NAME" 1>&2 >> $FILETOSEND
	fi
else
	#On modifie les droits si un fichier est rajouté
	if ! [ -z `tail -n 150 "$FILELOG" |tail -n $NUMBER_LINE |grep -F "[MOVE] From"` ] > /dev/null 2>&1
	then
		tail -n 150 "$FILELOG" |tail -n $NUMBER_LINE |grep -F "[MOVE] From" 1>&2 >> $FILETOSEND
		#On modifie les droits sur les fichiers téléchargés
		DIR_PATH=`tail -n 150 "$FILELOG" |tail -n $NUMBER_LINE |grep -F "[MOVE] From" |sed -E 's/(.*)\] to \[(.*)(\])/\2/'`
		DIR_PATH=`dirname "$DIR_PATH"`
		#On s'assure que le chemin ou on change les droits correspond bien au chemin ou on stocke les films et séries
		if [ -z `echo "$DIR_PATH" |grep "$DIR_MEDIA"` ] >/dev/null 2>&1
		then
			echo $(date +"%d-%m-%y %T") "Le script a voulu changer les droits du dossier $DIR_PATH : refusé pour prévenir d'une mauvaise manipulation. $DIR_MEDIA" 1>&2 >> $FILETOSEND
		else
			sudo chown -R "$USER_RW_DISK":"$GROUP_RW_DISK" "$DIR_PATH" 1>&2 >> $FILETOSEND
			sudo chmod -R 777 "$DIR_PATH" 1>&2 >> $FILETOSEND
			echo $(date +"%d-%m-%y %T") "Modification des droits pour le dossier $DIR_PATH" >> "$FILELOG"
		fi
	else
		echo $(date +"%d-%m-%y %T") "Aucun fichie déplacé : " `tail -n 150 "$FILELOG" |tail -n $NUMBER_LINE |grep -F "[MOVE] From"` 1>&2 >> $FILETOSEND
	fi
fi

#On enleve le torrent de transmission
echo $(date +"%d-%m-%y %T") "transmission-remote $IP_TRANSMISSION:$RPC_PORT_TRANSMISSION -n $USER_TRANSMISSION:$PASSWORD_TRANSMISSION -l |grep -F Finished  |awk "\''{print $1}'\' >> "$FILELOG"
for TR_ID in `transmission-remote "$IP_TRANSMISSION":"$RPC_PORT_TRANSMISSION" -n "$USER_TRANSMISSION":"$PASSWORD_TRANSMISSION" -l |grep -F Finished  |awk '{print $1}'`; do
#    `transmission-remote "$IP_TRANSMISSION":"$RPC_PORT_TRANSMISSION" -n "$USER_TRANSMISSION":"$PASSWORD_TRANSMISSION" -t "${TR_ID%\*}" -r`
    `transmission-remote "$IP_TRANSMISSION":"$RPC_PORT_TRANSMISSION" -n "$USER_TRANSMISSION":"$PASSWORD_TRANSMISSION" -t "${TR_ID}" -r`
done


#echo $(date +"%d-%m-%y %T") "Statut : $?" >> "$FILELOG"
echo "********************************************************" >> "$FILELOG"
