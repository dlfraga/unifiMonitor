#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

unifiUrl=$(grep unifiUrl $DIR/.unifi-env | cut -d '=' -f2)
unifiUsername=$(grep unifiUsername $DIR/.unifi-env | cut -d '=' -f2)
unifiPassword=$(grep unifiPassword $DIR/.unifi-env | cut -d '=' -f2)
authCookiePath=$(grep authCookiePath $DIR/.unifi-env | cut -d '=' -f2)

apiUrlToQuery=$1
authCookiePath=$DIR/cookiejar
logFile=$DIR/connectionsUnifi.log
curlBin=/usr/bin/curl
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

function validatePaths() {
local curlBin=$(which curl)

if [ $curlBin == ""  ]; then
	echo "Cannot find curl. Please set your PATH variable or define curl path manually."
	echo "[\"errorMsg\",\"Cannot find the curl command\"]"
	exit 1;
fi
}

function login () {
  echo "Trying to login" >> $logFile
  response=$(curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"$unifiUsername\",\"password\":\"$unifiPassword\",\"remember\":false,\"strict\":true}" -s $unifiUrl/api/login -c $authCookiePath)
  echo "curl -X POST -H "Content-Type: application/json" -d "{\"username\":\"$unifiUsername\",\"password\":\"$unifiPassword\",\"remember\":false,\"strict\":true}" -s $unifiUrl/api/login -c $authCookiePath" >> $logFile
  echo $response >> $logFile
}

function query() {
#Query the unifi api
  response=$(curl -X GET -b $authCookiePath -s "$unifiUrl"/"$apiUrlToQuery")
  echo $response >> $logFile
  echo $response
}

validatePaths
checkLogin

if [ "$isLoggedIn" == 1 ]; then
  echo "Already logged in. Proceeding" >> $logFile
else 
  login
  checkLogin
  if [ "$isLoggedIn" == 0 ]; then
    echo "Can't login to the unifi dashboard. Please check the logs and responses" >> $logFile
    echo "[\"errorMsg\",\"Cannot login to the unifi API\"]"
    exit 1
  fi
fi

query $apiUrlToQuery
