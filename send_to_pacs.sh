#!/usr/bin/env bash

# Configuration variables
WATCH_DIR="/path/to/your/dicom_directory"
PACS_AET="YOUR_PACS_AET"
PACS_HOST="PACS_SERVER_IP"
PACS_PORT=104
CALLING_AET="YOUR_CALLING_AET"
LOG_DIR="/usr/local/bin/log"

LOG_FILE="$LOG_DIR/dicom_uploaded_files.log"
ERROR_LOG="$LOG_DIR/dicom_error_files.log"
INVALID_LOG="$LOG_DIR/dicom_invalid_files.log"
BATCH_SIZE=500
MAX_CONCURRENT_JOBS=2

# Ensure log directory and files exist
mkdir -p "$LOG_DIR"
touch "$LOG_FILE" "$ERROR_LOG" "$INVALID_LOG"

# Persistent files to track uploaded count
UPLOAD_COUNT_FILE="$LOG_DIR/upload_count.log"
TOTAL_COUNT_FILE="$LOG_DIR/total_count.log"
BATCH_FILE="$LOG_DIR/batch_file.log"
LAST_PROCESSED_FILE="$LOG_DIR/last_processed_marker"

if [[ ! -f "$UPLOAD_COUNT_FILE" ]]; then echo 0 > "$UPLOAD_COUNT_FILE"; fi
if [[ ! -f "$TOTAL_COUNT_FILE" ]]; then echo 0 > "$TOTAL_COUNT_FILE"; fi
if [[ ! -f "$LAST_PROCESSED_FILE" ]]; then touch -d "1970-01-01 00:00:00" "$LAST_PROCESSED_FILE"; fi

temp_cleanup() {
    echo "Cleaning up temporary files..."
}
trap temp_cleanup EXIT

# Check for required commands
for cmd in storescu dcmftest; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "$cmd is required but not installed."; exit 1; }
done

# Check if a file is a valid DICOM
is_valid_dicom() {
    local file="$1"
    if dcmftest "$file" | grep -q "seems to be"; then
        return 0
    else
        return 1
    fi
}

# Upload a single file to PACS
upload_file() {
    local file="$1"

    if grep -Fxq -- "$file" "$LOG_FILE" || grep -Fxq -- "$file" "$INVALID_LOG"; then
        return
    fi

    if ! is_valid_dicom "$file"; then
        echo "$file" >> "$INVALID_LOG"
        return
    fi

    timeout 5 storescu -aet "$CALLING_AET" -aec "$PACS_AET" "$PACS_HOST" "$PACS_PORT" "$file" && {
        echo "$file" >> "$LOG_FILE"
        flock "$UPLOAD_COUNT_FILE" bash -c 'count=$(cat "$1"); echo $((count + 1)) > "$1"' -- "$UPLOAD_COUNT_FILE"
        flock "$TOTAL_COUNT_FILE" bash -c 'total=$(cat "$1"); echo $((total + 1)) > "$1"' -- "$TOTAL_COUNT_FILE"
        touch -r "$file" "$LAST_PROCESSED_FILE"
    } || {
        echo "$file" >> "$ERROR_LOG"
    } &

    while (( $(jobs -r -p | wc -l) >= MAX_CONCURRENT_JOBS )); do
        wait -n || break
    done
}

# Prepare next batch of files to upload
prepare_next_batch() {
    find "$WATCH_DIR" -type f \( ! -name "*.thumbnail-150.jpg" ! -name "*.thumbnail-50.jpg" \) \
        -not -newer "$LAST_PROCESSED_FILE" | awk -v log_file="$LOG_FILE" -v invalid_file="$INVALID_LOG" '
    BEGIN {
        while ((getline line < log_file) > 0) seen[line] = 1
        while ((getline line < invalid_file) > 0) seen[line] = 1
    }
    !($0 in seen) { print $0 }
    ' | head -n "$BATCH_SIZE" > "$BATCH_FILE"
}

# Begin first batch preparation
prepare_next_batch &

# Main upload loop
while true; do
    wait  # Ensure batch preparation is complete

    start_time=$(date +%s)
    files_found=0
    batch_count=0

    while IFS= read -r file; do
        upload_file "$file"
        files_found=$((files_found + 1))
        batch_count=$((batch_count + 1))

        if (( batch_count % 10 == 0 )); then
            echo "$batch_count" > "$UPLOAD_COUNT_FILE"
        fi
    done < "$BATCH_FILE"

    wait  # Wait for all background jobs

    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    uploaded_files_count=$(cat "$UPLOAD_COUNT_FILE")
    total_uploaded_count=$(cat "$TOTAL_COUNT_FILE")
    echo -e "\n📦 Batch uploaded: $uploaded_files_count"
    echo "⏱ Time: ${elapsed_time} seconds"
    echo "📊 Total uploaded: $total_uploaded_count"

    echo 0 > "$UPLOAD_COUNT_FILE"

    if [[ $files_found -eq 0 ]]; then
        echo "No new files found. Exiting."
        break
    fi

    prepare_next_batch &  # Prepare next batch in parallel
    sleep 2
done

# Final report
total_uploaded_count=$(cat "$TOTAL_COUNT_FILE")
echo "Upload completed."
echo "📊 Total studies uploaded: $total_uploaded_count"
