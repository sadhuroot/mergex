#!/bin/bash
# MergeX Interactive - Advanced PCAP & Hash Merger Tool
# Optimized for macOS ARM64 (Apple Silicon)
# Enhanced version with interactive CLI terminal

# Terminal colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Global variables
WORKDIR=""
OUTPUT_FILE=""
SOURCE_DIR=""
PCAP_COUNT=0
HASH22000_COUNT=0
FINAL_HASH_COUNT=0
TERMINAL_WIDTH=$(tput cols 2>/dev/null || echo 80)
PROGRESS_BAR_WIDTH=$((TERMINAL_WIDTH - 10))
VERBOSE=false
ARCH=$(uname -m)
OS=$(uname -s)
AUTO_MODE=false

# Check if running on macOS ARM64
check_system() {
    if [[ "$OS" != "Darwin" ]]; then
        echo -e "${YELLOW}[!] Warning: This script is optimized for macOS but detected: $OS${RESET}"
    fi
    
    if [[ "$ARCH" != "arm64" ]]; then
        echo -e "${YELLOW}[!] Warning: This script is optimized for ARM64 but detected: $ARCH${RESET}"
    fi
}

# Function to draw a progress bar
draw_progress_bar() {
    local percent=$1
    local completed=$((percent * PROGRESS_BAR_WIDTH / 100))
    local remaining=$((PROGRESS_BAR_WIDTH - completed))
    
    printf "\r[" 
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "] %3d%%" "$percent"
}

# Animated spinner function
spinner() {
    local pid=$1
    local msg="$2"
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    echo -ne "${CYAN}$msg${RESET}"
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r${CYAN}$msg${RESET} %c " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    
    printf "\r${GREEN}$msg [✓]${RESET}    \n"
}

# Show fancy banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔═════════════════════════════════════════════════════╗"
    echo "║                                                     ║"
    echo "║  ███╗   ███╗███████╗██████╗  ██████╗ ███████╗██╗  ██╗║"
    echo "║  ████╗ ████║██╔════╝██╔══██╗██╔════╝ ██╔════╝╚██╗██╔╝║"
    echo "║  ██╔████╔██║█████╗  ██████╔╝██║  ███╗█████╗   ╚███╔╝ ║"
    echo "║  ██║╚██╔╝██║██╔══╝  ██╔══██╗██║   ██║██╔══╝   ██╔██╗ ║"
    echo "║  ██║ ╚═╝ ██║███████╗██║  ██║╚██████╔╝███████╗██╔╝ ██╗║"
    echo "║  ╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝║"
    echo "║                                                     ║"
    echo "╚═════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e "${MAGENTA}      Advanced PCAP & Hash Merger Tool - Interactive${RESET}"
    echo -e "${BLUE}      Optimized for macOS ARM64 (Apple Silicon)${RESET}"
    echo -e "${DIM}      By: sadhuroot - Enhanced Interactive Version${RESET}\n"
}

# Show help message
show_help() {
    echo -e "${WHITE}${BOLD}MergeX Interactive - Advanced PCAP & Hash Merger Tool${RESET}"
    echo -e "${DIM}Optimized for macOS ARM64 (Apple Silicon)${RESET}\n"
    
    echo -e "${BOLD}Usage:${RESET}"
    echo -e "  ./mergex_interactive.sh [OPTIONS]\n"
    
    echo -e "${BOLD}Options:${RESET}"
    echo -e "  ${GREEN}-h, --help${RESET}       Show this help message"
    echo -e "  ${GREEN}-d, --dir PATH${RESET}   Specify source directory containing PCAP/hash files"
    echo -e "  ${GREEN}-o, --output FILE${RESET} Specify output file path"
    echo -e "  ${GREEN}-a, --auto${RESET}       Auto-search mode (will search all mounted volumes)"
    echo -e "  ${GREEN}-v, --verbose${RESET}    Enable verbose output\n"
    
    echo -e "${BOLD}Interactive Commands:${RESET}"
    echo -e "  In the interactive menu, you can use:"
    echo -e "  ${CYAN}1-9${RESET}               Select menu options"
    echo -e "  ${CYAN}q, exit${RESET}           Exit the program\n"
    
    echo -e "${BOLD}Examples:${RESET}"
    echo -e "  ./mergex_interactive.sh"
    echo -e "  ./mergex_interactive.sh -d ~/Downloads/captures -o ~/combined.22000"
    echo -e "  ./mergex_interactive.sh --auto --verbose\n"
}

