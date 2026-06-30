// ContentBlockerHandler.swift
// Shield — Content Blocker Extension target
//
// ─────────────────────────────────────────────────────────────
// TARGET SETUP IN XCODE:
//   File → New → Target → Content Blocker Extension
//   Name: ShieldContentBlocker
//   Bundle ID: com.shield.app.ContentBlocker
//
// This handler loads blockerList.json and passes it to WebKit.
// WebKit compiles it into native bytecode for zero-overhead
// blocking in Safari and all WKWebView-based apps.
//
// RULE LIMIT: Apple allows up to 150,000 rules per extension.
// Shield's ruleset is well within that limit.
// ─────────────────────────────────────────────────────────────

import Foundation
import UniformTypeIdentifiers

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {

        // Priority 1: load from shared App Group container
        // (allows the main app to push updated rules dynamically)
        let groupID = "group.com.shield.app"
        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupID
        ) {
            let dynamicURL = containerURL.appendingPathComponent("blockerList.json")
            if FileManager.default.fileExists(atPath: dynamicURL.path),
               let attachment = NSItemProvider(contentsOf: dynamicURL) {
                let item = NSExtensionItem()
                item.attachments = [attachment]
                context.completeRequest(returningItems: [item], completionHandler: nil)
                return
            }
        }

        // Priority 2: load bundled blockerList.json
        if let bundleURL = Bundle.main.url(forResource: "blockerList", withExtension: "json"),
           let attachment = NSItemProvider(contentsOf: bundleURL) {
            let item = NSExtensionItem()
            item.attachments = [attachment]
            context.completeRequest(returningItems: [item], completionHandler: nil)
            return
        }

        // Fallback: empty rules (blocks nothing — should never reach here)
        let empty = "[]".data(using: .utf8)!
        let attachment = NSItemProvider(
            item: empty as NSSecureCoding,
            typeIdentifier: UTType.json.identifier
        )
        let item = NSExtensionItem()
        item.attachments = [attachment]
        context.completeRequest(returningItems: [item], completionHandler: nil)
    }
}
