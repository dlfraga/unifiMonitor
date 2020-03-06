#!/bin/bash

apiUrlToQuery="$1"
unifiUrl=$(grep unifiUrl .env | cut -d '=' -f2)
unifiUsername=$(grep unifiUsername .env | cut -d '=' -f2)
unifiPassword=$(grep unifiPassword .env | cut -d '=' -f2)
authCookiePath=$(grep authCookiePath .env | cut -d '=' -f2)
logFile=$(grep logFile .env | cut -d '=' -f2)

isLoggedIn=0
response=""

function checkLogin() {
##Checks if our cookie is still valid

  if [ ! -f "$authCookiePath" ]; then
    #if there's no cookie we need to login again
    isLoggedIn=0
    return 1
  else
    #Check if the cookie is still valid
    response=$(curl -X GET -b $authCookiePath -s $unifiUrl/api/self)
    echo $response >> $logFile
    if [ ! $? == 0 ]; then
      echo "Curl encountered an error" >> $logFile
      isLoggedIn=0
      return 1
    elif [[ $response == *"LoginRequired"* ]]; then
      echo "Cookie not valid" >> $logFile
      isLoggedIn=0
      return 1
    elif [[ $response == *"ok"* ]]; then
      echo "Cookie exists and is valid" >> $logFile
      isLoggedIn=1
      return 0;
    fi
  fi

#when in doubt try to login again
isLoggedIn=0
}

function login () {
  echo "Trying to login" >> $logFile
  response=$(curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"$unifiUsername\",\"password\":\"$unifiPassword\",\"remember\":false,\"strict\":true}" -s "$unifiUrl"/api/login -c $authCookiePath)
  echo $response >> $logFile
}

function query() {
#Query the unifi api
  response=$(curl -X GET -b $authCookiePath -s "$unifiUrl"/"$1")
  echo $response >> $logFile
  echo $response
}

checkLogin

if [ "$isLoggedIn" == 1 ]; then
  echo "Already logged in. Proceeding" >> $logFile
else 
  login
  checkLogin
  if [ "$isLoggedIn" == 1 ]; then
    echo "Can't login to the unifi dashboard. Please check the logs and responses" >> $logFile
    exit 1
  fi
fi

query $1