# Check dependencies
check_dependencies() {
    local missing=false
    
    echo -e "${CYAN}[*] Checking required dependencies...${RESET}"
    
    # Check for Homebrew (needed for installing other dependencies)
    if ! command -v brew &>/dev/null; then
        echo -e "${YELLOW}[!] Homebrew not found. It's recommended for installing dependencies on macOS.${RESET}"
        read -p "Do you want to install Homebrew? (y/n): " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}[*] Installing Homebrew...${RESET}"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            echo -e "${RED}[!] Homebrew installation declined. Some dependencies may not be available.${RESET}"
            missing=true
        fi
    fi
    
    # Check for wireshark (for mergecap)
    if ! command -v mergecap &>/dev/null; then
        # Check common macOS Wireshark paths
        if [[ -f "/Applications/Wireshark.app/Contents/MacOS/mergecap" ]]; then
            echo -e "${YELLOW}[!] Found mergecap in Wireshark.app but it's not in your PATH.${RESET}"
            export PATH="$PATH:/Applications/Wireshark.app/Contents/MacOS"
            echo -e "${GREEN}[✓] Added Wireshark to PATH temporarily.${RESET}"
        else
            echo -e "${YELLOW}[!] mergecap not found (part of Wireshark).${RESET}"
            if command -v brew &>/dev/null; then
                read -p "Do you want to install Wireshark via Homebrew? (y/n): " choice
                if [[ "$choice" =~ ^[Yy]$ ]]; then
                    echo -e "${CYAN}[*] Installing Wireshark...${RESET}"
                    brew install --cask wireshark
                    # Check if it's in PATH after installation
                    if ! command -v mergecap &>/dev/null; then
                        echo -e "${YELLOW}[!] mergecap installed but not in PATH. Adding to PATH.${RESET}"
                        export PATH="$PATH:/Applications/Wireshark.app/Contents/MacOS"
                    fi
                else
                    echo -e "${RED}[!] Wireshark installation declined. Cannot proceed without mergecap.${RESET}"
                    missing=true
                fi
            else
                echo -e "${RED}[!] Cannot install Wireshark. Missing Homebrew and mergecap.${RESET}"
                missing=true
            fi
        fi
    fi
    
    # Check for hcxtools (for hcxpcapngtool)
    if ! command -v hcxpcapngtool &>/dev/null; then
        echo -e "${YELLOW}[!] hcxpcapngtool not found (part of hcxtools).${RESET}"
        if command -v brew &>/dev/null; then
            read -p "Do you want to install hcxtools via Homebrew? (y/n): " choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                echo -e "${CYAN}[*] Installing hcxtools...${RESET}"
                brew install hcxtools
            else
                echo -e "${RED}[!] hcxtools installation declined. Cannot proceed without hcxpcapngtool.${RESET}"
                missing=true
            fi
        else
            echo -e "${RED}[!] Cannot install hcxtools. Missing Homebrew.${RESET}"
            missing=true
        fi
    fi
    
    if [[ "$missing" == true ]]; then
        echo -e "${RED}[!] Some required dependencies are missing. Cannot proceed.${RESET}"
        exit 1
    else
        echo -e "${GREEN}[✓] All dependencies are installed and ready.${RESET}"
    fi
}

# Create temporary directory
setup_workdir() {
    WORKDIR=$(mktemp -d)
    if [[ ! -d "$WORKDIR" ]]; then
        echo -e "${RED}[!] Failed to create temporary working directory.${RESET}"
        exit 1
    fi
    
    # Register cleanup handler for unexpected exits
    trap cleanup EXIT
}

