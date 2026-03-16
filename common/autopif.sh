#!/system/bin/sh
# X-Integrity — Auto PIF Generator
# Downloads and generates a working pif.json fingerprint config
# Run via: sh /data/adb/modules/x-integrity/common/autopif.sh

PERSISTENT="/data/adb/x-integrity"
MODDIR="/data/adb/modules/x-integrity"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║    X-Integrity — Auto PIF Generator  ║"
echo "╚══════════════════════════════════════╝"
echo ""

#################
# Fingerprint Database
# These are known working fingerprints for certified devices
# Update this list periodically
#################

generate_pixel_fp() {
  # Pixel 8 Pro (husky) — Android 14
  cat > "$PERSISTENT/pif.json" << 'FPEOF'
{
  "MANUFACTURER": "Google",
  "MODEL": "Pixel 8 Pro",
  "FINGERPRINT": "google/husky/husky:14/AP4A.250205.004/12716org:user/release-keys",
  "BRAND": "google",
  "PRODUCT": "husky",
  "DEVICE": "husky",
  "RELEASE": "14",
  "ID": "AP4A.250205.004",
  "INCREMENTAL": "12716org",
  "TYPE": "user",
  "TAGS": "release-keys",
  "SECURITY_PATCH": "2025-02-05",
  "DEVICE_INITIAL_SDK_INT": "34",
  "spoofBuild": true,
  "spoofProps": true,
  "spoofProvider": true,
  "spoofSignature": false,
  "verboseLogs": 0
}
FPEOF
}

generate_pixel7_fp() {
  # Pixel 7 (panther) — Android 14
  cat > "$PERSISTENT/pif.json" << 'FPEOF'
{
  "MANUFACTURER": "Google",
  "MODEL": "Pixel 7",
  "FINGERPRINT": "google/panther/panther:14/AP4A.250205.004/12716org:user/release-keys",
  "BRAND": "google",
  "PRODUCT": "panther",
  "DEVICE": "panther",
  "RELEASE": "14",
  "ID": "AP4A.250205.004",
  "INCREMENTAL": "12716org",
  "TYPE": "user",
  "TAGS": "release-keys",
  "SECURITY_PATCH": "2025-02-05",
  "DEVICE_INITIAL_SDK_INT": "33",
  "spoofBuild": true,
  "spoofProps": true,
  "spoofProvider": true,
  "spoofSignature": false,
  "verboseLogs": 0
}
FPEOF
}

generate_pixel6a_fp() {
  # Pixel 6a (bluejay) — Android 14
  cat > "$PERSISTENT/pif.json" << 'FPEOF'
{
  "MANUFACTURER": "Google",
  "MODEL": "Pixel 6a",
  "FINGERPRINT": "google/bluejay/bluejay:14/AP4A.250205.004/12716org:user/release-keys",
  "BRAND": "google",
  "PRODUCT": "bluejay",
  "DEVICE": "bluejay",
  "RELEASE": "14",
  "ID": "AP4A.250205.004",
  "INCREMENTAL": "12716org",
  "TYPE": "user",
  "TAGS": "release-keys",
  "SECURITY_PATCH": "2025-02-05",
  "DEVICE_INITIAL_SDK_INT": "32",
  "spoofBuild": true,
  "spoofProps": true,
  "spoofProvider": true,
  "spoofSignature": false,
  "verboseLogs": 0
}
FPEOF
}

#################
# Selection Menu
#################

echo "Select a fingerprint profile:"
echo ""
echo "  1) Google Pixel 8 Pro (recommended)"
echo "  2) Google Pixel 7"
echo "  3) Google Pixel 6a"
echo ""
echo -n "Choice [1-3]: "
read choice

case "$choice" in
  1|"")
    echo ""
    echo "→ Generating Pixel 8 Pro fingerprint..."
    generate_pixel_fp
    ;;
  2)
    echo ""
    echo "→ Generating Pixel 7 fingerprint..."
    generate_pixel7_fp
    ;;
  3)
    echo ""
    echo "→ Generating Pixel 6a fingerprint..."
    generate_pixel6a_fp
    ;;
  *)
    echo "Invalid choice. Using default (Pixel 8 Pro)..."
    generate_pixel_fp
    ;;
esac

echo ""
echo "✅ pif.json generated at: $PERSISTENT/pif.json"
echo ""
echo "📋 Generated fingerprint:"
cat "$PERSISTENT/pif.json"
echo ""
echo ""
echo "📌 Next steps:"
echo "   1. Reboot your device"
echo "   2. Check Play Integrity API Checker"
echo ""
echo "💡 Tip: If this fingerprint gets banned, run this"
echo "   script again and choose a different profile."
echo ""

# Mark GMS cache for clearing on next boot
rm -f "$PERSISTENT/gms_cleared" 2>/dev/null
echo "   GMS cache will be cleared on next boot."
echo ""
