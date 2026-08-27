#!/bin/bash
# Build script for Firefox on Ubuntu 26.04 with Ryzen 5 5600H optimizations
# Optimized for cutting-edge performance and telemetry removal

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIREFOX_DIR="$HOME/firefox"

echo "=================================="
echo "Firefox Source Build Script"
echo "For AMD Ryzen 5 5600H (Zen 3)"
echo "=================================="

# Check prerequisites
echo "[1/6] Checking prerequisites..."
command -v git >/dev/null 2>&1 || { echo "ERROR: git not installed"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not installed"; exit 1; }
command -v clang >/dev/null 2>&1 || { echo "WARNING: clang not found, will use system CC"; }

# Create working directory
mkdir -p "$FIREFOX_DIR"
cd "$FIREFOX_DIR"

# Clone/update Firefox source
echo "[2/6] Cloning Firefox source (main branch)..."
if [ ! -d "$FIREFOX_DIR/.git" ]; then
    git clone --depth 1 --branch main https://github.com/mozilla-firefox/firefox.git .
else
    echo "Source already exists, updating..."
    git fetch origin main
    git reset --hard origin/main
fi

# Copy MOZCONFIG
echo "[3/6] Creating optimized MOZCONFIG..."
cp "$SCRIPT_DIR/configs/.mozconfig" "$FIREFOX_DIR/.mozconfig"
echo "MOZCONFIG installed"

# Create build wrapper script
cat > "$FIREFOX_DIR/build-fast.sh" << 'BUILDEOF'
#!/bin/bash
# Fast build wrapper

# Ensure we use the right compiler
export CC=clang
export CXX=clang++

# Build with all cores
./mach build -j$(nproc)
BUILDEOF
chmod +x "$FIREFOX_DIR/build-fast.sh"

# Check dependencies
echo "[4/6] Checking build dependencies..."
MISSING=0

check_pkg() {
    if ! dpkg -l "$1" >/dev/null 2>&1; then
        echo "  MISSING: $1"
        MISSING=1
    fi
}

# Check essential packages
PACKAGES="build-essential python3 git clang libclang-dev libgtk-3-dev \
          libdbus-1-dev libxt-dev libx11-xcb-dev libxcb1-dev libffi-dev \
          libglib2.0-dev nspr-dev libnss3-dev libsqlite3-dev libevent-dev \
          rustc cargo"

for pkg in $PACKAGES; do
    dpkg -l "$pkg" >/dev/null 2>&1 || {
        echo "  Missing: $pkg"
        MISSING=1
    }
done

if [ $MISSING -eq 1 ]; then
    echo ""
    echo "=================================="
    echo "MISSING DEPENDENCIES"
    echo "=================================="
    echo ""
    echo "Please install with:"
    echo "  sudo apt install -y $PACKAGES"
    echo ""
    read -p "Press Enter to continue anyway, or Ctrl+C to abort..."
fi

# Build Firefox
echo "[5/6] Building Firefox (this takes 1-2 hours)..."
echo "Using $(nproc) cores for parallel build"

cd "$FIREFOX_DIR"

# First time bootstrap
if [ ! -d "$FIREFOX_DIR/obj-firefox" ]; then
    echo "Initializing build environment..."
    ./mach bootstrap --no-confirm
fi

# Build
echo "Starting compilation..."
./mach build

echo "[6/6] Build complete!"
echo ""
echo "=================================="
echo "BUILD OUTPUT"
echo "=================================="
echo ""
echo "Binaries location: $FIREFOX_DIR/obj-firefox/dist/firefox/"
echo ""
echo "To run:"
echo "  $FIREFOX_DIR/obj-firefox/dist/firefox/firefox"
echo ""
echo "To install system-wide:"
echo "  sudo cp -r obj-firefox/dist/firefox /opt/firefox-ryzen"
echo "  sudo ln -sf /opt/firefox-ryzen/firefox /usr/local/bin/firefox"
echo ""
echo "Firefox Sync: preserved - connect via about:preferences#sync"