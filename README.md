# harbour-sailfish-horizon (Outlook 365 for Sailfish OS)

A dedicated, isolated Sailfish OS web application container for enterprise **Microsoft 365 / Outlook Web**, optimized for modern **Jolla 2026** tall OLED/notch displays, featuring native Sailfish OS **DBus notifications**, offline auto-reconnect, enterprise passcode privacy, and automated multi-architecture CI/CD packaging.

---

## Complete Feature Matrix

1. **Complete Isolation from Main Browser**:
   - Runs in its own separate process and application sandbox (`harbour-sailfish-horizon`).
   - Dedicated cookie storage, session state, localStorage, and IndexedDB at `~/.local/share/harbour-sailfish-horizon/` and `~/.cache/harbour-sailfish-horizon/`.
   - Your corporate credentials and sessions remain completely isolated from `sailfish-browser`.

2. **Enterprise Passcode / PIN Lock**:
   - Protects confidential email with an in-app Silica keypad PIN screen.
   - Configurable auto-lock timeout (Immediately, 1, 5, 15, or 30 minutes) whenever the app is minimized or backgrounded.

3. **Suppress "Get the App" Upsell Banners**:
   - Injected styling automatically eliminates promotional banners pushing users to download iOS/Android apps, maximizing vertical reading space.

4. **Offline Detection & Auto-Reconnect**:
   - Displays a sleek, non-intrusive status banner when network connectivity drops.
   - Automatically refreshes your inbox as soon as Wi-Fi or cellular data resumes.

5. **Live Unread Email Badge on Active Cover**:
   - Parses incoming email count `(N)` from Outlook and renders an unread counter badge directly on the Sailfish OS home multitasking grid.

6. **External Link Interception**:
   - Clicking links inside emails (e.g. news, Jira, external docs) intercepts the request and launches them in the default **Sailfish Browser** via `Qt.openUrlExternally()`, keeping your Outlook container focused and free of third-party cookies.

7. **System `mailto:` URL Handler**:
   - Registered as a MIME handler for `x-scheme-handler/mailto;`. Tapping an email address anywhere in Sailfish OS launches the app directly into Outlook's compose window.

8. **Fast Account / Tenant Switcher**:
   - Dedicated "Switch / Add Account" action in the Pulley Menu and Settings pointing to `prompt=select_account`, allowing quick switching between corporate tenants or accounts.

9. **Native Bottom Navigation Dock**:
   - ⬅️ **History Back**: Intercepts web navigation before popping the Silica page.
   - ✉️ **Mail**: Instant access to your Outlook inbox.
   - 📅 **Calendar**: Meetings, agendas, and appointments.
   - 👥 **People / Contacts**: Corporate address book and lookup.
   - 🔍 **Search**: Instantly focuses Outlook's internal search bar.

10. **Attachment Download Notifications**:
    - System DBus notification alerts you when attachments are downloaded to `~/Downloads`.

11. **Sailfish Ambiance / Dark Mode Synchronization**:
    - Automatically synchronizes Outlook's theme (`color-scheme: dark | light`) with the active Sailfish OS Ambiance.

12. **Hardware & Bluetooth Keyboard Shortcuts**:
    - `Ctrl + 1`: Mail Inbox
    - `Ctrl + 2`: Calendar
    - `Ctrl + 3`: Contacts (People)
    - `Ctrl + F`: Focus Search
    - `Ctrl + N`: Compose new email / event
    - `Ctrl + R` / `F5`: Reload
    - `Ctrl + ,`: Open Settings
    - `Alt + Left`: History Back

13. **Jolla 2026 Display & Notch Optimization**:
    - Dynamic safe-area padding for camera punch-holes and rounded corners (`Screen.topCutout`, `Screen.bottomCutout`).
    - Viewport styling (`viewport-fit=cover`) ensuring edge-to-edge layout on tall 20:9 / 21:9 displays.
    - Display scaling slider (80% to 150%) for high-DPI displays.

14. **Native Sailfish OS DBus Notifications**:
    - Hooks into the HTML5 `Notification` API in the background.
    - Forwards new messages to `org.freedesktop.Notifications` with lock screen summaries, haptic vibrations, and standard email chimes (`x-nemo-feedback: email_exists`).

15. **Background Systemd Daemon & Timer**:
    - Includes `harbour-sailfish-horizon.service` and `harbour-sailfish-horizon.timer` for persistent background notification keep-alive.

---

## Project Structure

```text
harbour-sailfish-horizon/
├── .github/
│   └── workflows/
│       └── build.yml              # Automated multi-arch RPM builds (aarch64, armv7hl, i486)
├── systemd/
│   ├── harbour-sailfish-horizon.service # Systemd user background keep-alive service
│   └── harbour-sailfish-horizon.timer   # Systemd timer for periodic sync
├── harbour-sailfish-horizon.pro    # qmake project definition (Qt DBus enabled)
├── harbour-sailfish-horizon.desktop# Desktop launcher entry & mailto handler
├── src/
│   ├── main.cpp                   # App bootstrap, daemon support, isolated identity, mailto parser
│   ├── notificationmanager.h      # DBus notification bridge header
│   └── notificationmanager.cpp    # org.freedesktop.Notifications implementation
├── qml/
│   ├── harbour-sailfish-horizon.qml# Main ApplicationWindow with state & PIN lock listener
│   ├── pages/
│   │   ├── MailWebPage.qml        # WebView, dock, offline detection, external link interceptor
│   │   ├── PinLockOverlay.qml     # Silica keypad passcode lock overlay
│   │   └── SettingsPage.qml       # Realm, PIN setup, scaling, ambiance sync, test notification
│   └── cover/
│       └── CoverPage.qml          # Active Multitasking Cover with live unread badge
├── icons/                         # App icons in standard Sailfish OS resolutions
│   ├── 86x86/
│   ├── 108x108/
│   ├── 128x128/
│   ├── 172x172/
│   └── 256x256/
└── rpm/
    └── harbour-sailfish-horizon.spec# RPM packaging spec with Qt5DBus, popups & systemd units
```

---

## How to Build and Deploy

### Automated CI/CD (GitHub Actions)
Push this repository to GitHub or create a git release tag (e.g. `v1.0.0`). The workflow in `.github/workflows/build.yml` will automatically build and publish `.rpm` installation packages for:
* **`aarch64`** (64-bit ARM: Xperia 10 III / IV / V, Jolla 2026 / C2)
* **`armv7hl`** (32-bit ARM: Xperia X, Jolla 1, Jolla C)
* **`i486`** (Sailfish OS Emulator)

### Local Build Using Sailfish OS SDK (`sfdk`)

1. Build for your target architecture:
   ```bash
   sfdk config target=SailfishOS-<version>-armv7hl   # or aarch64 / i486
   sfdk build
   ```

2. Package the RPM:
   ```bash
   sfdk package
   ```

3. Deploy to device:
   ```bash
   sfdk deploy --sdk
   ```
