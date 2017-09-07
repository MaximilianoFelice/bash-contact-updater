#!/bin/bash

#
# Requires cookies.txt (with logged in cookie)
#
#

COOKIES=cookies.txt

function fetchPage() {
  local URL=$1
  local COOKIES=$2
  local FILE=$3

  mkdir -p crawled

  local FILE_NAME="crawled/$FILE"
  wget --quiet -x --load-cookies $COOKIES $URL -O "$FILE_NAME"

  echo $FILE_NAME
}

function sisOpValue(){
  local BASE=$1
  local INNER=$2
  local PROP=$3

  echo ".[$BASE].children[$INNER].children | .[] | select(.class == \"$PROP\").text"
}

function extractStudentsJSON() {
  local FILE_NAME=$1

  pup --color -f "$FILE_NAME" 'div.caption json{}' |\
    jq -c \
      'def extract(base; inner; prop): .[base].children[inner].children | .[] | select(.class == prop).text;
      map(.children) | map({firstName: extract(0; 0; "lblNombre"), lastName: extract(0; 0; "lblApellido"), id: extract(1; 0; "lblLegajo"), email: extract(1; 1; "lblEmail"), classId: extract(1; 2; "lblCurso") })'
}

function extractGroupName() {
  local FILE_NAME=$1

  pup --color -f "$FILE_NAME" 'div.page-header h1 text{}' | sed 's/Grupo: //g' | xargs -I% echo "\"%\""
}

function extractGroupEscapedName() {
  local FILE_NAME=$1

  pup --color -f "$FILE_NAME" 'div.page-header div.form-inline h4 a json{}' | jq '.[0].text' | sed 's/tp-....-.c-//g'
}

function extractGroupRepo() {
  local FILE_NAME=$1

  pup --color -f "$FILE_NAME" 'div.page-header div.form-inline h4 a json{}' | jq '.[0].href'
}

function processGroupJSON() {
  local GROUP_HTML=$1

  local NAME=$(extractGroupName "$GROUP_HTML")
  local ESCAPED_NAME=$(extractGroupEscapedName "$GROUP_HTML")
  local REPO=$(extractGroupRepo "$GROUP_HTML")
  local STUDENTS=$(extractStudentsJSON "$GROUP_HTML")

  echo "$STUDENTS" | jq -c "{name: $NAME, escapedName: $ESCAPED_NAME, repo: $REPO, students: .}"
}

function processGroups() {
  local COOKIES=$1
  
  mkdir -p groups

  local HTML_FILE=0

  while IFS='' read -r url || [[ -n "$url" ]]; do
    echo
    echo -n "Fetching group: $url... "
    local GROUP_HTML=$(fetchPage "$url" "$COOKIES" "$HTML_FILE.html")
    echo "Done!"

    echo
    echo -n "Processing JSON of file: $GROUP_HTML... "
    local GROUP=$(processGroupJSON "$GROUP_HTML")
    echo "Done!"

    echo
    echo -n "Saving group... "
    local NAME=$(echo "$GROUP" | jq '.escapedName' | sed 's/"//g')

    echo "$GROUP" > "groups/$NAME.json"
    echo "Done!"
    echo

    HTML_FILE=$(($HTML_FILE + 1))
  done
}

function findGroups() {
  local COOKIES=$1

  local PAGE=$(fetchPage "https://inscripciones.utnso.com/backoffice/index.php" $COOKIES "index.html")

  pup --color -f "$PAGE" 'div#MisGrupos table tbody tr td a attr{href}' | grep -v "github" | xargs -I% echo "https://inscripciones.utnso.com/backoffice/%"
}
