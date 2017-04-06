#!/bin/bash

function extractTag() {
  local CONTENT=$1
  local TAG=$2

  echo "$CONTENT" | sed -n "s:.*<$TAG>\(.*\)</$TAG>.*:\1:p"
}

function queryAPI() {
  local LOGIN_INFO=$1
  local URL=$2
  local PARAMS=$3

  curl -s \
    -d "alt=json&max-results=1" \
    -d "$PARAMS" \
    -X GET \
    -H "Authorization: Bearer $(getFromInfo "$LOGIN_INFO" "access_token")" \
    -G $URL
}

function postAPI() {
  local LOGIN_INFO=$1
  local URL=$2
  local XML=$3

  curl -s \
    -X POST \
    -H "Authorization: Bearer $(getFromInfo "$LOGIN_INFO" "access_token")" \
    -H "Content-Type: application/atom+xml" \
    -H "GData-Version: 3.0" \
    -d@- \
    $URL << EOF
$XML
EOF
}

function fetchContacts() {
  local EMAIL=$(echo "$2" | sed "s/@/%40/g")
  local FILTERS=$3

  if [[ "$FILTERS" != "" ]]; then
    FILTERS="q=\"$FILTERS\""
  fi

  queryAPI "$1" https://www.google.com/m8/feeds/contacts/$EMAIL/full "$FILTERS"
}

function fetchGroups() {
  local EMAIL=$(echo "$2" | sed "s/@/%40/g")

  queryAPI "$1" https://www.google.com/m8/feeds/groups/$EMAIL/full
}

function createGroup() {
  local EMAIL=$(echo "$2" | sed "s/@/%40/g")
  local GROUP_NAME=$3
  local GROUP_ESCAPED_NAME=$4
  local REPO=$5

  read -r -d '' XML << EOF
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:gd="http://schemas.google.com/g/2005">
  <atom:category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/contact/2008#group"/>
  <atom:title type="text">SisOp::1C-2017-$GROUP_ESCAPED_NAME</atom:title>
  <gd:extendedProperty name="sisop">
    <type>group</type>
    <name>$GROUP_NAME</name>
    <repo>$REPO</repo>
  </gd:extendedProperty>
</atom:entry>
EOF

  local RESPONSE=$(postAPI "$1" https://www.google.com/m8/feeds/groups/$EMAIL/full "$XML")

  extractTag "$RESPONSE" "id"
}

function createUserInGroup() {
  local EMAIL=$(echo "$2" | sed "s/@/%40/g")
  local CONTACT_EMAIL=$3
  local FIRST_NAME=$4
  local LAST_NAME=$5
  local ID=$6
  local CLASS_ID=$7
  local GROUP_URL=$8

  read -r -d '' XML << EOF
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:gd="http://schemas.google.com/g/2005">
  <atom:category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/contact/2008#contact"/>
  <gd:name>
     <gd:givenName>"$FIRST_NAME"</gd:givenName>
     <gd:familyName>"$LAST_NAME"</gd:familyName>
     <gd:fullName>"$FIRST_NAME $LAST_NAME"</gd:fullName>
  </gd:name>
  <gd:email rel="http://schemas.google.com/g/2005#other" primary="true" address="$CONTACT_EMAIL"/>
  <gContact:groupMembershipInfo deleted="false" href="$GROUP_URL"/>
  <gd:extendedProperty name="sisop">
    <type>student</type>
    <studentId>"$ID"</studentId>
    <classId>"$CLASS_ID"</classId>
  </gd:extendedProperty>
</atom:entry>
EOF

  local RESPONSE=$(postAPI "$1" https://www.google.com/m8/feeds/contacts/$EMAIL/full "$XML")

  extractTag "$RESPONSE" "id"
}

function createContactGroupFromJSON(){
  local LOGIN_INFO=$1
  local EMAIL=$2
  local JSON=$(cat "groups/$3")

  local NAME=$(echo "$JSON" | jq '.name' | sed 's/"//g')
  local ESCAPED_NAME=$(echo "$JSON" | jq '.escapedName' | sed 's/"//g')
  local REPO=$(echo "$JSON" | jq '.repo' | sed 's/"//g')
  local STUDENTS=$(echo "$JSON" | jq -c '.students')
  local STUDENTS_LEN=$(echo "$STUDENTS" | jq 'length')

  echo
  echo -n "Creating Group $NAME... "
  local GROUP_URL=$(createGroup "$LOGIN_INFO" "$EMAIL" "$NAME" "$ESCAPED_NAME" "$REPO")
  if [[ "$GROUP_URL" == "" ]]; then
    echo "ERROR: creating $EMAIL $NAME $ESCAPED_NAME $REPO"
    exit 1
  else
    echo "Done: $GROUP_URL"
  fi

  for n in `seq 0 $(($STUDENTS_LEN - 1))`; do
    local CURR=$(echo "$STUDENTS" | jq ".[$n]")

    local FIRST_NAME=$(echo "$CURR" | jq '.firstName' | sed 's/"//g')
    local LAST_NAME=$(echo "$CURR" | jq '.lastName' | sed 's/"//g')
    local ID=$(echo "$CURR" | jq '.id' | sed 's/"//g')
    local STUDENT_EMAIL=$(echo "$CURR" | jq '.email' | sed 's/"//g')
    local CLASS_ID=$(echo "$CURR" | jq '.classId' | sed 's/"//g')

    printf "\tAdding $FIRST_NAME $LAST_NAME... "
    local USER_URL=$(createUserInGroup "$LOGIN_INFO" "$EMAIL" "$STUDENT_EMAIL" "$FIRST_NAME" "$LAST_NAME" "$ID" "$CLASS_ID" "$GROUP_URL")
    if [[ "$USER_URL" == "" ]]; then
      echo "ERROR: creating $EMAIL $STUDENT_EMAIL $FIRST_NAME $LAST_NAME $ID $CLASS_ID $GROUP_URL"
      exit 1
    else
      echo "Done: $USER_URL"
    fi

  done

}