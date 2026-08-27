#!/bin/bash
# Setup and push Firefox build config to GitHub

REPO_URL="git@github.com:som-anshu/firefox-source-build.git"

echo "Setting up GitHub repository for Firefox source build..."

cd ~/firefox-build/Firefox-Source-Build

# Add remote
git remote add origin "$REPO_URL" 2>/dev/null || git remote set-url origin "$REPO_URL"

echo ""
echo "Repository structure created locally."
echo ""
echo "To create the remote repository and push, run:"
echo ""
echo "  # If you have GitHub CLI installed and authenticated:"
echo "  gh repo create som-anshu/firefox-source-build --public --source=. --push"
echo ""
echo "  # Or create repository via web UI at:"
echo "  https://github.com/som-anshu/firefox-source-build"
echo ""
echo "  # Then add and push:"
echo "  git remote add origin git@github.com:som-anshu/firefox-source-build.git"
echo "  git branch -M main"
echo "  git push -u origin main"
echo ""
echo "Files ready to push:"
git status --short