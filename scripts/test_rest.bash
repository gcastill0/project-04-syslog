#!/bin/bash

# This script is designed to send a test message to the SentinelOne Data Lake (SDL) intake API.
# It prompts the user to enter their AI SIEM key, sets the necessary environment variables, 
# and constructs the appropriate API endpoint URL based on the specified region and source type.
# The script then sends a test message using the curl command to verify the connection and 
# configuration. The message includes a timestamp, hostname, and process ID for identification.

clear && echo

if [ -z "$SDL_API_TOKEN" ]; then
    read -s -p "Enter your AI SIEM KEY: " SDL_API_TOKEN
    export SDL_API_TOKEN
fi

# The REGION to the SDL intake API. The default value is us1. The other options are:
# US1: United States
# EU1: Europe (AWS)
# EUW31: Europe (GCP)
# CA1: Canada
# AP1: Asia Pacific (Singapore)
# APS1: Asia Pacific (Mumbai)
# APS2: Asia Pacific (Sydney)

REGION="us1"

# The default source is paloaltonetworksfirewall. The other options are: 
# fortinetfortimanager, 
# zscalerinternetaccess, 
# ciscofirewallthreatdefense, and 
# fortinetfortigate. 

# Alternatively, you can replace the SOURCETYPE variable with syslog.
SOURCE="paloaltonetworksfirewall"

# The SOURCETYPE to the SDL intake API. 
SOURCETYPE="marketplace-${SOURCE}-latest"

SDL_URL="https://ingest.${REGION}.sentinelone.net/services/collector/raw?sourcetype=${SOURCETYPE}"

  # Detect mac OSX which does not support milliseconds
  if [[ "$(uname)" == "Darwin" ]]; then
    timestamp=$(date '+%b %d %T.000')
  else
    timestamp=$(date '+%b %d %T.%N')
  fi

echo && echo
message="${timestamp} $(hostname) tester[$$]: Test message to SDL intake API using curl and ${SOURCE}"
echo $message && echo && echo

# Check if the environment variable SDL_API_TOKEN exists and is not empty
if [ -z "${SDL_API_TOKEN+x}" ]; then
    echo "Error: The environment variable SDL_API_TOKEN is not set or is empty."
    exit 1
fi

# Send the test message to the SDL intake API
curl -v -k "${SDL_URL}" \
  -H "Authorization: Bearer ${SDL_API_TOKEN}" \
  -H "Accept: application/text" \
  -d "${message}" \
  -x POST
