#!/bin/bash
IP=$(curl -s https://api.ipify.org)
echo "{\"ip\": \"${IP}\"}"