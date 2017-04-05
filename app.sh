#!/bin/bash

CLIENT_ID=812331059426-iui8aml6jab3sukfiitggdspbqmnqtin.apps.googleusercontent.com
SECRET_KEY=3xvHNbpE5UNx5YQlirlPa3vd

function createUserInfo(){
	local CLIENT_ID=$1

	curl -s -d \
		"client_id=$CLIENT_ID&scope=https://www.googleapis.com/auth/contacts"\
		https://accounts.google.com/o/oauth2/device/code
}

function getFromInfo(){
	local INFO=$1
	local VALUE=$2

	echo $INFO | jq ".$VALUE" | cut -d"\"" -f 2
}

function displayUserInfo(){
	local INFO=$1

	echo "Verification URL:" $(getFromInfo "$INFO" "verification_url")
	echo "User Code:" $(getFromInfo "$INFO" "user_code")
}

function singlePollAuth(){
	local CLIENT_ID=$1
	local SECRET_KEY=$2
	local DEVICE_CODE=$3

	curl -s -d "client_id=$CLIENT_ID&client_secret=$SECRET_KEY&code=$DEVICE_CODE&grant_type=http://oauth.net/grant_type/device/1.0" \
		 -H "Content-Type: application/x-www-form-urlencoded" \
		 https://www.googleapis.com/oauth2/v4/token
}

function checkAuthorization(){
	local RESPONSE=$1
}


function pollGoogleAuth(){
	local PENDING=false

	local INTERVAL=$1
	shift

	local RESPONSE

	while [[ $PENDING == false ]]; do
		RESPONSE=$(singlePollAuth $*)
		
		if [[ "$( echo "$RESPONSE" | jq '.access_token' )" != "null" ]]; then
			break
		fi

		sleep $INTERVAL 
	done

	echo $RESPONSE
}

USER_INFO=$(createUserInfo $CLIENT_ID)

displayUserInfo "$USER_INFO"

LOGIN_INFO=$( pollGoogleAuth $(getFromInfo "$USER_INFO" "interval") $CLIENT_ID $SECRET_KEY $(getFromInfo "$USER_INFO" "device_code") )

echo "Authenticated!!"

echo "Login Info: $LOGIN_INFO"
