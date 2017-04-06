#!/bin/bash

function getAllEmails(){
  mkdir -p "groups"

  cat groups/* | jq -s '. | map(.students | map(.email)) | flatten[]' | xargs -I% echo "from:% to:%" | xargs -n 40 | xargs -I% printf "\n{%} after:yyyy/mm/dd before:yyyy/mm/dd\n"
}