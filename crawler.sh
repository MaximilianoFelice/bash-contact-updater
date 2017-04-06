#!/bin/bash

#
# Requires cookies.txt (with logged in cookie)
#
#

COOKIES=cookies.txt

function downloadGroup() {
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
      --arg firstName "$(sisOpValue 0 0 lblNombre)" \
      --arg lastName "$(sisOpValue 0 0 lblApellido)" \
      --arg id "$(sisOpValue 1 0 lblLegajo)" \
      --arg email "$(sisOpValue 1 1 lblEmail)" \
      --arg classId "$(sisOpValue 1 2 lblCurso)" \
      'map(.children) | map({firstName: $firstName, lastName: $lastName, id: $id, email: $email, classId: $classId })'
}

function extractGroupName() {
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
  local REPO=$(extractGroupRepo "$GROUP_HTML")
  local STUDENTS=$(extractStudentsJSON "$GROUP_HTML")

  echo "$STUDENTS" | jq -c "{name: $NAME, repo: $REPO, students: .}"
}

function processGroups() {
  local COOKIES=$1
  mkdir -p groups

  local HTML_FILE=0

  while IFS='' read -r url || [[ -n "$url" ]]; do
    echo
    echo -n "Fetching group: $url... "
    local GROUP_HTML=$(downloadGroup "$url" "$COOKIES" "$HTML_FILE.html")
    echo "Done!"

    echo
    echo -n "Processing JSON of file: $GROUP_HTML... "
    local GROUP=$(processGroupJSON "$GROUP_HTML")
    echo "Done!"

    echo
    echo -n "Saving group... "
    local NAME=$(echo "$GROUP" | jq '.name' | sed 's/"//g')

    echo "$GROUP" > "groups/$NAME.json"
    echo "Done!"
    echo

    HTML_FILE=$(($HTML_FILE + 1))
  done
}