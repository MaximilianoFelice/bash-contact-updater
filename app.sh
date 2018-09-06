#!/bin/bash

source auth.sh
source crawler.sh
source contacts.sh
source mail.sh

# TODO: Generalie "asking for yes/no" logic
echo 
read -p "Would you like to crawl groups? (Y/n): " RECRAWL
echo
if [[ $RECRAWL =~ ^[Yy]$ ]]; then
    rm -rf "groups/"
    rm -rf "crawled/"
    findGroups "$COOKIES" | processGroups "$COOKIES"
fi

echo 
read -p "Would you like to upload the contacts to your account? (Y/n): " UPDATE
echo
if [[ $UPDATE =~ ^[Yy]$ ]]; then
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

    read -p "Email that will contain contacts:" USER_EMAIL

    export USER_EMAIL
    export LOGIN_INFO
    export GROUP_PREFIX
    ls -1 groups/ | xargs -I% bash -c 'source auth.sh; source crawler.sh; source contacts.sh; createContactGroupFromJSON "$LOGIN_INFO" "$USER_EMAIL" "$GROUP_PREFIX" %'
fi

echo 
read -p "Would you like me to generate filters for Gmail? (Y/n): " FILTERS
echo
if [[ $FILTERS =~ ^[Yy]$ ]]; then
    echo "You can add the following filter on Gmail https://mail.google.com/mail/u/0/#settings/filters"
    echo "If you wish to set the date on the filters you can add at the end: {..} AND after:yyyy/mm/dd AND before:yyyy/mm/dd\n"
    echo
    echo "Remember that OSX xargs is broken"
    echo $(getAllEmails)
fi