# Cleanup function
cleanup() {
    if [[ -d "$WORKDIR" ]]; then
        rm -rf "$WORKDIR"
    fi
}

# Find files function
find_files() {
    local search_path="$1"
    local depth="$2"
    local pcap_list=()
    local hash_list=()
    
    echo -e "${CYAN}[*] Searching for PCAP, PCAPNG, and 22000 files in ${search_path}...${RESET}"
    
    # Initialize empty files
    > "$WORKDIR/pcap_files.txt"
    > "$WORKDIR/hash_files.txt"
    
    # Animate the search process
    (find "$search_path" -type f \( -iname "*.pcap" -o -iname "*.pcapng" -o -iname "*.22000" \) -maxdepth "$depth" 2>/dev/null > "$WORKDIR/file_list.txt") &
    spinner $! "Scanning for files"
    
    if [[ ! -s "$WORKDIR/file_list.txt" ]]; then
        echo -e "${YELLOW}[!] No relevant files found in ${search_path}.${RESET}"
        return 1
    fi
    
    # Process each file and add to appropriate list
    while IFS= read -r file; do
        if [[ "$file" =~ \.(pcap|pcapng)$ ]]; then
            echo "$file" >> "$WORKDIR/pcap_files.txt"
        elif [[ "$file" =~ \.22000$ ]]; then
            echo "$file" >> "$WORKDIR/hash_files.txt"
        fi
    done < "$WORKDIR/file_list.txt"
    
    PCAP_COUNT=$(wc -l < "$WORKDIR/pcap_files.txt" 2>/dev/null || echo 0)
    HASH22000_COUNT=$(wc -l < "$WORKDIR/hash_files.txt" 2>/dev/null || echo 0)
    
    echo -e "${GREEN}[✓] Found ${BOLD}$PCAP_COUNT${RESET}${GREEN} PCAP/PCAPNG files and ${BOLD}$HASH22000_COUNT${RESET}${GREEN} .22000 files.${RESET}"
    
    return 0
}

