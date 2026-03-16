#!/system/bin/sh
# X-Integrity — Service Script
# Runs late in boot process after system is fully mounted
# Re-applies spoofing and clears GMS cache

MODDIR=${0%/*}
PERSISTENT="/data/adb/x-integrity"
LOGFILE="/data/adb/x-integrity.log"
BOOT_COUNT_FILE="$PERSISTENT/boot_count"

#################
# Logging
#################

log() {
  echo "[$(date '+%H:%M:%S')] [service] $1" >> "$LOGFILE"
}

#################
# Safety Checks
#################

# Check safe mode
if [ "$(getprop ro.sys.safemode)" = "1" ] || [ "$(getprop persist.sys.safemode)" = "1" ]; then
  echo "[SAFE MODE] Service script skipped" >> "$LOGFILE"
  exit 0
fi

# Check if module is disabled
if [ -f "$MODDIR/disable" ]; then
  log "Module is disabled, skipping service script"
  exit 0
fi

#################
# Wait for Boot
#################

log "Waiting for boot to complete..."

# Wait for boot_completed signal (max 120 seconds)
WAIT_COUNT=0
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 1
  WAIT_COUNT=$((WAIT_COUNT + 1))
  if [ $WAIT_COUNT -ge 120 ]; then
    log "WARNING: Boot completion timeout after 120s"
    break
  fi
done

log "Boot completed after ${WAIT_COUNT}s"

#################
# Reset Boot Counter (boot succeeded!)
#################

# If we get here, boot was successful — reset the counter
echo "0" > "$BOOT_COUNT_FILE"
log "Boot counter reset (successful boot) ✓"

# Remove disable flag if it was set by bootloop protection
# (user manually re-enabled the module)
if [ -f "$MODDIR/disable" ] && [ -f "$PERSISTENT/auto_disabled" ]; then
  rm -f "$PERSISTENT/auto_disabled"
  log "Cleared auto-disable flag"
fi

#################
# JSON Parser
#################

json_get() {
  local file="$1"
  local key="$2"
  local value=""

  value=$(grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" 2>/dev/null | \
          head -1 | \
          sed 's/.*:[[:space:]]*"\(.*\)"/\1/')

  if [ -z "$value" ]; then
    value=$(grep -o "\"$key\"[[:space:]]*:[[:space:]]*[^,}]*" "$file" 2>/dev/null | \
            head -1 | \
            sed 's/.*:[[:space:]]*//' | \
            sed 's/[[:space:]]//g')
  fi

  echo "$value"
}

#################
# Re-apply Props (some get reset during boot)
#################

log "Re-applying critical properties..."

# Determine config file
PIF_FILE=""
if [ -f "$PERSISTENT/custom.pif.json" ]; then
  fp=$(json_get "$PERSISTENT/custom.pif.json" "FINGERPRINT")
  if [ -n "$fp" ]; then
    PIF_FILE="$PERSISTENT/custom.pif.json"
  fi
fi
[ -z "$PIF_FILE" ] && [ -f "$PERSISTENT/pif.json" ] && PIF_FILE="$PERSISTENT/pif.json"
[ -z "$PIF_FILE" ] && [ -f "$MODDIR/pif.json" ] && PIF_FILE="$MODDIR/pif.json"

if [ -n "$PIF_FILE" ]; then
  FP_FINGERPRINT=$(json_get "$PIF_FILE" "FINGERPRINT")
  FP_SECURITY_PATCH=$(json_get "$PIF_FILE" "SECURITY_PATCH")

  # Re-apply critical props that might get overwritten
  [ -n "$FP_FINGERPRINT" ] && resetprop -n "ro.build.fingerprint" "$FP_FINGERPRINT" 2>/dev/null
  [ -n "$FP_SECURITY_PATCH" ] && resetprop -n "ro.build.version.security_patch" "$FP_SECURITY_PATCH" 2>/dev/null

  # Ensure root hiding props stay set
  resetprop -n "ro.build.type" "user" 2>/dev/null
  resetprop -n "ro.build.tags" "release-keys" 2>/dev/null
  resetprop -n "ro.debuggable" "0" 2>/dev/null
  resetprop -n "ro.secure" "1" 2>/dev/null
  resetprop -n "ro.boot.vbmeta.device_state" "locked" 2>/dev/null
  resetprop -n "ro.boot.verifiedbootstate" "green" 2>/dev/null
  resetprop -n "ro.boot.flash.locked" "1" 2>/dev/null
  resetprop -n "ro.boot.veritymode" "enforcing" 2>/dev/null

  log "Critical properties re-applied ✓"
fi

#################
# Clear GMS Cache
#################

clear_gms_cache() {
  log "Clearing Google Play Services DroidGuard cache..."

  # Force stop GMS
  am force-stop com.google.android.gms 2>/dev/null
  sleep 1

  # Clear DroidGuard cache (this forces re-evaluation of integrity)
  local gms_data="/data/data/com.google.android.gms"
  local gms_dg_cache="$gms_data/databases/dg.db"

  if [ -f "$gms_dg_cache" ]; then
    rm -f "$gms_dg_cache" 2>/dev/null
    rm -f "${gms_dg_cache}-journal" 2>/dev/null
    rm -f "${gms_dg_cache}-wal" 2>/dev/null
    rm -f "${gms_dg_cache}-shm" 2>/dev/null
    log "  Cleared DroidGuard database ✓"
  fi

  # Clear integrity cache files
  local cache_dirs="
    $gms_data/cache
    $gms_data/code_cache
    /data/data/com.google.android.gms/app_dg_cache
  "

  for dir in $cache_dirs; do
    if [ -d "$dir" ]; then
      find "$dir" -name "*integrity*" -delete 2>/dev/null
      find "$dir" -name "*droidguard*" -delete 2>/dev/null
      find "$dir" -name "*attest*" -delete 2>/dev/null
    fi
  done

  log "GMS cache cleared ✓"
}

# Only clear on first boot after install/update
if [ ! -f "$PERSISTENT/gms_cleared" ]; then
  # Small delay to ensure GMS has started
  sleep 5
  clear_gms_cache
  touch "$PERSISTENT/gms_cleared"
else
  log "GMS cache already cleared (previous boot)"
fi

#################
# Status Report
#################

log ""
log "━━━ X-Integrity Status Report ━━━"
log "Module version: $(grep 'version=' "$MODDIR/module.prop" 2>/dev/null | head -1 | cut -d= -f2)"
log "Config file: $PIF_FILE"
log "Spoofed fingerprint: $(getprop ro.build.fingerprint)"
log "Security patch: $(getprop ro.build.version.security_patch)"
log "Build type: $(getprop ro.build.type)"
log "Build tags: $(getprop ro.build.tags)"
log "Boot state: $(getprop ro.boot.verifiedbootstate)"
log "VBMeta state: $(getprop ro.boot.vbmeta.device_state)"
log "━━━ End Status Report ━━━"
log ""
log "X-Integrity service complete ✓"
log "Check integrity at: Play Integrity API Checker app"
