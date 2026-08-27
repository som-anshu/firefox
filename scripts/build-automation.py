#!/usr/bin/env python3
"""
Automated Firefox build and package creation for Ryzen 5 5600H
"""

import subprocess
import os
import sys
from pathlib import Path

def run_cmd(cmd, cwd=None, check=True):
    """Run a shell command"""
    print(f"Running: {cmd}")
    result = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"Error: {result.stderr}")
        sys.exit(1)
    return result

def main():
    print("=" * 60)
    print("Firefox Ryzen 5600H Build Automation")
    print("=" * 60)
    
    work_dir = Path.home() / "firefox-build" / "Firefox-Source-Build"
    firefox_dir = Path.home() / "firefox"
    
    # Step 1: Clone Firefox if needed
    if not firefox_dir.exists():
        print("\n[1/6] Cloning Firefox source...")
        run_cmd("git clone --depth 1 --branch main https://github.com/mozilla-firefox/firefox.git", cwd=str(work_dir.parent))
        firefox_dir = Path(work_dir.parent) / "firefox"
    else:
        print("\n[1/6] Firefox source already exists")
    
    # Step 2: Copy MOZCONFIG
    print("[2/6] Installing optimized MOZCONFIG...")
    mozconfig_src = work_dir / "configs" / ".mozconfig"
    mozconfig_dst = firefox_dir / ".mozconfig"
    
    if mozconfig_src.exists():
        mozconfig_dst.write_text(mozconfig_src.read_text())
        print("  MOZCONFIG installed")
    else:
        print("  ERROR: MOZCONFIG not found")
        sys.exit(1)
    
    # Step 3: Check dependencies
    print("[3/6] Checking build dependencies...")
    required_pkgs = [
        "build-essential", "python3", "git", "clang", "libclang-dev",
        "libgtk-3-dev", "libdbus-1-dev", "libxt-dev", "libx11-xcb-dev",
        "libxcb1-dev", "libffi-dev", "libglib2.0-dev", "nspr-dev",
        "libnss3-dev", "libsqlite3-dev", "libevent-dev", "rustc", "cargo"
    ]
    
    missing = []
    for pkg in required_pkgs:
        result = run_cmd(f"dpkg -l {pkg}", check=False)
        if "no packages found" in result.stdout.lower():
            missing.append(pkg)
    
    if missing:
        print(f"  Missing packages: {', '.join(missing)}")
        print("  Install with: sudo apt install -y " + " ".join(missing))
    else:
        print("  All dependencies satisfied")
    
    # Step 4: Create build script
    print("[4/6] Creating build wrapper...")
    build_script = firefox_dir / "build-fast.sh"
    build_script.write_text(f"""#!/bin/bash
# Fast build wrapper for Ryzen 5600H

export CC=clang
export CXX=clang++
export CFLAGS="-march=znver3 -O3 -pipe -ffast-math"
export CXXFLAGS="-march=znver3 -O3 -pipe -ffast-math"

./mach build -j$(nproc)
""")
    os.chmod(build_script, 0o755)
    print("  Build script created")
    
    # Step 5: Create deb package script
    print("[5/6] Creating DEB package script...")
    deb_script = firefox_dir / "create-deb.sh"
    deb_script.write_text((work_dir / "scripts" / "create-deb.sh").read_text())
    os.chmod(deb_script, 0o755)
    print("  DEB script created")
    
    # Step 6: Summary
    print("\n" + "=" * 60)
    print("BUILD SETUP COMPLETE")
    print("=" * 60)
    print(f"""
To build Firefox:
  cd {firefox_dir}
  ./build-fast.sh

To create .deb package:
  cd {firefox_dir}
  ./create-deb.sh

Build will take 1-2 hours depending on your system.
Output will be in: {firefox_dir}/obj-firefox/dist/

Firefox Sync will be preserved - enable at about:preferences#sync
""")

if __name__ == "__main__":
    main()