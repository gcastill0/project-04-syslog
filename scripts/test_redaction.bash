#!/bin/bash

# Set initial message number
counter=1

# Simulate a thread number
thread=$((RANDOM % 1024 + 1))

# Define the destination (localhost in this case, change as needed)
destination="localhost"
port="514"

# Pick 5 unique random indexes for injecting test logs
inject_indices=($(shuf -i 1-100 -n 5))

# Loop to send 100 messages
while [ $counter -le 100 ]; do
  # Generate a timestamp with/without nanoseconds
  if [[ "$(uname)" == "Darwin" ]]; then
    timestamp=$(date '+%b %d %T.000')
  else
    timestamp=$(date '+%b %d %T.%N')
  fi

  if [[ " ${inject_indices[@]} " =~ " ${counter} " ]]; then
    # Inject redaction test log using current timestamp
    case $((RANDOM % 5)) in
      0)
        test_log="${timestamp} fw1 CheckPoint - [action:\"Accept\"; proto:\"1\"; icmp_type:\"8\"; rule_name:\"Implied Rule\"; dst:\"8.8.8.8\";]"
        ;;
      1)
        test_log="${timestamp} fw2 CheckPoint - [action:\"Accept\"; proto:\"1\"; icmp_type:\"8\"; rule_name:\"Implied Rule\"; dst:\"8.8.4.4\";]"
        ;;
      2)
        test_log="${timestamp} fw2 CheckPoint - [action:\"Accept\"; proto:\"1\"; icmp_type:\"8\"; rule_name:\"Implied Rule\"; dst:\"8.8.4.4\";]"
        ;;
      3)
        test_log="${timestamp} fw4 CheckPoint - [action:\"Accept\"; proto:\"1\"; icmp_type:\"8\"; rule_name:\"Implied Rule\"; dst:\"8.8.8.8\";]"
        ;;
      4)
        test_log="${timestamp} fw4 CheckPoint - [action:\"Accept\"; proto:\"1\"; icmp_type:\"8\"; rule_name:\"Implied Rule\"; dst:\"8.8.8.8\";]"
        ;;
    esac

    echo "$test_log" | nc -u -w1 $destination $port
    printf '%s\t' "[INJECTED] $test_log"
  else
    message="${timestamp} $(hostname) tester[$$]: Message number ${counter} to UDP port ${port} thread ${thread}"
    echo "$message" | nc -u -w1 $destination $port
    printf '%s\t' "$message"
  fi

  ((counter++))
  delay=$((RANDOM % 5 + 1))

  while [ $delay -gt 0 ]; do
    echo -n "."
    sleep 1
    ((delay--))
  done

  echo ""
done