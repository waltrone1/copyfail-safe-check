#!/usr/bin/env bash
set -u

# ---------------------------------------------------------------------------
# Copy Fail / CVE-2026-31431 Safe Check
# ---------------------------------------------------------------------------
#
# Project: https://github.com/waltrone1/copyfail-safe-check
# Maintainer: @waltrone1
#
# Read-only script:
# - Does NOT run exploit code
# - Does NOT modify the system
# - Does NOT download anything
#
# This script checks whether the known algif_aead-based Copy Fail attack path
# appears to be mitigated by:
# - checking whether algif_aead is currently loaded
# - checking whether algif_aead can be loaded via modprobe dry-run
# - checking for modprobe block rules
# - checking kernel/kmod package status on Debian/Ubuntu
# - checking whether a reboot is required
#
# Optional:
#   FORCE_COLOR=1 ./check-copyfail-safe.sh
#   NO_COLOR=1 ./check-copyfail-safe.sh
#   STRICT_EXIT_CODES=1 ./check-copyfail-safe.sh
#
# Strict exit codes:
#   0 = OK / mitigated
#   1 = mitigated, but reboot required
#   2 = action required
#   3 = manual review required
#
# ---------------------------------------------------------------------------

# Colors
if { [ -t 1 ] || [ "${FORCE_COLOR:-0}" = "1" ]; } && [ "${NO_COLOR:-0}" != "1" ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  BOLD=''
  NC=''
fi

ok()    { echo -e "${GREEN}OK:${NC} $*"; }
warn()  { echo -e "${YELLOW}WARNING:${NC} $*"; }
crit()  { echo -e "${RED}${BOLD}CRITICAL:${NC} $*"; }
info()  { echo -e "${YELLOW}INFO:${NC} $*"; }
headl() { echo -e "\n${BLUE}${BOLD}===== $* =====${NC}"; }

banner() {
  local color="$1"
  local title="$2"
  local status="$3"

  echo
  echo -e "${color}${BOLD}============================================================${NC}"
  echo -e "${color}${BOLD}  ${title}${NC}"
  echo -e "${color}${BOLD}============================================================${NC}"
  echo -e "${color}${BOLD}  ${status}${NC}"
  echo -e "${color}${BOLD}============================================================${NC}"
}

# State variables
ALGIF_LOADED="unknown"
ALGIF_BLOCKED="unknown"
ALGIF_LOADABLE="unknown"
REBOOT_REQUIRED="unknown"
FINAL_STATUS="REVIEW_REQUIRED_UNCLEAR"
STRICT_EXIT_CODE=3

FINDINGS=()

# Header
echo -e "${BOLD}Copy Fail / CVE-2026-31431 Safe Check${NC}"
echo "Read-only check - no exploit, no system changes"

HOSTNAME_FQDN="$(hostname -f 2>/dev/null || hostname)"
KERNEL_ACTIVE="$(uname -r)"

echo
echo "Host:   $HOSTNAME_FQDN"
echo "Kernel: $KERNEL_ACTIVE"

if [ -f /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "OS:     ${PRETTY_NAME:-unknown}"
else
  echo "OS:     unknown"
fi

# ---------------------------------------------------------------------------
# 1) Check whether algif_aead is loaded
# ---------------------------------------------------------------------------

headl "1) Is algif_aead currently loaded?"

if command -v lsmod >/dev/null 2>&1; then
  if lsmod | grep -q '^algif_aead '; then
    ALGIF_LOADED="yes"
    crit "algif_aead is currently loaded"
    lsmod | grep '^algif_aead '
    FINDINGS+=("algif_aead is currently loaded")
  else
    ALGIF_LOADED="no"
    ok "algif_aead is not currently loaded"
  fi
elif [ -r /proc/modules ]; then
  if grep -q '^algif_aead ' /proc/modules; then
    ALGIF_LOADED="yes"
    crit "algif_aead is currently loaded"
    grep '^algif_aead ' /proc/modules
    FINDINGS+=("algif_aead is currently loaded")
  else
    ALGIF_LOADED="no"
    ok "algif_aead is not currently loaded"
  fi
else
  ALGIF_LOADED="unknown"
  warn "Could not check loaded modules"
  FINDINGS+=("could not check whether algif_aead is loaded")
fi

# ---------------------------------------------------------------------------
# 2) Check whether algif_aead can be loaded via modprobe dry-run
# ---------------------------------------------------------------------------

headl "2) Can algif_aead be loaded via modprobe?"

if command -v modprobe >/dev/null 2>&1; then
  MODPROBE_TEST="$(modprobe -n -v algif_aead 2>&1 || true)"
  echo "$MODPROBE_TEST"

  if echo "$MODPROBE_TEST" | grep -qE 'install[[:space:]]+/bin/false|install[[:space:]]+/bin/true'; then
    ALGIF_BLOCKED="yes"
    ALGIF_LOADABLE="no"
    ok "algif_aead is blocked by a modprobe install rule"
  elif echo "$MODPROBE_TEST" | grep -qE 'insmod .*/algif_aead\.ko|modprobe .*algif_aead'; then
    ALGIF_BLOCKED="no"
    ALGIF_LOADABLE="yes"
    crit "algif_aead appears to be loadable"
    FINDINGS+=("algif_aead appears to be loadable")
  else
    ALGIF_BLOCKED="unknown"
    ALGIF_LOADABLE="unknown"
    warn "modprobe result could not be classified with certainty"
    FINDINGS+=("modprobe result unclear")
  fi
else
  MODPROBE_TEST=""
  ALGIF_BLOCKED="unknown"
  ALGIF_LOADABLE="unknown"
  warn "modprobe command not found"
  FINDINGS+=("modprobe command not found")
fi

# ---------------------------------------------------------------------------
# 3) Module information
# ---------------------------------------------------------------------------

headl "3) Module information"

if command -v modinfo >/dev/null 2>&1; then
  if modinfo algif_aead >/dev/null 2>&1; then
    modinfo algif_aead 2>/dev/null | grep -E '^(filename|name|vermagic):'
  else
    info "No modinfo entry found for algif_aead"
  fi
else
  info "modinfo command not found"
fi

# ---------------------------------------------------------------------------
# 4) Modprobe block rules
# ---------------------------------------------------------------------------

headl "4) Modprobe block rules"

BLOCKRULES="$(grep -R "algif_aead" /etc/modprobe.d /lib/modprobe.d 2>/dev/null || true)"

if [ -n "$BLOCKRULES" ]; then
  ok "algif_aead-related modprobe rule found"
  echo "$BLOCKRULES"
else
  warn "No algif_aead modprobe block rule found"
  FINDINGS+=("no algif_aead modprobe block rule found")
fi

# ---------------------------------------------------------------------------
# 5) Debian / Ubuntu package status
# ---------------------------------------------------------------------------

headl "5) Debian / Ubuntu package status"

if command -v dpkg-query >/dev/null 2>&1; then
  echo "kmod package:"
  dpkg-query -W -f='${Package} ${Version}\n' kmod 2>/dev/null || echo "kmod package not found"

  echo
  echo "Currently running kernel package:"
  dpkg-query -W -f='${Package} ${Version}\n' "linux-image-${KERNEL_ACTIVE}" 2>/dev/null || echo "running kernel package not found via dpkg"

  echo
  echo "Installed linux-image packages:"
  dpkg -l 'linux-image*' 2>/dev/null | awk '/^ii/ {print $2, $3}' | sort -V || true

  echo
  echo "Installed linux-generic packages:"
  dpkg -l 'linux-generic*' 2>/dev/null | awk '/^ii/ {print $2, $3}' | sort -V || true

  echo
  echo "Open kernel/kmod updates:"
  if command -v apt >/dev/null 2>&1; then
    UPG="$(apt list --upgradable 2>/dev/null | grep -E '^(linux-image|linux-modules|linux-generic|linux-headers|kmod)/' || true)"
    if [ -n "$UPG" ]; then
      warn "Kernel/kmod updates are available"
      echo "$UPG"
      FINDINGS+=("kernel/kmod updates are available")
    else
      ok "No obvious kernel/kmod updates are available"
    fi
  else
    info "apt not found"
  fi
else
  info "dpkg-query not found, skipping Debian/Ubuntu package checks"
fi

# ---------------------------------------------------------------------------
# 6) Reboot required
# ---------------------------------------------------------------------------

headl "6) Is a reboot required?"

if [ -f /var/run/reboot-required ]; then
  REBOOT_REQUIRED="yes"
  warn "REBOOT REQUIRED"
  cat /var/run/reboot-required.pkgs 2>/dev/null || true
  FINDINGS+=("reboot required")
else
  REBOOT_REQUIRED="no"
  ok "No reboot-required marker found"
fi

# ---------------------------------------------------------------------------
# 7) RHEL / Rocky / Alma hints
# ---------------------------------------------------------------------------

headl "7) RHEL / Rocky / Alma boot parameter hint"

if command -v grubby >/dev/null 2>&1; then
  GRUBBY_INFO="$(grubby --info=ALL 2>/dev/null | grep -E 'initcall_blacklist=algif_aead_init|module_blacklist=algif_aead' || true)"
  if [ -n "$GRUBBY_INFO" ]; then
    ok "Boot blacklist parameter found"
    echo "$GRUBBY_INFO"
  else
    info "No algif_aead-related boot blacklist parameter found"
  fi
else
  info "grubby not present"
fi

# ---------------------------------------------------------------------------
# 8) Final decision
# ---------------------------------------------------------------------------

if [ "$ALGIF_LOADED" = "no" ] && [ "$ALGIF_BLOCKED" = "yes" ] && [ "$REBOOT_REQUIRED" = "no" ]; then
  FINAL_STATUS="OK_MITIGATED"
  STRICT_EXIT_CODE=0
elif [ "$ALGIF_LOADED" = "no" ] && [ "$ALGIF_BLOCKED" = "yes" ] && [ "$REBOOT_REQUIRED" = "yes" ]; then
  FINAL_STATUS="MITIGATED_REBOOT_REQUIRED"
  STRICT_EXIT_CODE=1
elif [ "$ALGIF_LOADED" = "yes" ]; then
  FINAL_STATUS="ACTION_REQUIRED_MODULE_LOADED"
  STRICT_EXIT_CODE=2
elif [ "$ALGIF_LOADABLE" = "yes" ]; then
  FINAL_STATUS="ACTION_REQUIRED_MODULE_LOADABLE"
  STRICT_EXIT_CODE=2
else
  FINAL_STATUS="REVIEW_REQUIRED_UNCLEAR"
  STRICT_EXIT_CODE=3
fi

# ---------------------------------------------------------------------------
# 9) Final user-friendly summary
# ---------------------------------------------------------------------------

headl "Final result"

case "$FINAL_STATUS" in
  OK_MITIGATED)
    banner "$GREEN" "COPY FAIL CHECK RESULT" "ALL SAFE - NO ACTION REQUIRED"

    echo -e "${GREEN}${BOLD}Result:${NC} This system appears to be protected against the known Copy Fail attack path."
    echo
    echo -e "${BOLD}You must do the following:${NC}"
    echo -e "${GREEN}Nothing else is required right now.${NC}"
    echo
    echo "Details:"
    echo "- algif_aead is not loaded."
    echo "- algif_aead is blocked by a modprobe rule."
    echo "- No reboot is currently required."
    ;;

  MITIGATED_REBOOT_REQUIRED)
    banner "$YELLOW" "COPY FAIL CHECK RESULT" "PROTECTED NOW - REBOOT REQUIRED"

    echo -e "${YELLOW}${BOLD}Result:${NC} This system is currently protected by the algif_aead block rule."
    echo
    echo -e "${BOLD}You must do the following:${NC}"
    echo -e "${YELLOW}Schedule a reboot and run this check again afterwards.${NC}"
    echo
    echo "Why:"
    echo "- algif_aead is not loaded."
    echo "- algif_aead is blocked by a modprobe rule."
    echo "- A reboot is required so installed kernel/system updates can become active."
    echo
    echo "Packages requiring reboot:"
    cat /var/run/reboot-required.pkgs 2>/dev/null || true
    ;;

  ACTION_REQUIRED_MODULE_LOADED)
    banner "$RED" "COPY FAIL CHECK RESULT" "ACTION REQUIRED - MODULE IS LOADED"

    echo -e "${RED}${BOLD}Result:${NC} algif_aead is currently loaded."
    echo
    echo -e "${BOLD}You must do the following:${NC}"
    echo -e "${RED}Patch kernel/kmod, block algif_aead if applicable, and reboot this system.${NC}"
    echo
    echo "Why:"
    echo "- algif_aead is currently loaded."
    echo "- The known Copy Fail attack path does not appear to be mitigated."
    ;;

  ACTION_REQUIRED_MODULE_LOADABLE)
    banner "$RED" "COPY FAIL CHECK RESULT" "ACTION REQUIRED - MODULE IS LOADABLE"

    echo -e "${RED}${BOLD}Result:${NC} algif_aead appears to be loadable."
    echo
    echo -e "${BOLD}You must do the following:${NC}"
    echo -e "${RED}Update kernel/kmod or temporarily block algif_aead, then run this check again.${NC}"
    echo
    echo "Why:"
    echo "- algif_aead is not safely blocked."
    echo "- The known Copy Fail attack path does not appear to be fully mitigated."
    ;;

  *)
    banner "$YELLOW" "COPY FAIL CHECK RESULT" "MANUAL REVIEW REQUIRED"

    echo -e "${YELLOW}${BOLD}Result:${NC} The script could not clearly determine the protection status."
    echo
    echo -e "${BOLD}You must do the following:${NC}"
    echo -e "${YELLOW}Manually review the modprobe result, kernel version, block rules, and reboot status.${NC}"
    echo
    echo "Why:"
    echo "- The check result was unclear."
    echo "- The system should not be considered fully verified until reviewed."
    ;;
esac

echo
echo "------------------------------------------------------------"
echo -e "${BOLD}Machine-readable status:${NC} ${FINAL_STATUS}"
echo -e "${BOLD}Read-only note:${NC} This script does not run an exploit and does not modify the system."
echo
echo -e "${BOLD}Cleanup note:${NC} This check file can be deleted after use."
echo "If you cloned the repository only for this check, you can remove it with:"
echo "  cd ~ && rm -rf copyfail-safe-check"
echo "If you downloaded only this script, you can remove it with:"
echo "  rm -f ./copyfail-safe-check.sh"
echo "------------------------------------------------------------"

if [ "${STRICT_EXIT_CODES:-0}" = "1" ]; then
  exit "$STRICT_EXIT_CODE"
fi

exit 0
