#!/bin/bash

# MergeX - PCAP & Hash Merger Tool
# By default merges PCAP, PCAPNG, and .22000 files, removing duplicates

show_help() {
    echo ""
    echo "MergeX - PCAP & Hash Merger Tool"
    echo "Usage: ./mergex.sh [source_path] [output_file]"
    echo ""
    echo "Example:"
    echo "  ./mergex.sh ~/handshakes clearhashes.22000"
    echo ""
    echo "Options:"
    echo "  -h        Show this help message"
    echo "  -ai       Auto-search and merge all PCAP files on the system"
    echo ""
    exit 0
}

# Display MergeX Banner

echo "  __  __                     __  __"
echo " |  \/  | ___ _ __ __ _  ___ \\ \/ /   by:sadhuroot"
echo " | |\/| |/ _ \\ '__/ _\\\` |/ _ \\ \\  /"
echo " | |  | |  __/ | | (_| |  __/ /  \\"
echo " |_|  |_|\\___|_|  \\__, |\\___|/_/\\_\\"
echo "                    |___/"


# --------- ARGUMENT HANDLING ----------

if [[ "$1" == "-h" || "$1" == "--help" || $# -lt 1 ]]; then
    show_help
fi

WORKDIR="$(mktemp -d)"
OUTPUT_FILE=""
PCAP_COUNT=0
HASH22000_COUNT=0
FINAL_HASH_COUNT=0

if [[ "$1" == "-ai" ]]; then
    echo -e "\e[93m[+] Searching for PCAP, PCAPNG, and 22000 files system-wide...\e[0m"
    FILE_LIST=$(find / -type f \( -iname "*.pcap" -o -iname "*.pcapng" -o -iname "*.22000" \) 2>/dev/null)

    if [[ -z "$FILE_LIST" ]]; then
        echo -e "\e[91m[!] No files found.\e[0m"
        exit 1
    fi

    PCAP_FILES=()
    HASH_FILES=()
    for file in $FILE_LIST; do
        case "$file" in
            *.pcap|*.pcapng) PCAP_FILES+=("$file") ;;
            *.22000) HASH_FILES+=("$file") ;;
        esac
    done

    PCAP_COUNT=${#PCAP_FILES[@]}
    HASH22000_COUNT=${#HASH_FILES[@]}

    echo -e "\e[92m[+] Found $PCAP_COUNT PCAP/PCAPNG files and $HASH22000_COUNT .22000 files.\e[0m"

    read -p "Enter full path for the output file (e.g., /home/kali/Desktop/ready.22000): " OUTPUT_FILE

    if [[ "$PCAP_COUNT" -gt 0 ]]; then
        mergecap -w "$WORKDIR/combined.pcapng" "${PCAP_FILES[@]}" 2>&1 | grep -i 'damaged\|error' && echo -e "\e[93m[!] Some PCAP files might be damaged.\e[0m"
        hcxpcapngtool -o "$WORKDIR/converted.22000" "$WORKDIR/combined.pcapng" 2>&1 | grep -i 'warning\|error'
    else
        touch "$WORKDIR/converted.22000"
    fi

    cat "${HASH_FILES[@]}" "$WORKDIR/converted.22000" > "$WORKDIR/all.22000" 2>/dev/null
    sort -u "$WORKDIR/all.22000" > "$OUTPUT_FILE"

    FINAL_HASH_COUNT=$(wc -l < "$OUTPUT_FILE")

    rm -rf "$WORKDIR"

    echo -e "\e[92m[✓] Done! Merged hashes saved to: $OUTPUT_FILE\e[0m"
    echo -e "\e[94m[*] Stats:\n  PCAP/PCAPNG files: $PCAP_COUNT\n  .22000 files:      $HASH22000_COUNT\n  Total hashes:      $FINAL_HASH_COUNT\e[0m"
    exit 0
fi

# Manual mode
SOURCE_DIR="$1"
OUTPUT_FILE="$2"

if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "\e[91m[!] Source directory not found: $SOURCE_DIR\e[0m"
    exit 1
fi

PCAP_FILES=($(find "$SOURCE_DIR" -type f \( -iname "*.pcap" -o -iname "*.pcapng" \)))
HASH_FILES=($(find "$SOURCE_DIR" -type f -iname "*.22000"))

PCAP_COUNT=${#PCAP_FILES[@]}
HASH22000_COUNT=${#HASH_FILES[@]}

if [[ "$PCAP_COUNT" -gt 0 ]]; then
    mergecap -w "$WORKDIR/combined.pcapng" "${PCAP_FILES[@]}" 2>&1 | grep -i 'damaged\|error' && echo -e "\e[93m[!] Some PCAP files might be damaged.\e[0m"
    hcxpcapngtool -o "$WORKDIR/converted.22000" "$WORKDIR/combined.pcapng" 2>&1 | grep -i 'warning\|error'
else
    touch "$WORKDIR/converted.22000"
fi

cat "${HASH_FILES[@]}" "$WORKDIR/converted.22000" > "$WORKDIR/all.22000" 2>/dev/null
sort -u "$WORKDIR/all.22000" > "$OUTPUT_FILE"

FINAL_HASH_COUNT=$(wc -l < "$OUTPUT_FILE")

rm -rf "$WORKDIR"

echo -e "\e[92m[✓] Done! Merged hashes saved to: $OUTPUT_FILE\e[0m"
echo -e "\e[94m[*] Stats:\n  PCAP/PCAPNG files: $PCAP_COUNT\n  .22000 files:      $HASH22000_COUNT\n  Total hashes:      $FINAL_HASH_COUNT\e[0m"
