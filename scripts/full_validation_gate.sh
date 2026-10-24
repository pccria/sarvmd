#!/usr/bin/env bash
# Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
# Licensed under the Business Source License 1.1 (BUSL-1.1).
#
# Full Automated Validation Gate for SarvMD Workspaces.
# Ensures static analysis and test suites pass across core, UI, and CLI.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_step() {
  echo -e "\n${BOLD}${BLUE}===> $1${NC}"
}

log_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

log_failure() {
  echo -e "${RED}✗ $1${NC}"
  exit 1
}

log_step "1/4 Running Static Analysis across workspace..."
(cd "$WORKSPACE_ROOT" && dart analyze) \
  && log_success "Workspace static analysis passed" \
  || log_failure "Workspace static analysis failed"

log_step "2/4 Running Unit Tests on sarvmd_core..."
(cd "$WORKSPACE_ROOT/packages/sarvmd_core" && flutter test) \
  && log_success "sarvmd_core tests passed" \
  || log_failure "sarvmd_core tests failed"

log_step "3/4 Running Unit & Command Tests on sarvmd_cli..."
(cd "$WORKSPACE_ROOT/apps/sarvmd_cli" && dart test) \
  && log_success "sarvmd_cli tests passed" \
  || log_failure "sarvmd_cli tests failed"

log_step "4/4 Running Widget & Unit Tests on sarvmd_ui..."
(cd "$WORKSPACE_ROOT/apps/sarvmd_ui" && flutter test) \
  && log_success "sarvmd_ui tests passed" \
  || log_failure "sarvmd_ui tests failed"

echo -e "\n${BOLD}${GREEN}=========================================${NC}"
echo -e "${BOLD}${GREEN}  ALL VALIDATION GATE CHECKS PASSED!     ${NC}"
echo -e "${BOLD}${GREEN}=========================================${NC}\n"
