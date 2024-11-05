#!/bin/bash

# Hidden file to store the user's choice
CACHE_FILE="$HOME/.script_choices"

# Define the options and corresponding URLs
declare -A region_urls=(
    ["1"]="us1"
    ["2"]="au1"
    ["3"]="euw31"
    ["4"]="ca1"
    ["5"]="ap1"
    ["6"]="aps1"
    ["7"]="aps2"
)

# Define the options and corresponding URLs
declare -A region_names=(
    ["1"]="United States"
    ["2"]="Europe (AWS)"
    ["3"]="Europe (GCP)"
    ["4"]="Canada"
    ["5"]="Asia Pacific (Singapore)"
    ["6"]="Asia Pacific (Mumbai)"
    ["7"]="Asia Pacific (Sydney)"
)

# Display the menu to the user
function display_menu() {
    # clear
    echo 
    echo "Select a region:"
    echo
    echo "1) United States"
    echo "2) Europe (AWS)"
    echo "3) Europe (GCP)"
    echo "4) Canada"
    echo "6) Asia Pacific (Singapore)"
    echo "5) Asia Pacific (Mumbai)"
    echo "7) Asia Pacific (Sydney)"
    echo
}

# Function to get user's choice
function get_choice() {
    local tries=0
    local max_tries=3

    while [[ $tries -lt $max_tries ]]; do
        # Display the menu
        display_menu

        # Read the user's choice
        read -p "Enter your choice (1-7): " choice

        echo
        # Check if the input is a valid choice
        if [[ ${region_urls[$choice]+_} ]]; then
            # Valid choice: construct and print the Raw URL
            RAW_URL="https://ingest.${region_urls[$choice]}.sentinelone.net/services/collector/raw?sourcetype=marketplace-paloaltonetworksfirewall-latest"
            echo "You selected region $choice. The URL is: ${RAW_URL}"

            # Ask the user if they want to save the choice
            read -p "Would you like to save this choice for future use? (y/n): " save_choice
            if [[ "$save_choice" == "y" || "$save_choice" == "Y" ]]; then
                echo "$choice" > "$CACHE_FILE"
                echo "Choice saved."
            fi

            return 0
        else
            # Invalid choice
            echo "Invalid choice. Please try again."
            ((tries++))
        fi
    done

    # If the user failed to make a valid choice in 3 tries
    echo "Too many invalid attempts. Exiting."
    return 1
}

# Check if there is a saved choice in the hidden file
if [[ -f "$CACHE_FILE" ]]; then
    saved_choice=$(cat "$CACHE_FILE")
    
    # Ask the user if they want to use the saved choice
    if [[ ${region_urls[$saved_choice]+_} ]]; then
        read -p "Use the saved region choice (region $saved_choice: ${region_names[$saved_choice]})? (y/n): " use_saved

        if [[ "$use_saved" == "y" || "$use_saved" == "Y" ]]; then
            RAW_URL="https://ingest.${region_urls[$saved_choice]}.sentinelone.net/services/collector/raw?sourcetype=marketplace-paloaltonetworksfirewall-latest"
            echo "Using saved region. The URL is: ${RAW_URL}"
            exit 0
        fi
    fi
fi

# Run the get_choice function

get_choice