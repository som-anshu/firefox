# Firefox Source Build - Ryzen 5 5600H Optimized

Custom Firefox build configuration for Ubuntu 26.04 with AMD Ryzen 5000/5600H optimizations.

## System Requirements
- **OS**: Ubuntu 26.04 LTS (or compatible Debian-based distro)
- **CPU**: AMD Ryzen 5 5600H (Zen 3) - optimized for znver3 architecture
- **Required**: ~20GB free disk space, 8GB+ RAM

## Features

### Performance Optimizations
- `-march=znver3` - CPU-specific optimizations
- `-O3` - Maximum optimization level
- `-ffast-math` - Fast math operations
- LTO (Link-Time Optimization) - Thin LTO for faster builds
- AVX/AVX2 support enabled
- Native CPU instruction sets enabled

### Telemetry Removal
- All telemetry disabled
- No crash reports
- No automatic updates
- No distribution data
- **Firefox Sync preserved** - Connect via `about:preferences#sync`

### Removed Components
- Debug/testing tools
- Unused backends (PulseAudio, GStreamer, GLX)
- Developer options
- Extension policies

## Build Instructions

### 1. Install Dependencies
```bash
# Install build tools
sudo apt update
sudo apt install -y build-essential python3 python3-pip git clang libclang-dev

# Install Firefox dependencies
sudo apt install -y \
  libgtk-3-dev libdbus-1-dev libxt-dev libx11-xcb-dev \
  libxcb1-dev libxcb-randr0-dev libxcb-shape0-dev \
  libffi-dev libglib2.0-dev nspr-dev libnss3-dev \
  libsqlite3-dev libevent-dev rustc cargo

# Optional: Install more dependencies if build fails
sudo apt install -y libgl1-mesa-dev libglu1-mesa-dev libcairo2-dev \
  libpango1.0-dev libpulse-dev libasound2-dev libjpeg-dev \
  libpng-dev libwebp-dev libhyperscan-dev
```

### 2. Clone This Repository
```bash
git clone https://github.com/som-anshu/firefox.git
cd firefox
```

### 3. Clone Firefox Source
```bash
# Clone Firefox source (main branch for cutting edge)
git clone --depth 1 --branch main https://github.com/mozilla-firefox/firefox.git firefox-src
```

### 4. Copy MOZCONFIG
```bash
cp configs/.mozconfig firefox-src/
```

### 5. Build Firefox
```bash
cd firefox-src

# Bootstrap (first time only)
./mach bootstrap --no-confirm

# Build with all CPU cores
./mach build -j$(nproc)

# Package
./mach package
```

### 6. Create .deb Package
```bash
# Run the deb creation script
./create-deb.sh
```

The script will create `firefox-ryzen_*.deb` package.

### 7. Install
```bash
sudo dpkg -i firefox-ryzen_*.deb
```

Or:
```bash
sudo apt install ./firefox-ryzen_*.deb
```

## MOZCONFIG Reference

| Flag | Purpose |
|------|---------|
| `--enable-optimize=-O3` | Maximum optimization |
| `-march=znver3` | Zen 3 CPU optimizations |
| `--disable-telemetry` | Remove telemetry |
| `--disable-updater` | No auto-updates |
| `--enable-lto=thin` | Link-time optimization |
| `--enable-avx2` | Advanced-vector extensions |

## Firefox Sync Setup

After installation, enable Firefox Sync:
1. Open Firefox
2. Go to `about:preferences#sync`
3. Sign in with Firefox Account
4. Enable Sync for bookmarks, passwords, history, etc.

**Sync is preserved** - only telemetry is removed.

## Reconfiguring for Different Hardware

To change CPU optimizations, edit `configs/.mozconfig`:

```bash
# For Intel 10th+ gen:
export CFLAGS="-march=x86-64-v4 -O3 ..."
ac_add_options --enable-optimize="-march=x86-64-v4 -O3"

# For AMD Zen 2 (Ryzen 3000/5000 non-X):
export CFLAGS="-march=znver2 -O3 ..."

# For newer Zen 4 (Ryzen 7000):
export CFLAGS="-march=znver4 -O3 ..."
```

## CI/CD

This repo includes GitHub Actions workflow in `.github/workflows/build.yml`
for automated builds on Ubuntu 26.04.

## Troubleshooting

### Build fails with missing dependencies
```bash
# Check what's missing
./mach build 2>&1 | grep "error:"

# Install common missing packages
sudo apt install -y libhyperscan-dev libquantum-dev libomp-dev
```

### Clang errors
```bash
# Try gcc instead
export CC=gcc
export CXX=g++
```

### Disk space issues
```bash
# Clean old builds
./mach clobber
rm -rf obj-firefox
```

## License

Files:
- `configs/.mozconfig`: Custom build config
- `README.md`: Documentation

Source:
- Firefox source: MPL-2.0 (Mozilla Public License)
- Build scripts: MIT