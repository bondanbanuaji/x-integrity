# X-Integrity — Play Integrity Fix for All Devices

<p align="center">
  <strong>🛡️ All-in-One Magisk Module to fix Play Integrity on rooted devices & custom ROMs</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-v1.0.0-blue" alt="Version">
  <img src="https://img.shields.io/badge/Magisk-24.0+-green" alt="Magisk">
  <img src="https://img.shields.io/badge/Android-10--15+-orange" alt="Android">
  <img src="https://img.shields.io/badge/License-GPL--3.0-red" alt="License">
</p>

<p align="center">
  <br>
  <a href="https://github.com/boba/x-integrity/releases/latest/download/x-integrity-v1.0.0.zip">
    <img src="https://img.shields.io/badge/⬇_DOWNLOAD_HERE-x--integrity--v1.0.0.zip-0078D4?style=for-the-badge&logo=android&logoColor=white" alt="Download">
  </a>
  <br><br>
  <i>Click the button above to download the module directly</i>
</p>

---

## ✨ Features

| Feature | Status |
|---|---|
| Pass **MEETS_BASIC_INTEGRITY** | ✅ |
| Pass **MEETS_DEVICE_INTEGRITY** | ✅ |
| Pass **MEETS_STRONG_INTEGRITY** | ✅* |
| Anti-Bootloop Protection | ✅ |
| 100% Systemless (no /system modification) | ✅ |
| Auto Fingerprint Spoofing | ✅ |
| Build Prop Spoofing | ✅ |
| Root Indicator Hiding | ✅ |
| GMS Cache Auto-Clear | ✅ |
| Safe Mode Detection | ✅ |
| Clean Uninstall | ✅ |

> \* **STRONG_INTEGRITY** requires **Tricky Store** + a valid keybox

## 🔧 Compatibility

- **Magisk**: v24.0+ (including Magisk Alpha)
- **KitsuneMask**: ✅ Fully compatible
- **Magisk Forks**: All forks that support standard Magisk modules
- **Android**: 10, 11, 12, 12L, 13, 14, 15+
- **Architecture**: ARM64, ARM, x86_64, x86
- **Devices**: All devices (Samsung, Xiaomi, OPPO, Realme, Infinix, etc.)
- **ROM**: Stock ROM, Custom ROM (LineageOS, Evolution X, PixelOS, etc.)

## 📦 Installation

### Method 1: Via Magisk Manager / KitsuneMask

1. Download `x-integrity-v1.0.0.zip` (click the **DOWNLOAD HERE** button above ☝️)
2. Open **Magisk Manager** or **KitsuneMask**
3. Tap **Modules** → **Install from Storage**
4. Select the downloaded ZIP file
5. Wait for the installation to complete
6. **Reboot** your device

### Method 2: Via Recovery (TWRP)

1. Boot into recovery mode
2. Select "Install"
3. Select `x-integrity-v1.0.0.zip`
4. Swipe to flash
5. Reboot system

## ⚙️ Configuration

### Config File Locations

```
/data/adb/x-integrity/
├── pif.json           # Fingerprint config (auto-generated)
├── custom.pif.json    # Custom fingerprint (optional, takes priority)
├── boot_count         # Boot counter (anti-bootloop)
└── gms_cleared        # GMS cache cleared flag
```

### Change Fingerprint

**Automatic (Recommended):**
```bash
# Run via Terminal/Termux (with root)
su -c "sh /data/adb/modules/x-integrity/common/autopif.sh"
```

**Manual:**
1. Edit `/data/adb/x-integrity/custom.pif.json`
2. Fill in all fields with the desired fingerprint values
3. Reboot device

### Check Status

```bash
# Run via Terminal/Termux (with root)
su -c "sh /data/adb/modules/x-integrity/common/verify.sh"
```

## 🛡️ Safety

### Anti-Bootloop Protection

This module will NOT cause bootloops because:

1. **Boot Counter**: If the device fails to boot 3 times in a row, the module automatically disables itself
2. **Safe Mode Detection**: Module is inactive during safe mode
3. **100% Systemless**: Does not modify any files in `/system` — module can always be removed via Magisk
4. **Clean Uninstall**: All changes are restored when the module is uninstalled

### Anti-Brick

- Module does NOT flash firmware/kernel
- Module does NOT modify the partition table
- Module does NOT modify the bootloader
- Only modifies properties in memory (RAM), not on storage

## 🔨 Troubleshooting

### DEVICE_INTEGRITY still ❌

1. Make sure Zygisk is active (install ZygiskNext/ReZygisk)
2. Run `autopif.sh` to generate a new fingerprint
3. Clear Google Play Services data manually
4. Reboot and check again

### STRONG_INTEGRITY still ❌

1. Install **Tricky Store** module
2. Install **Integrity Box** or obtain a valid keybox
3. Make sure the security patch date in `pif.json` matches the fingerprint
4. Reboot and check again

### Module Auto-Disabled

If the module was automatically disabled (bootloop protection), do the following:
```bash
# Reset boot counter
su -c "echo 0 > /data/adb/x-integrity/boot_count"
# Remove disable flag
su -c "rm /data/adb/modules/x-integrity/disable"
# Reboot
reboot
```

### Log File

```bash
# View latest logs
su -c "cat /data/adb/x-integrity.log"
```

## 📂 Module Structure

```
x-integrity/
├── META-INF/
│   └── com/google/android/
│       ├── update-binary      # Magisk installer
│       └── updater-script     # Module identifier
├── common/
│   ├── autopif.sh             # Auto fingerprint generator
│   └── verify.sh              # Status verification tool
├── module.prop                # Module metadata
├── customize.sh               # Installation script
├── post-fs-data.sh            # Early boot prop spoofing
├── service.sh                 # Late boot service
├── uninstall.sh               # Clean uninstall script
├── system.prop                # Persistent prop overrides
├── pif.json                   # Default fingerprint config
├── custom.pif.json            # Custom fingerprint template
└── README.md                  # Documentation (this file)
```

## 🤝 Credits

- Inspired by [PlayIntegrityFork](https://github.com/chiteroman/PlayIntegrityFork)
- Built upon Magisk Module template by [topjohnwu](https://github.com/topjohnwu)
- Fingerprint research & community contributions

## 📜 License

This project is licensed under the GNU General Public License v3.0

---

<p align="center">Made with ❤️ by boba</p>
