#!/usr/bin/env bash
# CLI version of IPED launcher - no GUI dependencies required

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color


# Function to display usage
usage() {
    cat <<EOF
Usage: $0 <command> [options]

Commands:
    process     Process evidence files
    analyze     Open analysis GUI for processed case
    list        List available processed cases
    clean       Clean up temporary files and containers

Process Options:
    -e, --evidence PATH         Path to evidence file/directory (can be used multiple times)
    -d, --hashes-db PATH       Path to directory containing hashes database (required - pass the folder, not the database file)
    -c, --config PATH          Path to custom IPED config directory (default: ./conf)
    -o, --output NAME          Output case name (required)
    -t, --threads NUM          Number of processing threads (default: 1/2 of system threads)
    -m, --memory SIZE          Java heap size (default: 2/3 of physical RAM)
    --continue                 Continue interrupted processing
    --no-gpu                   Disable GPU acceleration
    --nogui                    Run IPED without GUI (headless mode)
    -h, --help                 Show this help message

Analyze Options:
    -n, --case-name NAME       Case name to analyze (required)
    -h, --help                 Show this help message

Examples:
    # Process single evidence file
    $0 process -e /data/phone.E01 -d /media/hobby/8TB\ SSD/IPED/hashesdb -c /path/to/config -o my_case

    # Process multiple evidence files together
    $0 process -e /data/phone.E01 -e /data/disk.dd -d /media/hobby/8TB\ SSD/IPED/hashesdb -c /path/to/config -o my_case

    # Process with custom settings
    $0 process -e /data/phone.E01 -d /media/hobby/8TB\ SSD/IPED/hashesdb -c /path/to/config -o my_case -t 8 -m 64G

    # Process without GUI (headless mode)
    $0 process -e /data/phone.E01 -e /data/disk.dd -d /media/hobby/8TB\ SSD/IPED/hashesdb -c /path/to/config -o my_case --nogui

    # Continue interrupted processing
    $0 process -e /data/phone.E01 -d /media/hobby/8TB\ SSD/IPED/hashesdb -c /path/to/config -o my_case --continue

    # Analyze processed case
    $0 analyze --case-name my_case

    # List all cases
    $0 list

EOF
    exit 1
}

# Function to validate required arguments
validate_required() {
    local var_name=$1
    local var_value=$2
    local friendly_name=$3
    
    if [[ -z "$var_value" ]]; then
        echo -e "${RED}Error: $friendly_name is required${NC}" >&2
        usage
    fi
}

# Function to validate path exists
validate_path() {
    local path=$1
    local name=$2
    
    if [[ ! -e "$path" ]]; then
        echo -e "${RED}Error: $name not found: $path${NC}" >&2
        exit 1
    fi
}

# Function to validate path is a directory
validate_directory() {
    local path=$1
    local name=$2
    
    if [[ ! -d "$path" ]]; then
        echo -e "${RED}Error: $name must be a directory: $path${NC}" >&2
        exit 1
    fi
}

