#!/bin/bash

source auth.sh

function queryAPI() {
	local LOGIN_INFO=$1
	local URL=$2
	local PARAMS=$3

	curl -v -s \
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

	curl -v -s -i \
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

	read -r -d '' XML << EOF
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:gd="http://schemas.google.com/g/2005">
  <atom:category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/contact/2008#group"/>
  <atom:title type="text">$GROUP_NAME</atom:title>
</atom:entry>
EOF
	postAPI "$1" https://www.google.com/m8/feeds/groups/$EMAIL/full "$XML"
}

printf "\nPlease Authenticate in the folowing web page:\n\n"

USER_INFO=$(createUserInfo "$CLIENT_ID")

requestUserLogin "$USER_INFO"

printf "\nAuthenticating...\n\n"

LOGIN_INFO=$(fetchLoginInfo "$USER_INFO" "$CLIENT_ID" "$SECRET_KEY")

printf "\nAuthenticated!\n\n"

printf "\nLogin Info: $LOGIN_INFO\n\n"

fetchContacts "$LOGIN_INFO" "gtaind@gmail.com"
