#!/bin/bash

function getAllEmails(){
  mkdir -p "groups"

  local EMAILS=$(cat groups/* | jq -s '. | map(.students | map(.email)) | flatten[]' | xargs -I% echo "from: %, to: %" | paste -sd ",")

  echo "{$EMAILS} after:yyyy/mm/dd before:yyyy/mm/dd"
}