# Command: Process evidence
cmd_process() {
    local evidence_paths=()
    local hashes_dir=""
    local config_dir="./conf"
    local output_name=""
    
    # Calculate defaults based on system resources
    local total_mem=$(free -g | grep "^Mem:" | awk '{print int($2 * 2 / 3)}')
    local memory="${total_mem}G"
    local cpu_count=$(nproc)
    local threads=$((cpu_count / 2))
    if [[ $threads -lt 1 ]]; then
        threads=1
    fi
    
    local continue_flag="false"
    local use_gpu="true"
    local nogui_flag="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--evidence)
                evidence_paths+=("$2")
                shift 2
                ;;
            -o|--output)
                output_name="$2"
                shift 2
                ;;
            -d|--hashes-db)
                hashes_dir="$2"
                shift 2
                ;;
            -c|--config)
                config_dir="$2"
                shift 2
                ;;
            -t|--threads)
                threads="$2"
                shift 2
                ;;
            -m|--memory)
                memory="$2"
                shift 2
                ;;
            --continue)
                continue_flag="true"
                shift
                ;;
            --no-gpu)
                use_gpu="false"
                shift
                ;;
            --nogui)
                nogui_flag="true"
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}" >&2
                usage
                ;;
        esac
    done
    
    # Validate required arguments
    if [[ ${#evidence_paths[@]} -eq 0 ]]; then
        echo -e "${RED}Error: At least one evidence path is required (-e/--evidence)${NC}" >&2
        usage
    fi
    
    validate_required "hashes_dir" "$hashes_dir" "Hashes database directory (-d/--hashes-db)"
    validate_required "output_name" "$output_name" "Output case name (-o/--output)"
    
    # Validate all evidence paths exist
    for evidence_path in "${evidence_paths[@]}"; do
        validate_path "$evidence_path" "Evidence"
    done
    
    validate_directory "$hashes_dir" "Hashes database directory"
    validate_path "$config_dir" "Config directory"
    
    # Display configuration
    echo -e "${GREEN}=== IPED Processing Configuration ===${NC}"
    echo "Evidence files:"
    for evidence_path in "${evidence_paths[@]}"; do
        echo "  - $evidence_path"
    done
    echo "Output: ./results/$output_name"
    echo "Threads: $threads"
    echo "Memory: $memory"
    echo "Continue: $continue_flag"
    echo "GPU: $use_gpu"
    echo "No GUI: $nogui_flag"
    echo ""
    
    # Ensure NVIDIA modules are loaded (prevents CDI device errors)
    if [[ "$use_gpu" == "true" ]]; then
        echo -e "${YELLOW}Checking NVIDIA GPU setup...${NC}"
        if ! nvidia-smi &>/dev/null; then
            echo -e "${RED}Warning: nvidia-smi not working. GPU may not be available.${NC}"
        elif [[ ! -e "/dev/nvidia-uvm" ]]; then
            echo -e "${YELLOW}NVIDIA UVM device not found. Loading NVIDIA modules...${NC}"
            if sudo nvidia-modprobe -u -c=0; then
                echo -e "${GREEN}NVIDIA modules loaded successfully${NC}"
            else
                echo -e "${RED}Failed to load NVIDIA modules. You may need to run: sudo nvidia-modprobe -u -c=0${NC}"
                echo -e "${YELLOW}Continue without GPU? (y/N)${NC}"
                read -r response
                if [[ "$response" =~ ^[Yy]$ ]]; then
                    use_gpu="false"
                    echo -e "${YELLOW}Disabling GPU acceleration${NC}"
                else
                    exit 1
                fi
            fi
        else
            echo -e "${GREEN}NVIDIA GPU ready${NC}"
        fi
    fi
    
    # Generate docker-compose.yml from template
    if [[ "$nogui_flag" == "true" ]]; then
        TEMPLATE="docker/docker-compose.nogui.template.yml"
    else
        TEMPLATE="docker/docker-compose.template.yml"
    fi
    
    # Build evidence paths flags for IPED command
    local evidence_flags=""
    local volume_mounts=""
    declare -A dir_to_mount_index
    local mount_counter=0
    
    for evidence_path in "${evidence_paths[@]}"; do
        # Get the directory containing the evidence
        local evidence_dir=$(dirname "$(realpath "$evidence_path")")
        local evidence_name=$(basename "$evidence_path")
        
        # Check if we've already mapped this directory
        if [[ -z "${dir_to_mount_index[$evidence_dir]}" ]]; then
            dir_to_mount_index[$evidence_dir]=$mount_counter
            mount_counter=$((mount_counter + 1))
        fi
        
        local mount_idx=${dir_to_mount_index[$evidence_dir]}
        local mount_path="/evidences_$mount_idx"
        
        # Add -d flag for this evidence with unique mount path
        evidence_flags="$evidence_flags\\n      -d \"$mount_path/$evidence_name\""
    done
    
    # Build volume mounts for unique evidence directories with unique mount paths
    local dir_index=0
    for dir in "${!dir_to_mount_index[@]}"; do
        local mount_idx=${dir_to_mount_index[$dir]}
        local mount_path="/evidences_$mount_idx"
        volume_mounts="$volume_mounts\\n      - \"$dir:$mount_path:ro\""
    done
    
    # Remove leading newline from evidence_flags
    evidence_flags="${evidence_flags:2}"
    
    # Build volume mounts for unique evidence directories
    for dir in "${unique_dirs[@]}"; do
        volume_mounts="$volume_mounts\\n      - \\\"$dir:/evidences:ro\\\""
    done
    
    sed \
        -e "s|__EVIDENCE_PATHS__|$evidence_flags|g" \
        -e "s|__EVIDENCE_PATHS_VOLUMES__|$volume_mounts|g" \
        -e "s|__EVIDENCE_NAME_NOEXT__|$output_name|g" \
        -e "s|__HASHES_PATH__|$hashes_dir|g" \
        -e "s|__CONF_PATH__|$config_dir|g" \
        "$TEMPLATE" > docker-compose.yml
    
    # Update memory settings
    sed -i "s|-Xms[0-9]*G -Xmx[0-9]*G|-Xms$((${memory%G} - 5))G -Xmx$memory|g" docker-compose.yml
    
    # Add --continue flag if requested
    if [[ "$continue_flag" == "true" ]]; then
        sed -i 's|java -jar iped.jar|java -jar iped.jar --continue|g' docker-compose.yml
        SKIP_DELETE=true
    fi
    
    # Add --nogui flag if requested (only for GUI template, nogui template already has it)
    if [[ "$nogui_flag" == "true" && "$TEMPLATE" != *"nogui"* ]]; then
        sed -i 's|java -jar iped.jar|java -jar iped.jar --nogui|g' docker-compose.yml
    fi
    
    # Disable GPU if requested (checked after nvidia-modprobe attempt)
    if [[ "$use_gpu" == "false" ]]; then
        sed -i '/nvidia.com\/gpu/d' docker-compose.yml
    fi
    
    # Cleanup
    echo -e "${YELLOW}Cleaning up previous containers...${NC}"
    podman-compose down 2>/dev/null || true
    podman container prune -f
    
    # Delete old results unless continuing
    if [[ "$continue_flag" != "true" && -d "./results/$output_name" ]]; then
        echo ""
        echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
        echo -e "${RED}          WARNING: EXISTING RESULTS FOUND!${NC}"
        echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}Case directory: ./results/$output_name${NC}"
        
        # Show size and basic info
        result_size=$(du -sh "./results/$output_name" 2>/dev/null | cut -f1)
        result_date=$(stat -c %y "./results/$output_name" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
        echo -e "${YELLOW}Size: $result_size${NC}"
        echo -e "${YELLOW}Last modified: $result_date${NC}"
        echo ""
        
        # List top-level contents
        echo -e "${YELLOW}Contents that will be DELETED:${NC}"
        ls -lh "./results/$output_name" 2>/dev/null | tail -n +2 | head -20 || true
        
        # Count total files
        file_count=$(find "./results/$output_name" -type f 2>/dev/null | wc -l)
        echo ""
        echo -e "${YELLOW}Total files: $file_count${NC}"
        echo ""
        echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
        echo -e "${RED}This operation CANNOT be undone!${NC}"
        echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}Do you want to DELETE these results? (yes/no)${NC}"
        read -r response
        
        if [[ "$response" == "yes" ]]; then
            echo -e "${YELLOW}Deleting ./results/$output_name ...${NC}"
            rm -rf "./results/$output_name"
            echo -e "${GREEN}Results deleted.${NC}"
        else
            echo -e "${RED}Aborted. Use --continue to resume existing processing, or rename the old results folder.${NC}"
            exit 1
        fi
    fi
    
    # Set up X11 for GUI (if available)
    if [[ -n "${DISPLAY:-}" ]]; then
        xhost +local:$(id -un) 2>/dev/null || true
    fi
    
    # Store evidence metadata for analysis
    mkdir -p "./results/$output_name"
    cat > "./results/$output_name/.iped-evidence-info" <<EOF
EVIDENCE_PATHS=($(printf '"%s" ' "${evidence_paths[@]}"))
PROCESSING_DATE="$(date -Iseconds)"
EOF
    
    # Countdown before starting
    echo ""
    echo -e "${GREEN}Starting IPED processing in...${NC}"
    for i in 5 4 3 2 1; do
        echo -ne "\r${GREEN}  $i...${NC}  "
        sleep 1
    done
    echo -e "\r${GREEN}  Starting now!${NC}"
    echo ""
    
    podman-compose up
}

# Command: Analyze results
cmd_analyze() {
    local case_name=""
    local evidence_path=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--case-name)
                case_name="$2"
                shift 2
                ;;
            -e|--evidence)
                evidence_path="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}" >&2
                usage
                ;;
        esac
    done
    
    # Validate required arguments
    validate_required "case_name" "$case_name" "Case name"
    
    if [[ ! -d "./results/$case_name" ]]; then
        echo -e "${RED}Error: Case not found: ./results/$case_name${NC}" >&2
        echo -e "${YELLOW}Available cases:${NC}"
        ls -1 ./results/ 2>/dev/null || echo "  (none)"
        exit 1
    fi
    
    echo -e "${GREEN}Opening analysis GUI for case: $case_name${NC}"
    echo ""
    
    # Generate analyze compose file
    TEMPLATE="docker/docker-compose.analyze.template.yml"
    
    sed \
        -e "s|__EVIDENCE_NAME_NOEXT__|$case_name|g" \
        "$TEMPLATE" > docker-compose.yml
    
    # Cleanup
    podman-compose down 2>/dev/null || true
    
    # Set up X11
    if [[ -n "${DISPLAY:-}" ]]; then
        xhost +local:$(id -un) 2>/dev/null || true
    else
        echo -e "${RED}Error: DISPLAY not set. Cannot start GUI.${NC}" >&2
        exit 1
    fi
    
    # Start analysis GUI
    podman-compose up
}

