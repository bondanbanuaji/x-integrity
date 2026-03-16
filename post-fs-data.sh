#!/system/bin/sh
# X-Integrity — Post-FS-Data Script
# Runs early in boot process before system is fully mounted
# Uses resetprop to spoof device properties for Play Integrity

MODDIR=${0%/*}
PERSISTENT="/data/adb/x-integrity"
LOGFILE="/data/adb/x-integrity.log"
BOOT_COUNT_FILE="$PERSISTENT/boot_count"
MAX_BOOT_FAILURES=3

#################
# Logging
#################

log() {
  echo "[$(date '+%H:%M:%S')] [post-fs-data] $1" >> "$LOGFILE"
}

log_start() {
  echo "" >> "$LOGFILE"
  echo "========================================" >> "$LOGFILE"
  echo " X-Integrity — Boot Log" >> "$LOGFILE"
  echo " $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOGFILE"
  echo "========================================" >> "$LOGFILE"
}

#################
# Safety Checks
#################

# Check safe mode — skip everything if in safe mode
if [ "$(getprop ro.sys.safemode)" = "1" ] || [ "$(getprop persist.sys.safemode)" = "1" ]; then
  echo "[SAFE MODE] X-Integrity skipped — device in safe mode" >> "$LOGFILE"
  exit 0
fi

# Bootloop protection
if [ -f "$BOOT_COUNT_FILE" ]; then
  BOOT_COUNT=$(cat "$BOOT_COUNT_FILE" 2>/dev/null)
  BOOT_COUNT=${BOOT_COUNT:-0}

  if [ "$BOOT_COUNT" -ge "$MAX_BOOT_FAILURES" ]; then
    echo "[BOOTLOOP PROTECTION] X-Integrity disabled after $MAX_BOOT_FAILURES failed boots" >> "$LOGFILE"
    echo "[BOOTLOOP PROTECTION] Delete $BOOT_COUNT_FILE and reboot to re-enable" >> "$LOGFILE"
    # Touch disable file to disable module
    touch "$MODDIR/disable"
    exit 0
  fi

  # Increment boot counter (will be reset in service.sh on successful boot)
  BOOT_COUNT=$((BOOT_COUNT + 1))
  echo "$BOOT_COUNT" > "$BOOT_COUNT_FILE"
fi

#################
# JSON Parser
#################

# Lightweight JSON value parser (no jq dependency)
json_get() {
  local file="$1"
  local key="$2"
  local value=""

  value=$(grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" 2>/dev/null | \
          head -1 | \
          sed 's/.*:[[:space:]]*"\(.*\)"/\1/')

  # Also check for boolean/number values
  if [ -z "$value" ]; then
    value=$(grep -o "\"$key\"[[:space:]]*:[[:space:]]*[^,}]*" "$file" 2>/dev/null | \
            head -1 | \
            sed 's/.*:[[:space:]]*//' | \
            sed 's/[[:space:]]//g')
  fi

  echo "$value"
}

#################
# Load Configuration
#################

log_start
log "Starting Play Integrity Fix..."

# Determine which config to use (custom > persistent > bundled)
PIF_FILE=""
if [ -f "$PERSISTENT/custom.pif.json" ]; then
  # Check if custom.pif.json has actual values (not empty template)
  fp=$(json_get "$PERSISTENT/custom.pif.json" "FINGERPRINT")
  if [ -n "$fp" ]; then
    PIF_FILE="$PERSISTENT/custom.pif.json"
    log "Using custom fingerprint config"
  fi
fi

if [ -z "$PIF_FILE" ] && [ -f "$PERSISTENT/pif.json" ]; then
  PIF_FILE="$PERSISTENT/pif.json"
  log "Using persistent fingerprint config"
elif [ -z "$PIF_FILE" ] && [ -f "$MODDIR/pif.json" ]; then
  PIF_FILE="$MODDIR/pif.json"
  log "Using bundled fingerprint config"
fi

if [ -z "$PIF_FILE" ]; then
  log "ERROR: No pif.json found! Aborting."
  exit 1
fi

log "Config file: $PIF_FILE"

#################
# Read Spoof Settings
#################

SPOOF_BUILD=$(json_get "$PIF_FILE" "spoofBuild")
SPOOF_PROPS=$(json_get "$PIF_FILE" "spoofProps")
SPOOF_PROVIDER=$(json_get "$PIF_FILE" "spoofProvider")

# Default to true if not set
SPOOF_BUILD=${SPOOF_BUILD:-true}
SPOOF_PROPS=${SPOOF_PROPS:-true}

#################
# Read Fingerprint Values
#################

FP_MANUFACTURER=$(json_get "$PIF_FILE" "MANUFACTURER")
FP_MODEL=$(json_get "$PIF_FILE" "MODEL")
FP_FINGERPRINT=$(json_get "$PIF_FILE" "FINGERPRINT")
FP_BRAND=$(json_get "$PIF_FILE" "BRAND")
FP_PRODUCT=$(json_get "$PIF_FILE" "PRODUCT")
FP_DEVICE=$(json_get "$PIF_FILE" "DEVICE")
FP_RELEASE=$(json_get "$PIF_FILE" "RELEASE")
FP_ID=$(json_get "$PIF_FILE" "ID")
FP_INCREMENTAL=$(json_get "$PIF_FILE" "INCREMENTAL")
FP_TYPE=$(json_get "$PIF_FILE" "TYPE")
FP_TAGS=$(json_get "$PIF_FILE" "TAGS")
FP_SECURITY_PATCH=$(json_get "$PIF_FILE" "SECURITY_PATCH")
FP_SDK_INT=$(json_get "$PIF_FILE" "DEVICE_INITIAL_SDK_INT")

