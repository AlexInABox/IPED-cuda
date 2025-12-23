#!/usr/bin/env bash
# Build script for IPED container image

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

IMAGE_NAME="iped-whisper-cuda"
IMAGE_TAG="4.2.2_7"

echo -e "${GREEN}=== Building IPED Container Image ===${NC}"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""

# Check if NVIDIA runtime is available
if ! podman run --rm --device nvidia.com/gpu=all ubuntu nvidia-smi &>/dev/null; then
    echo -e "${YELLOW}Warning: NVIDIA GPU not detected or runtime not configured${NC}"
    echo "GPU acceleration will not be available."
    echo "Continue anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Build the image
echo -e "${GREEN}Starting build...${NC}"
podman build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo ""
echo -e "${GREEN}=== Build Complete ===${NC}"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "Next steps:"
echo "  1. Run './startIped.sh' for GUI launcher"
echo "  2. Run './startIped-cli.sh --help' for CLI usage"