# Command: List cases
cmd_list() {
    echo -e "${GREEN}=== Processed Cases ===${NC}"
    if [[ -d "./results" ]]; then
        for case_dir in ./results/*/; do
            if [[ -d "$case_dir" ]]; then
                case_name=$(basename "$case_dir")
                size=$(du -sh "$case_dir" 2>/dev/null | cut -f1)
                modified=$(stat -c %y "$case_dir" 2>/dev/null | cut -d' ' -f1)
                echo "  $case_name (Size: $size, Modified: $modified)"
            fi
        done
    else
        echo "  (no cases found)"
    fi
}

# Command: Clean
cmd_clean() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    
    # Stop containers
    podman-compose down 2>/dev/null || true
    
    # Prune containers
    podman container prune -f
    
    # Clean temp files
    if [[ -d "./ipedtmp" ]]; then
        echo "Cleaning temp directory..."
        rm -rf ./ipedtmp/*
    fi
    
    # Remove generated docker-compose.yml
    if [[ -f "./docker-compose.yml" ]]; then
        rm -f ./docker-compose.yml
    fi
    
    echo -e "${GREEN}Cleanup complete${NC}"
}

# Main command dispatcher
COMMAND="${1:-}"
shift || true

case "$COMMAND" in
    process)
        cmd_process "$@"
        ;;
    analyze)
        cmd_analyze "$@"
        ;;
    list)
        cmd_list "$@"
        ;;
    clean)
        cmd_clean "$@"
        ;;
    -h|--help|help|"")
        usage
        ;;
    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}" >&2
        usage
        ;;
esac