# Process files function
process_files() {
    # Step 1: Merge PCAP files if any
    if [[ "$PCAP_COUNT" -gt 0 && -s "$WORKDIR/pcap_files.txt" ]]; then
        echo -e "${CYAN}[*] Merging PCAP/PCAPNG files...${RESET}"
        
        # Read files into an array (zsh/bash compatible)
        PCAP_FILES=()
        while IFS= read -r line; do
            PCAP_FILES+=("$line")
        done < "$WORKDIR/pcap_files.txt"
        
        if [[ ${#PCAP_FILES[@]} -eq 0 ]]; then
            echo -e "${YELLOW}[!] No PCAP files could be loaded from the list.${RESET}"
            return 1
        fi
        
        if [[ "$VERBOSE" == true ]]; then
            echo -e "${BLUE}[*] Processing ${#PCAP_FILES[@]} PCAP files.${RESET}"
            for file in "${PCAP_FILES[@]}"; do
                echo -e "   ${DIM}→ $file${RESET}"
            done
        fi
        
        # Start mergecap in background and capture output
        (mergecap -w "$WORKDIR/combined.pcapng" "${PCAP_FILES[@]}" 2>"$WORKDIR/mergecap_errors.log") &
        local pid=$!
        
        # Show spinner while process runs
        spinner $pid "Merging PCAP files"
        
        # Check if the merged file was created successfully
        if [[ ! -f "$WORKDIR/combined.pcapng" ]]; then
            echo -e "${RED}[!] Failed to merge PCAP files. Check for errors below:${RESET}"
            if [[ -f "$WORKDIR/mergecap_errors.log" ]]; then
                cat "$WORKDIR/mergecap_errors.log"
            else
                echo -e "${RED}[!] No error log available.${RESET}"
            fi
            return 1
        fi
        
        # Check for errors
        if [[ -f "$WORKDIR/mergecap_errors.log" ]] && grep -qi 'damaged\|error' "$WORKDIR/mergecap_errors.log"; then
            echo -e "${YELLOW}[!] Some PCAP files might be damaged. See details below:${RESET}"
            grep -i 'damaged\|error' "$WORKDIR/mergecap_errors.log" | while read -r line; do
                echo -e "   ${YELLOW}→ $line${RESET}"
            done
        fi
        
        # Step 2: Convert merged PCAP to hash format
        echo -e "${CYAN}[*] Converting PCAP data to hash format...${RESET}"
        
        (hcxpcapngtool -o "$WORKDIR/converted.22000" "$WORKDIR/combined.pcapng" 2>"$WORKDIR/hcx_errors.log") &
        local hcx_pid=$!
        
        # Show spinner while process runs
        spinner $hcx_pid "Converting to hash format"
        
        # Check if the converted file was created successfully
        if [[ ! -f "$WORKDIR/converted.22000" ]]; then
            echo -e "${YELLOW}[!] No hashes extracted from PCAP files. Creating empty file.${RESET}"
            touch "$WORKDIR/converted.22000"
        fi
        
        # Check for errors
        if [[ -f "$WORKDIR/hcx_errors.log" ]] && grep -qi 'warning\|error' "$WORKDIR/hcx_errors.log"; then
            echo -e "${YELLOW}[!] Some issues occurred during conversion:${RESET}"
            grep -i 'warning\|error' "$WORKDIR/hcx_errors.log" | while read -r line; do
                echo -e "   ${YELLOW}→ $line${RESET}"
            done
        fi
    else
        echo -e "${YELLOW}[!] No PCAP files to process. Skipping PCAP merging and conversion.${RESET}"
        touch "$WORKDIR/converted.22000"
    fi
    
    # Step 3: Combine all hash files
    echo -e "${CYAN}[*] Combining and deduplicating hash files...${RESET}"
    
    # Initialize an empty file for the combined hashes
    touch "$WORKDIR/all.22000"
    
    # Append converted hashes if they exist
    if [[ -f "$WORKDIR/converted.22000" ]]; then
        cat "$WORKDIR/converted.22000" > "$WORKDIR/all.22000"
    fi
    
    # Append hash files if any
    if [[ "$HASH22000_COUNT" -gt 0 && -s "$WORKDIR/hash_files.txt" ]]; then
        # Read hash files into an array (zsh/bash compatible)
        HASH_FILES=()
        while IFS= read -r line; do
            HASH_FILES+=("$line")
        done < "$WORKDIR/hash_files.txt"
        
        if [[ ${#HASH_FILES[@]} -gt 0 ]]; then
            if [[ "$VERBOSE" == true ]]; then
                echo -e "${BLUE}[*] Processing ${#HASH_FILES[@]} hash files.${RESET}"
                for file in "${HASH_FILES[@]}"; do
                    echo -e "   ${DIM}→ $file${RESET}"
                done
            fi
            
            # Combine files with progress
            for file in "${HASH_FILES[@]}"; do
                cat "$file" >> "$WORKDIR/all.22000" 2>/dev/null
            done
        fi
    fi
    
    # Validate output file path
    if [[ -z "$OUTPUT_FILE" ]]; then
        echo -e "${RED}[!] Output file not specified. Cannot proceed.${RESET}"
        return 1
    fi
    
    # Check if output is a directory
    if [[ -d "$OUTPUT_FILE" ]]; then
        # Create a default filename in the specified directory
        local timestamp=$(date +"%Y%m%d%H%M%S")
        OUTPUT_FILE="$OUTPUT_FILE/merged_hashes_$timestamp.22000"
        echo -e "${YELLOW}[!] Output path is a directory. Will save to: $OUTPUT_FILE${RESET}"
    fi
    
    # Make sure parent directory exists
    mkdir -p "$(dirname "$OUTPUT_FILE")" 2>/dev/null
    
    # Step 4: Remove duplicates (background process)
    (sort -u "$WORKDIR/all.22000" > "$OUTPUT_FILE") &
    local sort_pid=$!
    
    # Show spinner
    spinner $sort_pid "Removing duplicate hashes"
    
    # Check if the final file was created successfully
    if [[ ! -f "$OUTPUT_FILE" ]]; then
        echo -e "${RED}[!] Failed to create output file: $OUTPUT_FILE${RESET}"
        return 1
    fi
    
    # Get final stats
    FINAL_HASH_COUNT=$(wc -l < "$OUTPUT_FILE" 2>/dev/null || echo 0)
    
    return 0
}

# Show results function
show_results() {
    echo -e "\n${GREEN}${BOLD}══════════════ OPERATION COMPLETE ══════════════${RESET}\n"
    
    echo -e "${GREEN}[✓] Merged hashes saved to: ${WHITE}$OUTPUT_FILE${RESET}"
    echo
    echo -e "${CYAN}[*] Stats:${RESET}"
    echo -e "   ${BLUE}→ PCAP/PCAPNG files:${RESET} $PCAP_COUNT"
    echo -e "   ${BLUE}→ .22000 files:${RESET}      $HASH22000_COUNT" 
    echo -e "   ${BLUE}→ Total unique hashes:${RESET} $FINAL_HASH_COUNT"
    
    # If we have both input types, show deduplication stats
    if [[ "$PCAP_COUNT" -gt 0 && "$HASH22000_COUNT" -gt 0 ]]; then
        local converted_count=$(wc -l < "$WORKDIR/converted.22000" 2>/dev/null || echo 0)
        local all_count=$(wc -l < "$WORKDIR/all.22000" 2>/dev/null || echo 0)
        local duplicates=$((all_count - FINAL_HASH_COUNT))
        
        echo -e "   ${BLUE}→ Duplicates removed:${RESET} $duplicates"
    fi
    
    echo -e "\n${GREEN}${BOLD}══════════════════════════════════════════════${RESET}\n"
}

# Auto-search function
auto_search_mode() {
    echo -e "${CYAN}[*] Scanning volumes for PCAP, PCAPNG, and 22000 files...${RESET}"
    
    # Get list of mounted volumes (excluding system paths)
    local volumes=("/Volumes/"* "$HOME")
    
    # Create empty files list files
    > "$WORKDIR/pcap_files.txt"
    > "$WORKDIR/hash_files.txt"
    
    PCAP_COUNT=0
    HASH22000_COUNT=0
    
    # Search each volume
    for vol in "${volumes[@]}"; do
        if [[ -d "$vol" ]]; then
            echo -e "${CYAN}[*] Scanning: ${vol}${RESET}"
            
            # Find PCap files
            find "$vol" -type f \( -iname "*.pcap" -o -iname "*.pcapng" \) -print 2>/dev/null | while read -r file; do
                echo "$file" >> "$WORKDIR/pcap_files.txt"
                ((PCAP_COUNT++))
                echo -ne "\r${GREEN}[*] Found: ${PCAP_COUNT} PCAP files, ${HASH22000_COUNT} hash files${RESET}"
            done
            
            # Find Hash files
            find "$vol" -type f -iname "*.22000" -print 2>/dev/null | while read -r file; do
                echo "$file" >> "$WORKDIR/hash_files.txt"
                ((HASH22000_COUNT++))
                echo -ne "\r${GREEN}[*] Found: ${PCAP_COUNT} PCAP files, ${HASH22000_COUNT} hash files${RESET}"
            done
        fi
    done
    
    echo
    
    # Update counts from files (more accurate than counter in loop)
    PCAP_COUNT=$(wc -l < "$WORKDIR/pcap_files.txt" 2>/dev/null || echo 0)
    HASH22000_COUNT=$(wc -l < "$WORKDIR/hash_files.txt" 2>/dev/null || echo 0)
    
    echo -e "${GREEN}[✓] Found ${BOLD}$PCAP_COUNT${RESET}${GREEN} PCAP/PCAPNG files and ${BOLD}$HASH22000_COUNT${RESET}${GREEN} .22000 files.${RESET}"
    
    if [[ "$PCAP_COUNT" -eq 0 && "$HASH22000_COUNT" -eq 0 ]]; then
        echo -e "${RED}[!] No files found. Cannot proceed.${RESET}"
        return 1
    fi
    
    return 0
}

# Validate output path
validate_output_path() {
    local path="$1"
    
    # Check if path is empty
    if [[ -z "$path" ]]; then
        echo -e "${RED}[!] Output file path cannot be empty.${RESET}"
        return 1
    fi
    
    # Check if path is a directory
    if [[ -d "$path" ]]; then
        # Create a default filename in the specified directory
        local timestamp=$(date +"%Y%m%d%H%M%S")
        OUTPUT_FILE="$path/merged_hashes_$timestamp.22000"
        echo -e "${YELLOW}[!] Output path is a directory. Will save to: $OUTPUT_FILE${RESET}"
        return 0
    fi
    
    # Check if parent directory exists or can be created
    local parent_dir=$(dirname "$path")
    if [[ ! -d "$parent_dir" ]]; then
        echo -e "${YELLOW}[!] Parent directory doesn't exist. Attempting to create: $parent_dir${RESET}"
        if ! mkdir -p "$parent_dir" 2>/dev/null; then
            echo -e "${RED}[!] Failed to create parent directory. Choose another location.${RESET}"
            return 1
        fi
    fi
    
    # Check if file already exists
    if [[ -f "$path" ]]; then
        echo -e "${YELLOW}[!] Output file already exists. It will be overwritten.${RESET}"
    fi
    
    # Check if we can write to the file
    if ! touch "$path" 2>/dev/null; then
        echo -e "${RED}[!] Cannot write to the specified path. Choose another location.${RESET}"
        return 1
    fi
    
    OUTPUT_FILE="$path"
    return 0
}

# Interactive menu
show_menu() {
    local choice
    
    while true; do
        echo -e "\n${BLUE}${BOLD}══════════════ MERGEX INTERACTIVE ══════════════${RESET}\n"
        echo -e "${CYAN}[1]${RESET} Select source directory"
        echo -e "${CYAN}[2]${RESET} Select output file"
        echo -e "${CYAN}[3]${RESET} Auto-search (scan all volumes)"
        echo -e "${CYAN}[4]${RESET} Start processing"
        echo -e "${CYAN}[5]${RESET} Show file statistics"
        echo -e "${CYAN}[6]${RESET} Toggle verbose mode (currently: $(if [[ "$VERBOSE" == true ]]; then echo -e "${GREEN}ON${RESET}"; else echo -e "${RED}OFF${RESET}"; fi))"
        echo -e "${CYAN}[7]${RESET} Check dependencies"
        echo -e "${CYAN}[8]${RESET} Show help"
        echo -e "${CYAN}[9]${RESET} Exit"
        echo -e "\n${BLUE}${BOLD}═════════════════════════════════════════════${RESET}\n"
        
        # Show current settings
        if [[ -n "$SOURCE_DIR" ]]; then
            echo -e "${BLUE}Source:${RESET} $SOURCE_DIR"
        else
            echo -e "${BLUE}Source:${RESET} ${YELLOW}Not set${RESET}"
        fi
        
        if [[ -n "$OUTPUT_FILE" ]]; then
            echo -e "${BLUE}Output:${RESET} $OUTPUT_FILE"
        else
            echo -e "${BLUE}Output:${RESET} ${YELLOW}Not set${RESET}"
        fi
        
        echo
        read -p "Enter your choice [1-9]: " choice
        
        case $choice in
            1)
                read -p "Enter source directory path: " SOURCE_DIR
                if [[ ! -d "$SOURCE_DIR" ]]; then
                    echo -e "${RED}[!] Directory not found: $SOURCE_DIR${RESET}"
                    SOURCE_DIR=""
                else
                    find_files "$SOURCE_DIR" 10
                fi
                ;;
            2)
                read -p "Enter output file path: " output_path
                validate_output_path "$output_path"
                ;;
            3)
                auto_search_mode
                # Need to set output file if not already set
                if [[ -z "$OUTPUT_FILE" ]]; then
                    read -p "Enter output file path: " output_path
                    validate_output_path "$output_path"
                fi
                ;;
            4)
                if [[ -z "$OUTPUT_FILE" ]]; then
                    echo -e "${RED}[!] Output file not set. Please select an output file first.${RESET}"
                    continue
                fi
                
                if [[ "$PCAP_COUNT" -eq 0 && "$HASH22000_COUNT" -eq 0 ]]; then
                    echo -e "${RED}[!] No files found to process. Please select a source directory or use auto-search first.${RESET}"
                    continue
                fi
                
                process_files
                show_results
                ;;
            5)
                echo -e "\n${CYAN}[*] File Statistics:${RESET}"
                echo -e "   ${BLUE}→ PCAP/PCAPNG files:${RESET} $PCAP_COUNT"
                echo -e "   ${BLUE}→ .22000 files:${RESET}      $HASH22000_COUNT"
                
                if [[ -n "$OUTPUT_FILE" && -f "$OUTPUT_FILE" ]]; then
                    FINAL_HASH_COUNT=$(wc -l < "$OUTPUT_FILE" 2>/dev/null || echo 0)
                    echo -e "   ${BLUE}→ Processed hashes:${RESET} $FINAL_HASH_COUNT"
                fi
                ;;
            6)
                if [[ "$VERBOSE" == true ]]; then
                    VERBOSE=false
                    echo -e "${YELLOW}[*] Verbose mode turned OFF${RESET}"
                else
                    VERBOSE=true
                    echo -e "${GREEN}[*] Verbose mode turned ON${RESET}"
                fi
                ;;
            7)
                check_dependencies
                ;;
            8)
                show_help
                ;;
            9|q|exit|quit)
                echo -e "${GREEN}[*] Exiting MergeX Interactive. Goodbye!${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Invalid choice. Please select a number between 1-9.${RESET}"
                ;;
        esac
    done
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dir)
                SOURCE_DIR="$2"
                shift 2
                ;;
            -o|--output)
                validate_output_path "$2"
                shift 2
                ;;
            -a|--auto)
                AUTO_MODE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            *)
                echo -e "${RED}[!] Unknown option: $1${RESET}"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    # Check for Apple Silicon and show warning if not
    check_system
    
    # Setup temporary directory
    setup_workdir
    
    # Parse command-line arguments
    parse_args "$@"
    
    # Show the banner
    show_banner
    
    # Check dependencies
    check_dependencies
    
    # If auto mode is set, use it
    if [[ "$AUTO_MODE" == true ]]; then
        auto_search_mode
        
        # If no output file specified, prompt for one
        if [[ -z "$OUTPUT_FILE" ]]; then
            read -p "Enter output file path: " output_path
            validate_output_path "$output_path"
        fi
        
        # Process the files
        if [[ -n "$OUTPUT_FILE" ]]; then
            process_files
            show_results
        else
            echo -e "${RED}[!] No output file specified. Cannot proceed.${RESET}"
            exit 1
        fi
        
        exit 0
    fi
    
    # If source directory is specified, find files
    if [[ -n "$SOURCE_DIR" ]]; then
        if [[ ! -d "$SOURCE_DIR" ]]; then
            echo -e "${RED}[!] Source directory not found: $SOURCE_DIR${RESET}"
            exit 1
        fi
        
        find_files "$SOURCE_DIR" 10
        
        # If output file is also specified, process directly
        if [[ -n "$OUTPUT_FILE" ]]; then
            process_files
            show_results
            exit 0
        fi
    fi
    
    # Otherwise, show interactive menu
    show_menu
}

# Run the main function with all arguments
main "$@"
