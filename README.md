# IPED-Podman: Containerized Digital Forensics Analysis

A Podman/Docker-based setup for running IPED (Integrated Platform for Electronic Evidence Discovery and Analysis) with GPU acceleration for large-scale forensic investigations.

## Features

- 🔍 **Digital forensics processing** with IPED 4.2.2
- 🎙️ **Audio transcription** using faster-whisper with CUDA
- 👤 **Face recognition** with dlib compiled for CUDA acceleration
- 📝 **OCR** in multiple languages
- 🖼️ **Image thumbnail generation and similarity detection**
- 🚀 **GPU acceleration** via NVIDIA CUDA 12.4
- 🛠️ **CLI and headless modes** for automation and batch processing
- 📊 **Results analysis** with interactive GUI

## Prerequisites

### System Requirements
- **CPU**: 8+ cores recommended
- **RAM**: 32GB+ (more for large datasets)
- **GPU**: NVIDIA GPU with CUDA support (optional but highly recommended)
- **Storage**: SSD recommended, especially for temp directory (significant write-heavy workload)
- **OS**: Linux (Fedora, Ubuntu, Debian, Arch, or other distributions with Podman)

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

### 1. Build the Container Image

```bash
./build.sh
```

The build script will:
- Check for NVIDIA GPU availability
- Build the `iped-cuda:4.2.2_7` image with GPU support
- Preload Whisper and dlib models

### 2. Process Evidence

```bash
# Basic usage
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

# Headless mode (no GUI)
./startIped-cli.sh process \
  --evidence /data/phone.E01 \
  --hashes-db /db/hashes \
  --output my_case \
  --nogui

# Custom settings
./startIped-cli.sh process \
  --evidence /data/phone.E01 \
  --hashes-db /db/hashes \
  --output my_case \
  --threads 16 \
  --memory 64G

# Continue interrupted processing
./startIped-cli.sh process \
  --evidence /data/phone.E01 \
  --hashes-db /db/hashes \
  --output my_case \
  --continue
```

### 3. Analyze Results

```bash
# Analyze processed case
./startIped-cli.sh analyze --case-name my_case

# List all available cases
./startIped-cli.sh list
```

### 4. Clean Up

```bash
# Remove containers and temporary files
./startIped-cli.sh clean
```

## CLI Reference

### Process Command

```bash
./startIped-cli.sh process [options]
```

**Required Options:**
- `-e, --evidence PATH` - Path to evidence file/directory (can be specified multiple times)
- `-d, --hashes-db PATH` - Path to hashes database directory
- `-o, --output NAME` - Output case name

**Optional Options:**
- `-c, --config PATH` - Custom IPED config directory (default: `./conf`)
- `-t, --threads NUM` - Number of processing threads (default: half of system threads)
- `-m, --memory SIZE` - Java heap size (default: 2/3 of physical RAM)
- `--continue` - Continue interrupted processing
- `--no-gpu` - Disable GPU acceleration
- `--nogui` - Run in headless mode (no GUI)

### Analyze Command

```bash
./startIped-cli.sh analyze --case-name NAME
```

Opens the IPED analysis GUI for a previously processed case.

### List Command

```bash
./startIped-cli.sh list
```

Lists all completed cases in the `results/` directory.

### Clean Command

```bash
./startIped-cli.sh clean
```

Stops containers and cleans up temporary files.

## Configuration

### Main Configuration Files

1. **`conf/IPEDConfig.txt`** - IPED processing modules
   - Enable/disable analysis features (hash lookup, OCR, face recognition, etc.)
   - Language settings, hash algorithms, etc.

2. **`conf/LocalConfig.txt`** - Environment configuration
   - Thread count, temp directories, database paths
   - Java memory settings

3. **`conf/ParserConfig.xml`** - File parser configuration
   - Which file types to process
   - Custom parser rules

4. **Additional configs** - See `conf/` directory for specialized configs:
   - `OCRConfig.txt` - Optical character recognition settings
   - `FaceRecognitionConfig.txt` - Face detection parameters
   - `AudioTranscriptConfig.txt` - Whisper transcription settings
   - `HashDBLookupConfig.txt` - Hash database configuration
   - etc.

### Customization

#### Memory and Thread Allocation

The script automatically calculates optimal values based on system resources. Override with:

```bash
./startIped-cli.sh process \
  --evidence /data/phone.E01 \
  --hashes-db /db/hashes \
  --output my_case \
  --threads 8 \
  --memory 32G
```

#### Custom Plugins

Place `.jar` files in the `plugins/` directory before processing.

#### Custom Config Directory

Use a separate configuration directory:

```bash
./startIped-cli.sh process \
  --evidence /data/phone.E01 \
  --hashes-db /db/hashes \
  --output my_case \
  --config /path/to/custom/config
```

## Project Structure

```
IPED-Podman/
├── build.sh                                # Build script
├── startIped-cli.sh                        # CLI launcher (process, analyze, list, clean)
├── Dockerfile                              # Container image definition
├── docker-compose.yml                      # Generated at runtime (gitignored)
├── docker/
│   ├── docker-compose.template.yml         # Template for processing
│   ├── docker-compose.analyze.template.yml # Template for analysis
│   └── docker-compose.nogui.template.yml   # Template for headless mode
├── conf/                                   # IPED configuration directory
│   ├── IPEDConfig.txt                      # Main IPED features config
│   ├── LocalConfig.txt                     # Local environment settings
│   ├── OCRConfig.txt                       # OCR settings
│   ├── FaceRecognitionConfig.txt           # Face recognition settings
│   ├── AudioTranscriptConfig.txt           # Audio transcription settings
│   └── [many more configs...]              # Specialized configurations
├── plugins/                                # Custom IPED plugin JAR files
├── results/                                # Case output (indexed results, reports)
├── output/                                 # Intermediate processing output
├── logs/                                   # IPED processing logs
├── temp/                                   # Temporary files (large!)
└── [config files]                          # Root-level config overrides
```

## Troubleshooting

### NVIDIA GPU Not Detected

```bash
# Test if NVIDIA runtime works
podman run --rm --device nvidia.com/gpu=all ubuntu nvidia-smi

# If "failed to stat CDI host device /dev/nvidia-uvm":
sudo nvidia-modprobe -u -c=0
```

### Out of Memory Errors

1. Reduce thread count:
   ```bash
   ./startIped-cli.sh process ... --threads 4
   ```

2. Reduce heap size:
   ```bash
   ./startIped-cli.sh process ... --memory 32G
   ```

3. Process evidence in smaller batches

4. Close other applications

### Slow Processing

- Verify GPU is being used: Enable `--no-gpu` to compare performance
- Put everything (evidence, hashdb, temp, output) on the same NVME SSD drive!

## Output Structure

After processing, results are available in `results/<case_name>/`:

```
results/my_case/
├── iped/                           # IPED indexed database
├── DateiListe.csv                  # File listing
└── reports/                        # Generated reports
```

Analyze results with:
```bash
./startIped-cli.sh analyze --case-name my_case
```

## License

This project is licensed under GPLv3. See [LICENSE](LICENSE) for details.

IPED and related components:
- **IPED**: https://github.com/sepinf-inc/IPED (GPLv3)
- **Base Image**: https://hub.docker.com/r/ipeddocker/iped
- **Whisper**: https://github.com/openai/whisper (MIT)
- **dlib**: http://dlib.net (Boost Software License)

## References

- IPED Documentation: https://github.com/sepinf-inc/IPED/wiki
- IPED GitHub: https://github.com/sepinf-inc/IPED
- NVIDIA Container Toolkit: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/
