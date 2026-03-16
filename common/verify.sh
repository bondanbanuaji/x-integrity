#!/system/bin/sh
# X-Integrity — Verification Script
# Checks current spoofing status and provides diagnostics
# Run via: sh /data/adb/modules/x-integrity/common/verify.sh

echo ""
echo "╔══════════════════════════════════════╗"
echo "║    X-Integrity — Status Verifier     ║"
echo "╚══════════════════════════════════════╝"
echo ""

#################
# Module Status
#################

echo "━━━ Module Status ━━━"

MODDIR="/data/adb/modules/x-integrity"
if [ -d "$MODDIR" ]; then
  if [ -f "$MODDIR/disable" ]; then
    echo "  Module:  ❌ DISABLED"
  elif [ -f "$MODDIR/remove" ]; then
    echo "  Module:  ⚠️  PENDING REMOVAL"
  else
    echo "  Module:  ✅ ACTIVE"
  fi
  VERSION=$(grep 'version=' "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)
  echo "  Version: $VERSION"
else
  echo "  Module:  ❌ NOT INSTALLED"
  exit 1
fi

echo ""

#################
# Bootloop Protection
#################

echo "━━━ Safety Status ━━━"

BOOT_FILE="/data/adb/x-integrity/boot_count"
if [ -f "$BOOT_FILE" ]; then
  BOOT_COUNT=$(cat "$BOOT_FILE")
  if [ "$BOOT_COUNT" = "0" ]; then
    echo "  Boot protection: ✅ OK (counter: $BOOT_COUNT)"
  else
    echo "  Boot protection: ⚠️  Counter: $BOOT_COUNT/3"
  fi
else
  echo "  Boot protection: ⚠️  Counter file missing"
fi

echo ""

#################
# Spoofed Properties
#################

echo "━━━ Current Device Properties ━━━"

show_prop() {
  local name="$1"
  local value="$(getprop "$name" 2>/dev/null)"
  if [ -n "$value" ]; then
    printf "  %-45s %s\n" "$name:" "$value"
  fi
}

echo ""
echo "  [Fingerprint]"
show_prop "ro.build.fingerprint"
show_prop "ro.vendor.build.fingerprint"

echo ""
echo "  [Device Info]"
show_prop "ro.product.manufacturer"
show_prop "ro.product.model"
show_prop "ro.product.brand"
show_prop "ro.product.device"
show_prop "ro.product.name"

echo ""
echo "  [Build Info]"
show_prop "ro.build.id"
show_prop "ro.build.type"
show_prop "ro.build.tags"
show_prop "ro.build.version.release"
show_prop "ro.build.version.security_patch"
show_prop "ro.build.version.incremental"

echo ""
echo "  [Security Status]"
show_prop "ro.boot.verifiedbootstate"
show_prop "ro.boot.vbmeta.device_state"
show_prop "ro.boot.flash.locked"
show_prop "ro.boot.veritymode"
show_prop "ro.debuggable"
show_prop "ro.secure"

echo ""

#################
# Zygisk Status
#################

echo "━━━ Zygisk Status ━━━"

ZYGISK_FOUND=0
for mod in "zygisksu" "zygisknext" "rezygisk" "neozygisk"; do
  if [ -d "/data/adb/modules/$mod" ] && [ ! -f "/data/adb/modules/$mod/disable" ]; then
    echo "  ✅ $mod: active"
    ZYGISK_FOUND=1
  fi
done

if [ "$ZYGISK_FOUND" = "0" ]; then
  # Check built-in Zygisk
  if [ "$(magisk --denylist status 2>/dev/null)" = "0" ]; then
    echo "  ✅ Built-in Zygisk: active"
    ZYGISK_FOUND=1
  else
    echo "  ⚠️  No Zygisk implementation detected"
    echo "     Consider installing ZygiskNext or ReZygisk"
  fi
fi

echo ""

#################
# Related Modules
#################

echo "━━━ Related Modules ━━━"

for mod in "tricky_store" "TrickyStore" "shamiko" "playintegrityfix" "PlayIntegrityFork" "lsposed" "zygisknext" "rezygisk"; do
  if [ -d "/data/adb/modules/$mod" ]; then
    if [ -f "/data/adb/modules/$mod/disable" ]; then
      echo "  ⏸️  $mod: disabled"
    else
      echo "  ✅ $mod: active"
    fi
  fi
done

echo ""

#################
# Config Status
#################

echo "━━━ Configuration ━━━"

PERSISTENT="/data/adb/x-integrity"
if [ -f "$PERSISTENT/custom.pif.json" ]; then
  echo "  Config: custom.pif.json (custom fingerprint)"
elif [ -f "$PERSISTENT/pif.json" ]; then
  echo "  Config: pif.json (default fingerprint)"
else
  echo "  Config: ⚠️  No config found!"
fi

if [ -f "/data/adb/x-integrity.log" ]; then
  echo "  Log:    /data/adb/x-integrity.log"
  echo ""
  echo "━━━ Last 10 Log Lines ━━━"
  tail -10 "/data/adb/x-integrity.log"
fi

echo ""

#################
# Recommendations
#################

echo "━━━ Recommendations ━━━"

# Check for common issues
ISSUES=0

if [ "$(getprop ro.build.type)" != "user" ]; then
  echo "  ⚠️  Build type is '$(getprop ro.build.type)' — should be 'user'"
  ISSUES=$((ISSUES + 1))
fi

if [ "$(getprop ro.build.tags)" != "release-keys" ]; then
  echo "  ⚠️  Build tags is '$(getprop ro.build.tags)' — should be 'release-keys'"
  ISSUES=$((ISSUES + 1))
fi

if [ "$(getprop ro.debuggable)" = "1" ]; then
  echo "  ⚠️  Device is debuggable — this may trigger detection"
  ISSUES=$((ISSUES + 1))
fi

if [ "$(getprop ro.boot.verifiedbootstate)" != "green" ]; then
  echo "  ⚠️  Boot state is '$(getprop ro.boot.verifiedbootstate)' — should be 'green'"
  ISSUES=$((ISSUES + 1))
fi

if [ "$ISSUES" = "0" ]; then
  echo "  ✅ No issues detected! Everything looks good."
fi

echo ""
echo "━━━ End Verification ━━━"
echo ""
