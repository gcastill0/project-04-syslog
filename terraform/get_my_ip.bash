# This script retrieves the public IP address of the machine running it
# by making a request to the ipify API (https://api.ipify.org).
# The result is then formatted as a JSON object and printed to the console.
#
# Usage:
#   Run the script directly in a bash shell.
#
# Output:
#   A JSON string containing the public IP address, e.g.:
#   {"ip": "203.0.113.42"}
#
# Dependencies:
#   - curl: Ensure that the `curl` command-line tool is installed and available.
#!/bin/bash
IP=$(curl -s https://api.ipify.org)
echo "{\"ip\": \"${IP}\"}"