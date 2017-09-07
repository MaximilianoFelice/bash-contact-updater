#!/bin/bash

source auth.sh
source crawler.sh
source contacts.sh
source mail.sh

YEAR=$(date +%Y)
QUARTER=$(( ($(date +%m | sed 's/^0*//') / 6) + 1 ))

GROUP_PREFIX="SisOp::${QUARTER}C-${YEAR}-"
printf "\nThe application will use the following prefix for groups: $GROUP_PREFIX"

printf "\nPlease Authenticate in the folowing web page:\n\n"

USER_INFO=$(createUserInfo "$CLIENT_ID")

requestUserLogin "$USER_INFO"

printf "\nAuthenticating... "

LOGIN_INFO=$(fetchLoginInfo "$USER_INFO" "$CLIENT_ID" "$SECRET_KEY")

printf "Authenticated!\n\n"


rm -rf "groups/"
rm -rf "crawled/"
findGroups "$COOKIES" | processGroups "$COOKIES"

echo
read -p "Email that will contain contacts:" USER_EMAIL

export USER_EMAIL
export LOGIN_INFO
export GROUP_PREFIX
ls -1 groups/ | xargs -I% bash -c 'source auth.sh; source crawler.sh; source contacts.sh; createContactGroupFromJSON "$LOGIN_INFO" "$USER_EMAIL" "$GROUP_PREFIX" %'

echo "You can add the following filter on GMAIL https://mail.google.com/mail/u/0/#settings/filters"
echo $(getAllEmails)
