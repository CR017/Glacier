# Shield — iOS Ad Blocker
### Brave-level blocking. Second Society design.

---

## What Shield does

Shield blocks ads and trackers across your **entire iPhone** — not just Safari. Pinterest, games, YouTube, TikTok, Instagram, Reddit, Spotify, and every other app.

It uses three layers, stacked like Brave does:

| Layer | What it blocks | Where it works |
|---|---|---|
| **DNS Tunnel** (VPN) | All ad/tracker domains before connection | Every app system-wide |
| **AdGuard DNS** | 300,000+ domains at resolver level | Every app system-wide |
| **Safari Content Blocker** | URL rules + CSS cosmetic hiding | Safari & WKWebView apps |

---

## Xcode project structure

```
Shield/                          ← Main app target
  ShieldApp.swift                ← @main entry, VPNManager
  ContentView.swift              ← Main UI (Second Society design)
  StatsView.swift                ← Stats sheet
  SetupGuideView.swift           ← Setup guide sheet
  BlockerEngine.swift            ← 300+ domains, 80+ CSS rules
  Theme.swift                    ← Design tokens (DS.*)

ShieldContentBlocker/            ← Content Blocker Extension target
  ContentBlockerHandler.swift    ← Hands blockerList.json to WebKit
  blockerList.json               ← Pre-compiled blocking rules

ShieldPacketTunnel/              ← Network Extension target
  PacketTunnelProvider.swift     ← Local VPN + DNS routing
```

---

## Xcode setup (step by step)

### 1. Create the project
- New Project → App
- Product Name: `Shield`
- Bundle ID: `com.shield.app`
- Language: Swift, Interface: SwiftUI

### 2. Add files to main target
Copy all `.swift` files into the main target (except `PacketTunnelProvider.swift` and `ContentBlockerHandler.swift`).

### 3. Content Blocker Extension
- File → New → Target → **Content Blocker Extension**
- Name: `ShieldContentBlocker`
- Bundle ID: `com.shield.app.ContentBlocker`
- Replace the generated handler with `ContentBlockerHandler.swift`
- Add `blockerList.json` to this target's bundle resources

### 4. Packet Tunnel Extension
- File → New → Target → **Network Extension**
- Provider type: **Packet Tunnel**
- Name: `ShieldPacketTunnel`
- Bundle ID: `com.shield.app.PacketTunnel`
- Replace generated file with `PacketTunnelProvider.swift`

### 5. Entitlements

**Main app** (`Shield.entitlements`):
```xml
<key>com.apple.developer.networking.networkextension</key>
<array>
    <string>packet-tunnel-provider</string>
</array>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.shield.app</string>
</array>
```

**PacketTunnel target** (`ShieldPacketTunnel.entitlements`):
```xml
<key>com.apple.developer.networking.networkextension</key>
<array>
    <string>packet-tunnel-provider</string>
</array>
```

### 6. App Groups (for dynamic rule sharing)
- In Apple Developer portal: create App Group `group.com.shield.app`
- Add it to both the main app and ContentBlocker targets in Xcode → Signing & Capabilities → App Groups

### 7. Capabilities in Xcode
Main app target → Signing & Capabilities:
- ✅ Network Extensions
- ✅ App Groups (`group.com.shield.app`)

---

## How blocking works (technical)

### DNS Layer (primary — blocks 95% of ads)
When Shield is ON, it creates a local VPN tunnel on the device. All DNS queries from every app go through this tunnel, which routes them to **AdGuard's DNS servers** (`94.140.14.14`).

AdGuard DNS maintains a blocklist of 300,000+ ad/tracker domains. When any app (Pinterest, a game, YouTube) tries to connect to an ad domain, the DNS resolver returns `NXDOMAIN` — the connection never happens.

This is identical to what Brave does on iOS.

### Content Blocker (Safari layer)
For Safari and WKWebView-based apps, Shield's Content Blocker Extension provides:
- **URL blocking rules**: block requests to ad domains before they load
- **CSS cosmetic rules**: hide sponsored posts, cookie banners, newsletter popups
- **80+ selectors**: covering YouTube, Reddit, Pinterest, Facebook, Twitter and generic patterns

### Packet Filter (tertiary — catches stragglers)
The PacketTunnelProvider also inspects raw packets for known ad domains as a final safety net.

---

## AdGuard DNS servers

| Server | Address | Purpose |
|---|---|---|
| Primary | `94.140.14.14` | Blocks ads + trackers |
| Secondary | `94.140.15.15` | Fallback |
| DoH | `https://dns.adguard-dns.com/dns-query` | Encrypted variant |

---

## Design tokens (`Theme.swift`)

| Token | Value | Use |
|---|---|---|
| `DS.chalk` | `#F0EDE6` | Background |
| `DS.ink` | `#1A1A18` | Primary text |
| `DS.crimson` | `#B01E28` | Accent, active state |
| `DS.stone` | `#8A8680` | Muted text, labels |
| `DS.paper` | `#E6E2DA` | Card surfaces |

Typography:
- **Display**: `.system(design: .serif, weight: .black)` — editorial headlines
- **Body**: `.system(design: .default)` — UI text
- **Mono**: `.system(design: .monospaced)` — stats, numbers, DNS addresses

---

## Why no Pac-Man

The previous design used Pac-Man as the central metaphor. This version replaces it entirely with a shield glyph (`shield.fill` / `shield` SF Symbol) and an editorial typographic approach inspired by Second Society's design language:
- Large bold serif headlines
- Crimson as the sole accent color
- Chalk cream background
- Hairline dividers and generous whitespace
- The word "Shield" and the state ("on." / "off.") do the emotional work the mascot previously did

---

## App Store notes

- Requires a **paid Apple Developer account** ($99/year)
- Network Extensions require **explicit approval** from Apple for App Store distribution
- When submitting, explain in the review notes that Shield uses NEPacketTunnelProvider to route DNS through privacy-respecting resolvers (AdGuard), not to intercept user traffic
- The Content Blocker extension has no such restrictions and can be submitted freely
