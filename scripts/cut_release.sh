#!/usr/bin/env bash
# Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
# Licensed under the Business Source License 1.1 (BUSL-1.1).
#
# Release cutting automation script for SarvMD Synchronized Monorepo.
# Usage: ./scripts/cut_release.sh <X.Y.Z>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

if [ $# -lt 1 ]; then
  echo -e "${RED}Error: Missing target version argument.${NC}"
  echo -e "Usage: $0 <X.Y.Z> (e.g. $0 0.13.0)"
  exit 1
fi

TARGET_VERSION="$1"

# Validate SemVer
if [[ ! "$TARGET_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo -e "${RED}Error: Version '$TARGET_VERSION' is not a valid Semantic Version (expected X.Y.Z).${NC}"
  exit 1
fi

RELEASE_DATE="$(date +%Y-%m-%d)"
TAG_NAME="v${TARGET_VERSION}"

echo -e "\n${BOLD}${BLUE}======================================================${NC}"
echo -e "${BOLD}${BLUE}  SarvMD Monorepo Release Coordinator: ${TAG_NAME} (${RELEASE_DATE})${NC}"
echo -e "${BOLD}${BLUE}======================================================${NC}\n"

# 1. Update Package Manifests
echo -e "${BOLD}1. Updating pubspec.yaml manifests...${NC}"
sed -i -E "s/^version:\s*[0-9]+\.[0-9]+\.[0-9]+/version: ${TARGET_VERSION}/" "$WORKSPACE_ROOT/packages/sarvmd_core/pubspec.yaml"
sed -i -E "s/^version:\s*[0-9]+\.[0-9]+\.[0-9]+/version: ${TARGET_VERSION}/" "$WORKSPACE_ROOT/apps/sarvmd_cli/pubspec.yaml"
sed -i -E "s/^version:\s*[0-9]+\.[0-9]+\.[0-9]+/version: ${TARGET_VERSION}/" "$WORKSPACE_ROOT/apps/sarvmd_ui/pubspec.yaml"
echo -e "${GREEN}✓ Updated packages/sarvmd_core/pubspec.yaml${NC}"
echo -e "${GREEN}✓ Updated apps/sarvmd_cli/pubspec.yaml${NC}"
echo -e "${GREEN}✓ Updated apps/sarvmd_ui/pubspec.yaml${NC}"

# 2. Update Code Version Constants
echo -e "\n${BOLD}2. Updating static code constants...${NC}"
sed -i -E "s/static const String version = '[0-9]+\.[0-9]+\.[0-9]+';/static const String version = '${TARGET_VERSION}';/" \
  "$WORKSPACE_ROOT/apps/sarvmd_ui/lib/src/core/constants/app_version.dart"

sed -i -E "s/static const String currentVersion = '[0-9]+\.[0-9]+\.[0-9]+';/static const String currentVersion = '${TARGET_VERSION}';/" \
  "$WORKSPACE_ROOT/apps/sarvmd_cli/lib/src/runner.dart"

echo -e "${GREEN}✓ Updated AppVersion.version in app_version.dart${NC}"
echo -e "${GREEN}✓ Updated SarvCommandRunner.currentVersion in runner.dart${NC}"

# 3. Promote Changelogs if needed
echo -e "\n${BOLD}3. Checking and promoting package changelogs...${NC}"
promote_changelog() {
  local file="$1"
  local name="$2"
  if grep -q "## \[${TARGET_VERSION}\]" "$file"; then
    echo -e "${GREEN}✓ $name changelog already contains ## [${TARGET_VERSION}]${NC}"
  elif grep -q "## \[Unreleased\]" "$file"; then
    sed -i "s/## \[Unreleased\]/## [Unreleased]\n\n## [${TARGET_VERSION}] - ${RELEASE_DATE}/" "$file"
    echo -e "${GREEN}✓ Promoted [Unreleased] to [${TARGET_VERSION}] - ${RELEASE_DATE} in $name${NC}"
  else
    echo -e "${YELLOW}! Warning: No ## [Unreleased] section found in $file${NC}"
  fi
}

promote_changelog "$WORKSPACE_ROOT/packages/sarvmd_core/CHANGELOG.md" "sarvmd_core"
promote_changelog "$WORKSPACE_ROOT/apps/sarvmd_cli/CHANGELOG.md" "sarvmd_cli"
promote_changelog "$WORKSPACE_ROOT/apps/sarvmd_ui/CHANGELOG.md" "sarvmd_ui"

# 4. Run Full Validation Gate
echo -e "\n${BOLD}4. Running full automated validation gate...${NC}"
"$WORKSPACE_ROOT/scripts/full_validation_gate.sh"

# 5. Git Commit & Tag
echo -e "\n${BOLD}5. Creating release commit and annotated tag...${NC}"
git -C "$WORKSPACE_ROOT" add \
  packages/sarvmd_core/pubspec.yaml \
  packages/sarvmd_core/CHANGELOG.md \
  apps/sarvmd_cli/pubspec.yaml \
  apps/sarvmd_cli/CHANGELOG.md \
  apps/sarvmd_cli/lib/src/runner.dart \
  apps/sarvmd_ui/pubspec.yaml \
  apps/sarvmd_ui/CHANGELOG.md \
  apps/sarvmd_ui/lib/src/core/constants/app_version.dart

git -C "$WORKSPACE_ROOT" commit -s -m "release: bump version to ${TAG_NAME}"
git -C "$WORKSPACE_ROOT" tag -a "${TAG_NAME}" -m "Release ${TAG_NAME}"

echo -e "\n${BOLD}${GREEN}======================================================${NC}"
echo -e "${BOLD}${GREEN}  RELEASE ${TAG_NAME} CREATED SUCCESSFULLY!${NC}"
echo -e "${BOLD}${GREEN}======================================================${NC}"
echo -e "\nTo publish this release to GitHub, run:"
echo -e "  ${BOLD}git push origin $(git -C "$WORKSPACE_ROOT" rev-parse --abbrev-ref HEAD)${NC}"
echo -e "  ${BOLD}git push origin ${TAG_NAME}${NC}\n"
