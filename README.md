# IPED-cuda: Containerized IPED with GPU Support
[![DeepWiki][deepwiki-badge]](https://deepwiki.com/AlexInABox/IPED-cuda)
[![DeepWiki][deepwiki-badge-iped]](https://deepwiki.com/sepinf-inc/IPED)

Podman/Docker setup for running IPED with GPU acceleration. Includes audio transcription (Whisper), face recognition (dlib), OCR, and image processing—all optimized for NVIDIA CUDA.

**Versions**: IPED 4.2.2, CUDA 12.4

## Prerequisites

### System Requirements
- **CPU**: 8+ cores recommended
- **RAM**: 32GB+
- **GPU**: NVIDIA GPU with CUDA support (recommended)
- **Storage**: SSD (temp directory is write-heavy)
- **OS**: Linux with Podman

### Required Software
```bash
# Fedora/RHEL
sudo dnf install podman podman-compose

# Ubuntu/Debian
sudo apt install podman podman-compose

# Arch
sudo pacman -S podman podman-compose

# Install NVIDIA Container Toolkit for GPU support
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/
```

## Quick Start

### 1. Build

```bash
./build.sh
```

### 2. Process Evidence

```bash
./startIped-cli.sh process \
  --evidence /path/to/evidence.E01 \
  --hashes-db /path/to/hashdb \
  --output my_case

# Multiple evidence files
./startIped-cli.sh process \
  --evidence /data/phone.E01 \
  --evidence /data/disk.dd \
  --hashes-db /db/hashes \
  --output my_case
```

### 3. Analyze Results

```bash
./startIped-cli.sh analyze --case-name my_case
```

## Command Reference

### Process

```bash
./startIped-cli.sh process [options]
```

**Required:**
- `-e, --evidence PATH` - Evidence file/directory (repeatable)
- `-d, --hashes-db PATH` - Hash database directory
- `-o, --output NAME` - Case output name

**Optional:**
- `-t, --threads NUM` - Processing threads (default: half available cores)
- `-m, --memory SIZE` - Java heap size (default: 2/3 physical RAM)
- `-c, --config PATH` - Custom config directory
- `--continue` - Resume interrupted case
- `--no-gpu` - Disable GPU acceleration
- `--nogui` - Headless mode

### Analyze

```bash
./startIped-cli.sh analyze --case-name NAME
```

### List

```bash
./startIped-cli.sh list
```

### Clean

```bash
./startIped-cli.sh clean
```

## Configuration

Edit files in `conf/`:
- **`IPEDConfig.txt`** - Enable/disable analysis features (hash lookup, OCR, face recognition, etc.)
- **`LocalConfig.txt`** - Thread count, temp directories, Java memory
- **`ParserConfig.xml`** - File type handling
- **Other configs** - Language/feature-specific settings (see `conf/` directory)

Override with custom settings:

```bash
./startIped-cli.sh process \
  --evidence /data/phone.E01 \
  --hashes-db /db/hashes \
  --output my_case \
  --threads 8 \
  --memory 32G \
  --config /custom/conf
```

Place custom plugins (`.jar` files) in `plugins/`.

## Project Structure

```
IPED-cuda/
├── build.sh                                # Build image
├── startIped-cli.sh                        # CLI entry point
├── Dockerfile                              # Container definition
├── docker/
│   ├── docker-compose.template.yml         # Processing template
│   ├── docker-compose.analyze.template.yml # Analysis template
│   └── docker-compose.nogui.template.yml   # Headless template
├── conf/                                   # Configuration files
├── plugins/                                # Custom plugin JARs
├── results/                                # Output (case results)
├── logs/                                   # Processing logs
└── temp/                                   # Temporary files
```

## Troubleshooting

### GPU Not Detected

```bash
podman run --rm --device nvidia.com/gpu=all ubuntu nvidia-smi

# If CDI error:
sudo nvidia-modprobe -u -c=0
```

### Out of Memory

- Reduce threads: `--threads 4`
- Reduce heap: `--memory 32G`
- Process in smaller batches
- Close other applications

### Slow Processing

- Check GPU usage: compare with `--no-gpu` flag
- **Important**: Put evidence, hashdb, temp, and output on the same SSD

## License

Licensed under GPLv3. See [LICENSE](LICENSE).

**Related projects:**
- [IPED](https://github.com/sepinf-inc/IPED) (GPLv3+)
- [IPED Docker](https://github.com/iped-docker/iped)
- [Whisper](https://github.com/openai/whisper) (MIT)
- [dlib](http://dlib.net) (Boost License 1.0)

**Docs:**
- [IPED Wiki](https://github.com/sepinf-inc/IPED/wiki)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/)

<!-- Badge references -->
[deepwiki-badge]: https://img.shields.io/badge/DeepWiki-AlexInABox%2FIPED--cuda-blue.svg?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAyCAYAAAAnWDnqAAAAAXNSR0IArs4c6QAAA05JREFUaEPtmUtyEzEQhtWTQyQLHNak2AB7ZnyXZMEjXMGeK/AIi+QuHrMnbChYY7MIh8g01fJoopFb0uhhEqqcbWTp06/uv1saEDv4O3n3dV60RfP947Mm9/SQc0ICFQgzfc4CYZoTPAswgSJCCUJUnAAoRHOAUOcATwbmVLWdGoH//PB8mnKqScAhsD0kYP3j/Yt5LPQe2KvcXmGvRHcDnpxfL2zOYJ1mFwrryWTz0advv1Ut4CJgf5uhDuDj5eUcAUoahrdY/56ebRWeraTjMt/00Sh3UDtjgHtQNHwcRGOC98BJEAEymycmYcWwOprTgcB6VZ5JK5TAJ+fXGLBm3FDAmn6oPPjR4rKCAoJCal2eAiQp2x0vxTPB3ALO2CRkwmDy5WohzBDwSEFKRwPbknEggCPB/imwrycgxX2NzoMCHhPkDwqYMr9tRcP5qNrMZHkVnOjRMWwLCcr8ohBVb1OMjxLwGCvjTikrsBOiA6fNyCrm8V1rP93iVPpwaE+gO0SsWmPiXB+jikdf6SizrT5qKasx5j8ABbHpFTx+vFXp9EnYQmLx02h1QTTrl6eDqxLnGjporxl3NL3agEvXdT0WmEost648sQOYAeJS9Q7bfUVoMGnjo4AZdUMQku50McDcMWcBPvr0SzbTAFDfvJqwLzgxwATnCgnp4wDl6Aa+Ax283gghmj+vj7feE2KBBRMW3FzOpLOADl0Isb5587h/U4gGvkt5v60Z1VLG8BhYjbzRwyQZemwAd6cCR5/XFWLYZRIMpX39AR0tjaGGiGzLVyhse5C9RKC6ai42ppWPKiBagOvaYk8lO7DajerabOZP46Lby5wKjw1HCRx7p9sVMOWGzb/vA1hwiWc6jm3MvQDTogQkiqIhJV0nBQBTU+3okKCFDy9WwferkHjtxib7t3xIUQtHxnIwtx4mpg26/HfwVNVDb4oI9RHmx5WGelRVlrtiw43zboCLaxv46AZeB3IlTkwouebTr1y2NjSpHz68WNFjHvupy3q8TFn3Hos2IAk4Ju5dCo8B3wP7VPr/FGaKiG+T+v+TQqIrOqMTL1VdWV1DdmcbO8KXBz6esmYWYKPwDL5b5FA1a0hwapHiom0r/cKaoqr+27/XcrS5UwSMbQAAAABJRU5ErkJggg==

[deepwiki-badge-iped]: https://img.shields.io/badge/DeepWiki-sepinf--inc%2FIPED-blue.svg?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAyCAYAAAAnWDnqAAAAAXNSR0IArs4c6QAAA05JREFUaEPtmUtyEzEQhtWTQyQLHNak2AB7ZnyXZMEjXMGeK/AIi+QuHrMnbChYY7MIh8g01fJoopFb0uhhEqqcbWTp06/uv1saEDv4O3n3dV60RfP947Mm9/SQc0ICFQgzfc4CYZoTPAswgSJCCUJUnAAoRHOAUOcATwbmVLWdGoH//PB8mnKqScAhsD0kYP3j/Yt5LPQe2KvcXmGvRHcDnpxfL2zOYJ1mFwrryWTz0advv1Ut4CJgf5uhDuDj5eUcAUoahrdY/56ebRWeraTjMt/00Sh3UDtjgHtQNHwcRGOC98BJEAEymycmYcWwOprTgcB6VZ5JK5TAJ+fXGLBm3FDAmn6oPPjR4rKCAoJCal2eAiQp2x0vxTPB3ALO2CRkwmDy5WohzBDwSEFKRwPbknEggCPB/imwrycgxX2NzoMCHhPkDwqYMr9tRcP5qNrMZHkVnOjRMWwLCcr8ohBVb1OMjxLwGCvjTikrsBOiA6fNyCrm8V1rP93iVPpwaE+gO0SsWmPiXB+jikdf6SizrT5qKasx5j8ABbHpFTx+vFXp9EnYQmLx02h1QTTrl6eDqxLnGjporxl3NL3agEvXdT0WmEost648sQOYAeJS9Q7bfUVoMGnjo4AZdUMQku50McDcMWcBPvr0SzbTAFDfvJqwLzgxwATnCgnp4wDl6Aa+Ax283gghmj+vj7feE2KBBRMW3FzOpLOADl0Isb5587h/U4gGvkt5v60Z1VLG8BhYjbzRwyQZemwAd6cCR5/XFWLYZRIMpX39AR0tjaGGiGzLVyhse5C9RKC6ai42ppWPKiBagOvaYk8lO7DajerabOZP46Lby5wKjw1HCRx7p9sVMOWGzb/vA1hwiWc6jm3MvQDTogQkiqIhJV0nBQBTU+3okKCFDy9WwferkHjtxib7t3xIUQtHxnIwtx4mpg26/HfwVNVDb4oI9RHmx5WGelRVlrtiw43zboCLaxv46AZeB3IlTkwouebTr1y2NjSpHz68WNFjHvupy3q8TFn3Hos2IAk4Ju5dCo8B3wP7VPr/FGaKiG+T+v+TQqIrOqMTL1VdWV1DdmcbO8KXBz6esmYWYKPwDL5b5FA1a0hwapHiom0r/cKaoqr+27/XcrS5UwSMbQAAAABJRU5ErkJggg==