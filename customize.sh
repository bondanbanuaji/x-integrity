#!/system/bin/sh
# X-Integrity — Installation Script
# This script runs during module installation via Magisk/KitsuneMask

SKIPUNZIP=1

#################
# Helper Functions
#################

print_banner() {
  ui_print ""
  ui_print "╔══════════════════════════════════════╗"
  ui_print "║        X-INTEGRITY v1.0.0            ║"
  ui_print "║   Play Integrity Fix — All Devices   ║"
  ui_print "╠══════════════════════════════════════╣"
  ui_print "║  ✓ Device Integrity                  ║"
  ui_print "║  ✓ Strong Integrity                  ║"
  ui_print "║  ✓ Anti-Bootloop Protection          ║"
  ui_print "║  ✓ 100% Systemless & Safe            ║"
  ui_print "╚══════════════════════════════════════╝"
  ui_print ""
}

abort_install() {
  ui_print ""
  ui_print "❌ $1"
  ui_print "   Installation aborted!"
  ui_print ""
  abort "$1"
}

#################
# Compatibility Checks
#################

check_magisk_version() {
  if [ "$MAGISK_VER_CODE" -lt 24000 ]; then
    abort_install "Magisk v24.0+ required! Current: $MAGISK_VER"
  fi
  ui_print "✅ Magisk version: $MAGISK_VER ($MAGISK_VER_CODE)"
}

check_architecture() {
  case "$ARCH" in
    arm64|arm|x86_64|x86)
      ui_print "✅ Architecture: $ARCH"
      ;;
    *)
      abort_install "Unsupported architecture: $ARCH"
      ;;
  esac
}

check_android_version() {
  local api_level="$API"
  if [ "$api_level" -lt 29 ]; then
    abort_install "Android 10+ required! Current API: $api_level"
  fi
  ui_print "✅ Android API: $api_level (Android $( \
    case $api_level in
      29) echo "10" ;;
      30) echo "11" ;;
      31|32) echo "12" ;;
      33) echo "13" ;;
      34) echo "14" ;;
      35) echo "15" ;;
      *) echo "$api_level" ;;
    esac
  ))"
}

check_zygisk() {
  if [ "$(magisk --denylist status 2>/dev/null)" = "0" ] || \
     [ -d "/data/adb/modules/zygisksu" ] || \
     [ -d "/data/adb/modules/zygisknext" ] || \
     [ -d "/data/adb/modules/rezygisk" ] || \
     [ -d "/data/adb/modules/neozygisk" ]; then
    ui_print "✅ Zygisk: detected"
  else
    ui_print "⚠️  Zygisk: not detected"
    ui_print "   Module will still work, but Zygisk is recommended"
    ui_print "   for better root hiding capabilities."
  fi
}

check_conflicting_modules() {
  local conflict=0
  local modules_dir="/data/adb/modules"

  # Check for old/conflicting Play Integrity modules
  for mod in "safetynet-fix" "MagiskHidePropsConf" "riru-unshare" ; do
    if [ -d "$modules_dir/$mod" ] && [ ! -f "$modules_dir/$mod/disable" ]; then
      ui_print "⚠️  Conflicting module detected: $mod"
      ui_print "   Consider disabling it to avoid conflicts."
      conflict=1
    fi
  done

  # Check for other PIF modules (warn but don't block)
  for mod in "playintegrityfix" "PlayIntegrityFork" "playcurl" ; do
    if [ -d "$modules_dir/$mod" ] && [ ! -f "$modules_dir/$mod/disable" ]; then
      ui_print "⚠️  Another PIF module found: $mod"
      ui_print "   X-Integrity will work alongside it, but you may"
      ui_print "   want to disable it to avoid conflicts."
    fi
  done

  return $conflict
}

#################
# Backup Functions
#################

backup_original_props() {
  local backup_dir="/data/adb/x-integrity-backup"
  mkdir -p "$backup_dir"

  ui_print "📦 Backing up original properties..."

  # Save original props
  {
    echo "# X-Integrity Original Properties Backup"
    echo "# Created: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "# DO NOT MODIFY THIS FILE"
    echo ""
    for prop in \
      ro.build.fingerprint \
      ro.build.description \
      ro.product.model \
      ro.product.manufacturer \
      ro.product.brand \
      ro.product.device \
      ro.product.name \
      ro.build.version.security_patch \
      ro.vendor.build.fingerprint \
      ro.bootimage.build.fingerprint \
      ro.build.display.id \
      ro.build.version.incremental \
      ro.build.type \
      ro.build.tags \
      ro.build.version.release \
      ro.build.id \
    ; do
      local val="$(getprop "$prop")"
      if [ -n "$val" ]; then
        echo "$prop=$val"
      fi
    done
  } > "$backup_dir/original.prop"

  ui_print "   Saved to $backup_dir/original.prop"
}

#################
# Installation
#################

print_banner

ui_print "━━━ Compatibility Checks ━━━"
check_magisk_version
check_architecture
check_android_version
check_zygisk
check_conflicting_modules

ui_print ""
ui_print "━━━ Installing Module ━━━"

# Extract module files
ui_print "📂 Extracting module files..."
unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >&2 || abort_install "Failed to extract module files"

# Backup original props
backup_original_props

# Handle custom pif.json
if [ -f "/data/adb/x-integrity/custom.pif.json" ]; then
  ui_print "📋 Found existing custom.pif.json, preserving..."
  cp -f "/data/adb/x-integrity/custom.pif.json" "$MODPATH/custom.pif.json"
fi

# Create persistent config directory
mkdir -p "/data/adb/x-integrity"

# Copy pif.json to persistent location if not exists
if [ ! -f "/data/adb/x-integrity/pif.json" ]; then
  cp -f "$MODPATH/pif.json" "/data/adb/x-integrity/pif.json"
  ui_print "📋 Default pif.json installed"
else
  ui_print "📋 Existing pif.json preserved"
fi

# Initialize boot counter for bootloop protection
echo "0" > "/data/adb/x-integrity/boot_count"

# Set proper permissions
ui_print "🔒 Setting permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
[ -d "$MODPATH/common" ] && set_perm_recursive "$MODPATH/common" 0 0 0755 0755

ui_print ""
ui_print "━━━ Installation Complete ━━━"
ui_print ""
ui_print "✅ X-Integrity installed successfully!"
ui_print ""
ui_print "📌 Next steps:"
ui_print "   1. Reboot your device"
ui_print "   2. Open Play Integrity API Checker"
ui_print "   3. Verify DEVICE_INTEGRITY ✓"
ui_print ""
ui_print "📌 For STRONG_INTEGRITY:"
ui_print "   → Also install Tricky Store + valid keybox"
ui_print ""
ui_print "📂 Config: /data/adb/x-integrity/"
ui_print "📝 Logs:   /data/adb/x-integrity.log"
ui_print ""
