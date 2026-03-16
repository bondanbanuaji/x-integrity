#!/system/bin/sh
# X-Integrity — Uninstall Script
# Runs when module is removed from Magisk Manager
# Restores original properties and cleans up

PERSISTENT="/data/adb/x-integrity"
BACKUP_DIR="/data/adb/x-integrity-backup"
LOGFILE="/data/adb/x-integrity.log"

log() {
  echo "[$(date '+%H:%M:%S')] [uninstall] $1" >> "$LOGFILE"
}

log "X-Integrity uninstall started..."

#################
# Restore Original Props
#################

if [ -f "$BACKUP_DIR/original.prop" ]; then
  log "Restoring original properties..."

  while IFS='=' read -r prop value; do
    # Skip comments and empty lines
    case "$prop" in
      \#*|"") continue ;;
    esac

    if [ -n "$prop" ] && [ -n "$value" ]; then
      resetprop -n "$prop" "$value" 2>/dev/null
      log "  Restored: $prop"
    fi
  done < "$BACKUP_DIR/original.prop"

  log "Original properties restored ✓"
fi

#################
# Cleanup
#################

log "Cleaning up..."

# Remove persistent config directory
rm -rf "$PERSISTENT" 2>/dev/null
log "  Removed $PERSISTENT"

# Remove backup directory
rm -rf "$BACKUP_DIR" 2>/dev/null
log "  Removed $BACKUP_DIR"

# Remove GMS cleared flag
rm -f "$PERSISTENT/gms_cleared" 2>/dev/null

log "Cleanup complete ✓"
log ""
log "X-Integrity has been uninstalled."
log "Please reboot your device for changes to take full effect."
log ""
