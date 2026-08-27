#!/bin/bash
# Create DEBIAN package from Firefox build

VERSION="1.0-$(date +%Y%m%d)"
PACKAGE_NAME="firefox-ryzen_${VERSION}_amd64"

# Create directory structure
mkdir -p "$PACKAGE_NAME/DEBIAN"
mkdir -p "$PACKAGE_NAME/usr/bin"
mkdir -p "$PACKAGE_NAME/usr/lib/firefox"
mkdir -p "$PACKAGE_NAME/usr/share/applications"
mkdir -p "$PACKAGE_NAME/usr/share/icons/hicolor/256x256/apps"

# Copy Firefox binaries
if [ -d "obj-firefox/dist/firefox" ]; then
    cp -r obj-firefox/dist/firefox/* "$PACKAGE_NAME/usr/lib/firefox/"
    cp "$PACKAGE_NAME/usr/lib/firefox/firefox" "$PACKAGE_NAME/usr/bin/firefox"
else
    echo "Error: Build output not found in obj-firefox/dist/firefox/"
    exit 1
fi

# Create control file
cat > "$PACKAGE_NAME/DEBIAN/control" << EOF
Package: firefox-ryzen
Version: $VERSION
Section: web
Priority: optional
Architecture: amd64
Maintainer: Somanshu <som-anshu@users.noreply.github.com>
Homepage: https://github.com/som-anshu/firefox-source-build
Description: Firefox browser optimized for Ryzen 5 5600H (Zen 3)
 Firefox built from source with CPU-specific optimizations for AMD
 Ryzen 5000 series processors.
 .
 Features:
  - Telemetry removed
  - No automatic updates
  - Firefox Sync preserved
  - AVX/AVX2 optimized
  - Link-time optimization enabled
EOF

# Create postinst script
cat > "$PACKAGE_NAME/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q 2>/dev/null || true
fi

# Update icon cache
if [ -d /usr/share/icons/hicolor ]; then
    gtk-update-icon-cache -q -t /usr/share/icons/hicolor 2>/dev/null || true
fi
EOF
chmod 755 "$PACKAGE_NAME/DEBIAN/postinst"

# Create desktop entry
cat > "$PACKAGE_NAME/usr/share/applications/firefox.desktop" << EOF
[Desktop Entry]
Version=1.0
Name=Firefox (Ryzen Optimized)
GenericName=Web Browser
Comment=Browse the World Wide Web
Exec=/usr/lib/firefox/firefox %u
Icon=firefox
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/vnd.mozilla.xul+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
EOF

# Create symlinks
ln -sf /usr/lib/firefox/firefox "$PACKAGE_NAME/usr/bin/firefox-bin"
ln -sf /usr/lib/firefox/firefox "$PACKAGE_NAME/usr/lib/firefox/firefox-ryzen"

# Build the package
echo "Creating .deb package..."
dpkg-deb --build "$PACKAGE_NAME" "${PACKAGE_NAME}.deb"

echo ""
echo "=================================="
echo "Package created: ${PACKAGE_NAME}.deb"
echo "=================================="
echo ""
echo "To install:"
echo "  sudo dpkg -i ${PACKAGE_NAME}.deb"
echo ""
echo "Or:"
echo "  sudo apt install ./${PACKAGE_NAME}.deb"
echo ""