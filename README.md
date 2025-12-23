# IPED-Podman: Containerized Digital Forensics Analysis

A Podman-based setup for running IPED (Digital Evidence Processor and Indexer) with GPU acceleration for forensic investigations.

## Features

- 🔍 **Digital forensics processing** with IPED 4.2.2
- 🎙️ **Audio transcription** using faster-whisper with CUDA
- 👤 **Face recognition** with dlib + CUDA
- 🖼️ **Image similarity detection**
- 📝 **OCR** in multiple languages
- 🚀 **GPU acceleration** via NVIDIA CUDA 12.4

## Prerequisites

### Required Software
- Podman and podman-compose
- NVIDIA GPU with CUDA support
- Insane VRAM
- Insane RAM
- SSD storage recommended for temp files

### Optional
- X11 display server for analysis GUI

### Installation
```bash
# Fedora/RHEL
sudo dnf install podman podman-compose yad

# Ubuntu/Debian
sudo apt install podman podman-compose yad

# Install NVIDIA Container Toolkit for Podman
# Follow: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/

# Arch (https://archlinux.org/packages/extra/x86_64/nvidia-container-toolkit/)
yay -S nvidia-container-toolkit
```

## Quick Start

### 1. Build the Image
```bash
./build.sh
```

### 2.
```bash
# Process evidence
./startIped-cli.sh process \
  --evidence /path/to/evidence.E01 \
  --hashes-db /path/to/hashdb

# Analyze results
./startIped-cli.sh analyze --case-name CaseName
```

## Configuration

### Main Configuration Files

1. **`config.txt`** - Quick settings (used by GUI)
   - Default locale, thread count, examiner name, etc.

2. **`IPEDConfig.txt`** - IPED processing features
   - Enable/disable specific analysis modules
   - Hash algorithms, OCR settings, etc.

3. **`LocalConfig.txt`** - Local environment
   - Temp directories, thread counts, database paths

### Customization

#### Change Memory Allocation
Edit `docker-compose.template.yml`:
```yaml
command: >
  java -jar iped.jar -Xms32G -Xmx64G --portable
```

#### Change Thread Count
Edit `LocalConfig.txt`:
```
numThreads = 8
```

#### Add Custom IPED Plugins
Place `.jar` files in `./plugins/` directory.

## Project Structure

```
IPED-Podman/
├── Dockerfile                              # Container image definition
├── docker-compose.template.yml             # Template for processing
├── docker-compose.analyze.template.yml     # Template for analysis
├── docker-compose.yml                      # Generated (gitignored)
├── startIped.sh                            # GUI launcher
├── startIped-cli.sh                        # CLI launcher (NEW)
├── build.sh                                # Build script (NEW)
├── config.txt                              # Quick config
├── IPEDConfig.txt                          # IPED features config
├── LocalConfig.txt                         # Environment config
├── results/                                # Processing output
├── ipedtmp/                                # Temporary files
├── logs/                                   # IPED logs
└── plugins/                                # Custom plugins
```

## Troubleshooting

### GUI doesn't appear
```bash
xhost +local:
export DISPLAY=:0
```

### Out of memory errors
- Reduce thread count in `LocalConfig.txt`
- Reduce Java heap size in `docker-compose.template.yml`
- Close other applications

### CUDA not working
```bash
# Test NVIDIA runtime
podman run --rm --device nvidia.com/gpu=all ubuntu nvidia-smi
```

### "failed to stat CDI host device /dev/nvidia-uvm" Error

This happens when NVIDIA kernel modules aren't loaded. The script will try to fix this automatically, but if it fails:

**Quick Fix:**
```bash
sudo nvidia-modprobe -u -c=0
```

**Permanent Fix (Recommended):**

1. Enable NVIDIA persistence daemon:
```bash
sudo systemctl enable nvidia-persistenced
sudo systemctl start nvidia-persistenced
```

2. Or run the helper script:
```bash
./fix-nvidia-modules.sh
```

3. Or add to `/etc/rc.local`:
```bash
#!/bin/bash
nvidia-modprobe -u -c=0
exit 0
```

**Why does this happen?**
- Rootless Podman needs the NVIDIA device nodes (`/dev/nvidia-uvm`, etc.)
- These aren't always created at boot, especially on systems that boot without X11
- The `nvidia-modprobe` command creates these device nodes
- The `-u` flag makes them accessible to non-root users (needed for rootless Podman)

### Permission denied errors
```bash
# Fix SELinux contexts
sudo chcon -Rt svirt_sandbox_file_t ./results ./ipedtmp ./logs
```

## Security Notes

⚠️ **X11 Security**: The startup script uses `xhost +` which is insecure. For production:
```bash
xhost +local:$(id -un)  # Only allow local user
```

⚠️ **Privileged Mode**: Container runs in privileged mode for hardware access. Review security implications.

## Performance Tips

1. **Use SSD** for `ipedtmp` directory
2. **Separate disks** for evidence (read) and results (write)
3. **GPU processing** significantly speeds up face recognition and transcription
4. **Hash database on SSD** improves lookup performance

## License

This setup is provided as-is. IPED itself is open source under GPLv3.
See: https://github.com/sepinf-inc/IPED

## Credits

- IPED: https://github.com/sepinf-inc/IPED
- Base Docker image: ipeddocker/iped
- Whisper: OpenAI
- dlib: Davis King

## Support

For IPED-specific questions, see the official documentation:
- https://github.com/sepinf-inc/IPED/wiki
