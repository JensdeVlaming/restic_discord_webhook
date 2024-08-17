#!/bin/bash

# Define URL and JSON file variables
URL=""
JSON_FILE="./discord_message.json"

# Check the number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 {started|failed|successful}"
    exit 1
fi

# Determine the status
STATUS="$1"

# Set the message and color based on the status
case "$STATUS" in
    started)
        TITLE="Starting backup for location: ${AUTORESTIC_LOCATION}"
        DESCRIPTION="Backup process has started."
        COLOR=16776960   # Yellow color for started
        ;;
    failed)
        TITLE="Backup failed for location: ${AUTORESTIC_LOCATION}"
        DESCRIPTION="The backup process has failed. Check the logs for details."
        COLOR=15548997   # More intense red color for failed
        ;;
    successful)
        TITLE="Backup successful for location: ${AUTORESTIC_LOCATION}"
        DESCRIPTION="Backup completed successfully."
        COLOR=3066993    # More vibrant green color for successful
        ;;
    *)
        echo "Invalid argument: $STATUS. Use started, failed, or successful."
        exit 1
        ;;
esac

# Function to get dynamic environment variables
get_dynamic_var() {
    local var_name="AUTORESTIC_${1}_0"
    eval echo \$$var_name
}

if [ "$STATUS" == "successful" ]; then
    # Dynamically access environment variables based on AUTORESTIC_LOCATION
    SNAPSHOT_ID=$(get_dynamic_var "SNAPSHOT_ID")
    PARENT_SNAPSHOT_ID=$(get_dynamic_var "PARENT_SNAPSHOT_ID")
    FILES_ADDED=$(get_dynamic_var "FILES_ADDED")
    FILES_CHANGED=$(get_dynamic_var "FILES_CHANGED")
    FILES_UNMODIFIED=$(get_dynamic_var "FILES_UNMODIFIED")
    DIRS_ADDED=$(get_dynamic_var "DIRS_ADDED")
    DIRS_CHANGED=$(get_dynamic_var "DIRS_CHANGED")
    DIRS_UNMODIFIED=$(get_dynamic_var "DIRS_UNMODIFIED")
    ADDED_SIZE=$(get_dynamic_var "ADDED_SIZE")
    PROCESSED_FILES=$(get_dynamic_var "PROCESSED_FILES")
    PROCESSED_SIZE=$(get_dynamic_var "PROCESSED_SIZE")
    PROCESSED_DURATION=$(get_dynamic_var "PROCESSED_DURATION")

    # Construct the description with environment variables
    DESCRIPTION+="

        Snapshot ID: ${SNAPSHOT_ID}
        Parent Snapshot ID: ${PARENT_SNAPSHOT_ID}
        Files Added: ${FILES_ADDED}
        Files Changed: ${FILES_CHANGED}
        Files Unmodified: ${FILES_UNMODIFIED}
        Dirs Added: ${DIRS_ADDED}
        Dirs Changed: ${DIRS_CHANGED}
        Dirs Unmodified: ${DIRS_UNMODIFIED}
        Added Size: ${ADDED_SIZE}
        Processed Files: ${PROCESSED_FILES}
        Processed Size: ${PROCESSED_SIZE}
        Processed Duration: ${PROCESSED_DURATION}
    "
fi

# Use jq to update the JSON file with the new title, description, and color
JSON_DATA=$(jq --arg title "$TITLE" --arg description "$DESCRIPTION" --argjson color "$COLOR" \
    '.embeds[0].title = $title | .embeds[0].description = $description | .embeds[0].color = $color' "$JSON_FILE")

# Execute the curl command
curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "$JSON_DATA" "$URL"