# Validate critical fields
if [ -z "$FP_FINGERPRINT" ]; then
  log "ERROR: FINGERPRINT is empty! Check pif.json"
  exit 1
fi

log "Spoofing as: $FP_MANUFACTURER $FP_MODEL"
log "Fingerprint: $FP_FINGERPRINT"

#################
# Apply Spoofed Props
#################

# Use resetprop -n to avoid triggering property_service events
# The -n flag prevents the property change from being detected

spoof_prop() {
  local prop="$1"
  local value="$2"

  if [ -n "$value" ]; then
    resetprop -n "$prop" "$value" 2>/dev/null
    log "  ✓ $prop"
  fi
}

if [ "$SPOOF_BUILD" = "true" ]; then
  log "Applying build prop spoofing..."

  # Core fingerprint
  spoof_prop "ro.build.fingerprint" "$FP_FINGERPRINT"
  spoof_prop "ro.vendor.build.fingerprint" "$FP_FINGERPRINT"
  spoof_prop "ro.bootimage.build.fingerprint" "$FP_FINGERPRINT"
  spoof_prop "ro.odm.build.fingerprint" "$FP_FINGERPRINT"
  spoof_prop "ro.product.build.fingerprint" "$FP_FINGERPRINT"
  spoof_prop "ro.system.build.fingerprint" "$FP_FINGERPRINT"
  spoof_prop "ro.system_ext.build.fingerprint" "$FP_FINGERPRINT"

  # Build description
  if [ -n "$FP_PRODUCT" ] && [ -n "$FP_RELEASE" ] && [ -n "$FP_ID" ] && [ -n "$FP_INCREMENTAL" ]; then
    desc="${FP_PRODUCT}-${FP_TYPE} ${FP_RELEASE} ${FP_ID} ${FP_INCREMENTAL} ${FP_TAGS}"
    spoof_prop "ro.build.description" "$desc"
  fi

  # Build identification
  spoof_prop "ro.build.id" "$FP_ID"
  spoof_prop "ro.build.display.id" "$FP_ID"
  spoof_prop "ro.build.version.incremental" "$FP_INCREMENTAL"
  spoof_prop "ro.build.type" "$FP_TYPE"
  spoof_prop "ro.build.tags" "$FP_TAGS"
  spoof_prop "ro.build.version.release" "$FP_RELEASE"
  spoof_prop "ro.build.version.release_or_codename" "$FP_RELEASE"

  # Security patch
  spoof_prop "ro.build.version.security_patch" "$FP_SECURITY_PATCH"
  spoof_prop "ro.vendor.build.security_patch" "$FP_SECURITY_PATCH"

  # Device initial SDK
  if [ -n "$FP_SDK_INT" ]; then
    spoof_prop "ro.product.first_api_level" "$FP_SDK_INT"
  fi

  log "Build props spoofed ✓"
fi

if [ "$SPOOF_PROPS" = "true" ]; then
  log "Applying product prop spoofing..."

  # Product props (all partitions)
  for partition in "" "product." "vendor." "system." "system_ext." "odm." "bootimage."; do
    spoof_prop "ro.${partition}product.manufacturer" "$FP_MANUFACTURER"
    spoof_prop "ro.${partition}product.model" "$FP_MODEL"
    spoof_prop "ro.${partition}product.brand" "$FP_BRAND"
    spoof_prop "ro.${partition}product.name" "$FP_PRODUCT"
    spoof_prop "ro.${partition}product.device" "$FP_DEVICE"
  done

  log "Product props spoofed ✓"
fi

#################
# Hide Root Indicators
#################

log "Hiding root indicators..."

# Ensure build type is 'user' not 'userdebug' or 'eng'
spoof_prop "ro.build.type" "user"
spoof_prop "ro.build.tags" "release-keys"
spoof_prop "ro.debuggable" "0"
spoof_prop "ro.secure" "1"

# Hide Magisk related props if exist
resetprop --delete "ro.magisk.version" 2>/dev/null
resetprop --delete "ro.magisk.versionString" 2>/dev/null

# Ensure verified boot state
spoof_prop "ro.boot.vbmeta.device_state" "locked"
spoof_prop "ro.boot.verifiedbootstate" "green"
spoof_prop "ro.boot.flash.locked" "1"
spoof_prop "ro.boot.veritymode" "enforcing"
spoof_prop "ro.boot.warranty_bit" "0"
spoof_prop "ro.warranty_bit" "0"
spoof_prop "ro.is_ever_orange" "0"

log "Root indicators hidden ✓"

#################
# Disable ROM Built-in Spoofing
#################

# Some custom ROMs have their own spoofing that conflicts
# We need to disable it so ours takes priority

# Disable custom ROM certification spoofing
if [ "$(getprop persist.sys.pihooks.enable)" = "true" ]; then
  spoof_prop "persist.sys.pihooks.enable" "false"
  log "Disabled ROM built-in PI hooks"
fi

# Disable GMS spoofing from custom ROM
for spoof_prop_name in \
  "persist.sys.pixelprops.gms" \
  "persist.sys.pixelprops.gphotos" \
  "persist.sys.pihooks.enable" \
; do
  if [ -n "$(getprop "$spoof_prop_name")" ]; then
    resetprop -n "$spoof_prop_name" "false" 2>/dev/null
    log "Disabled ROM spoof: $spoof_prop_name"
  fi
done

log "Post-fs-data phase complete ✓"
