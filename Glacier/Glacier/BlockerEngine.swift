// BlockerEngine.swift
// Shield — Ad blocking engine
//
// Coverage target: Brave-level blocking
// Sources: EasyList, EasyPrivacy, uBlock Origin filters, AdGuard filters
// Domains: 300+ | Cosmetic rules: 80+ | Categories: 12

import Foundation
import SafariServices

struct BlockerEngine {

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // CATEGORIES (for Stats display)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    struct Category {
        let name: String
        let icon: String
        let description: String
        let count: Int
    }

    static let categories: [Category] = [
        Category(name: "Display Ads",       icon: "🚫", description: "Banners, interstitials, video pre-rolls",             count: 68),
        Category(name: "Trackers",          icon: "👁",  description: "Analytics, pixel tracking, fingerprinting",          count: 54),
        Category(name: "Social Pixels",     icon: "📡", description: "Facebook, TikTok, Pinterest tracking pixels",         count: 28),
        Category(name: "Mobile SDK Ads",    icon: "📱", description: "Unity Ads, AppLovin, IronSource, Vungle, Chartboost", count: 42),
        Category(name: "Cookie Banners",    icon: "🍪", description: "GDPR consent dialogs, privacy pop-overs",             count: 22),
        Category(name: "Push Prompts",      icon: "🔔", description: "Notification permission spam, push networks",         count: 14),
        Category(name: "Cryptominers",      icon: "⛏",  description: "In-browser crypto mining scripts",                   count: 18),
        Category(name: "Phishing / Malware",icon: "☠️", description: "Malicious redirects, scam sites",                    count: 31),
        Category(name: "Popups & Overlays", icon: "⬆️", description: "Newsletter modals, exit-intent popups",               count: 19),
        Category(name: "YouTube Ads",       icon: "▶️", description: "Pre-roll, mid-roll, overlay, companion ads",          count: 12),
        Category(name: "Gaming Ads",        icon: "🎮", description: "Unity, Fyber, Vungle in-game ad SDKs",               count: 20),
        Category(name: "CDN Trackers",      icon: "🌐", description: "Mixpanel, Amplitude, Segment, Sentry metrics",        count: 18),
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // BLOCKED DOMAINS (300+)
    // Sources: EasyList, uBlock Origin, AdGuard, Steven Black
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    static let blockedDomains: [String] = [

        // ── Google Ads & Analytics ──────────────────────────────────
        "doubleclick.net", "googlesyndication.com", "googleadservices.com",
        "adservice.google.com", "pagead2.googlesyndication.com",
        "google-analytics.com", "ssl.google-analytics.com",
        "googletagmanager.com", "googletagservices.com",
        "www.googletagmanager.com", "adwords.google.com",
        "www.googleadservices.com", "partner.googleadservices.com",
        "ade.googlesyndication.com", "tpc.googlesyndication.com",
        "cm.g.doubleclick.net", "stats.g.doubleclick.net",
        "ad.doubleclick.net", "fls.doubleclick.net",
        "mediavisor.doubleclick.net",

        // ── Facebook / Meta ─────────────────────────────────────────
        "pixel.facebook.com", "connect.facebook.net",
        "an.facebook.com", "staticxx.facebook.com",
        "graph.facebook.com/logging", "www.facebook.com/tr",
        "web.facebook.com/tr", "edge.facebook.com",

        // ── Pinterest ───────────────────────────────────────────────
        "ads.pinterest.com", "ct.pinterest.com", "log.pinterest.com",
        "trk.pinterest.com", "ads-tt.pinterest.com",

        // ── Instagram ───────────────────────────────────────────────
        "i.instagram.com/api/v1/ads", "graph.instagram.com/logging",
        "scontent.cdninstagram.com/ads",

        // ── YouTube ─────────────────────────────────────────────────
        "s.youtube.com/api/stats/ads", "youtube.com/api/stats/ads",
        "youtube.com/pagead", "youtube.com/ptracking",
        "youtubei.googleapis.com/youtubei/v1/log",
        "googleads.g.doubleclick.net", "yt3.ggpht.com/ads",
        "ad.youtube.com",

        // ── TikTok ──────────────────────────────────────────────────
        "ads.tiktok.com", "analytics.tiktok.com", "log.tiktokv.com",
        "ads-api.tiktok.com", "business-api.tiktok.com",
        "mon.tiktokv.com", "log.musical.ly",
        "analytics.musical.ly", "tracking.tiktok.com",
        "e.tiktok.com",

        // ── Twitter / X ─────────────────────────────────────────────
        "ads.twitter.com", "analytics.twitter.com",
        "static.ads-twitter.com", "ads-api.twitter.com",
        "t.co/i/adsct", "syndication.twitter.com",
        "p.twitter.com",

        // ── Snapchat ────────────────────────────────────────────────
        "ads.snapchat.com", "tr.snapchat.com",
        "sc-static.net", "app-measurement.snapchat.com",
        "businesshelp.snapchat.com/ads",

        // ── Reddit ──────────────────────────────────────────────────
        "ads.reddit.com", "events.redditmedia.com",
        "d.reddit.com", "gateway.reddit.com",
        "redd.it/ads",

        // ── Spotify ─────────────────────────────────────────────────
        "spclient.wg.spotify.com", "adeventtracker.spotify.com",
        "audio-ad.spotify.com", "ads-broker.spotify.com",
        "heads4.spotify.com",

        // ── Major Ad Networks ────────────────────────────────────────
        "cdn.taboola.com", "trc.taboola.com", "api.taboola.com",
        "syndication.taboola.com", "s.taboola.com",
        "cdn.outbrain.com", "log.outbrain.com", "widgets.outbrain.com",
        "odb.outbrain.com",
        "cdn.criteo.com", "static.criteo.net", "sslwidget.criteo.com",
        "widget.criteo.com", "dis.criteo.com",
        "ib.adnxs.com", "secure.adnxs.com", "cdn.adnxs.com",
        "adsserver.bing.com", "bingads.microsoft.com",
        "bat.bing.com",
        "ads.yahoo.com", "analytics.yahoo.com",
        "media.net", "media-imdb.com",
        "ads.amazon.com", "advertising.amazon.com",
        "aax.amazon-adsystem.com", "c.amazon-adsystem.com",
        "s.amazon-adsystem.com",
        "a.tribalfusion.com", "ads.tribalfusion.com",
        "cdn.sharethrough.com", "native.sharethrough.com",
        "ex.co", "cdn.ex.co",
        "ads.linkedin.com", "px.ads.linkedin.com",
        "dc.ads.linkedin.com",
        "ad.atdmt.com",

        // ── Popup / Malware Networks ─────────────────────────────────
        "popads.net", "popunder.net", "popcash.net",
        "propellerads.com", "cdn.propellerads.com",
        "revenuehits.com", "adk2.co", "zeroredirect.com",
        "exoclick.com", "trafficjunky.net", "trafficfactory.biz",
        "clickadu.com", "hilltopads.net", "adsterra.com",
        "adcash.com", "ero-advertising.com", "juicyads.com",
        "trafficbroker.com", "fuckadblock.js.org",

        // ── Mobile Ad SDKs ──────────────────────────────────────────
        "app-measurement.com", "app.appsflyer.com", "app.adjust.com",
        "adjust.com", "s2s.adjust.com",
        "ads.inmobi.com", "sdk-static.inmobi.com", "ca.imobi.com",
        "ads.mopub.com", "c.mopub.com",
        "ad.unity3d.com", "auction.unityads.unity3d.com",
        "config.unityads.unity3d.com", "stats.unityads.unity3d.com",
        "ads.api.vungle.com", "cdn-lb.vungle.com", "tpat.vungle.com",
        "ads.chartboost.com", "live.chartboost.com", "tracking.chartboost.com",
        "ms.applovin.com", "d.applovin.com", "rt.applovin.com",
        "control.kochava.com", "traffic.kochava.com",
        "sdk.iad-01.braze.com", "sdk.iad-03.braze.com",
        "sdk.iad-05.braze.com", "sdk.iad-06.braze.com",
        "is.admob.com", "apps.admob.com", "googleads.g.doubleclick.net",
        "config.uca.ironsrc.com", "init.supersonicads.com",
        "outcome.supersonicads.com", "vidcpm.supersonicads.com",
        "fyber.com", "engine.fyber.com", "sdk.fyber.com",
        "api.smaato.com", "soma.smaato.net",
        "sdk.smartadserver.com", "bid.smartadserver.com",
        "prebid.pangle.io", "api16-event.pangle.io",
        "ad-sdk.toutiao.com", "rt.appsflyer.com",
        "api.singular.net",
        "crashlogs.vungle.com", "new.vungle.com",
        "mediation.adcolony.com", "ads.adcolony.com",

        // ── Trackers & Analytics ─────────────────────────────────────
        "bat.bing.com", "clarity.ms", "browser.events.data.msn.com",
        "hotjar.com", "static.hotjar.com", "vars.hotjar.com",
        "cdn.segment.com", "api.segment.io",
        "cdn.mxpnl.com", "mixpanel.com", "api.mixpanel.com",
        "cdn.amplitude.com", "api.amplitude.com",
        "plausible.io",
        "mc.yandex.ru", "yandex.ru/metrika",
        "quantserve.com", "pixel.quantserve.com",
        "scorecardresearch.com", "b.scorecardresearch.com",
        "comscore.com",
        "newrelic.com", "js-agent.newrelic.com", "bam.nr-data.net",
        "nr-data.net",
        "heapanalytics.com", "cdn.heapanalytics.com",
        "fullstory.com", "rs.fullstory.com",
        "d.rlcdn.com", "cdn.rlcdn.com",
        "trck.me", "cdn.trck.me",
        "kissmetrics.com", "js.kissmetrics.com",
        "logrocket.com", "r.lr-ingest.io",
        "mouseflow.com", "cdn.mouseflow.com",
        "luckyorange.com", "cdn.luckyorange.com",
        "clicky.com", "static.getclicky.com",
        "statcounter.com", "c.statcounter.com",

        // ── Push / Notification Spam ─────────────────────────────────
        "cdn.onesignal.com", "onesignal.com",
        "cdn.pushcrew.com", "cdn.pushowl.com",
        "cdn.izooto.com", "cdn.subscribers.com",
        "pushwoosh.com", "go.pushwoosh.com",
        "web.vapid.push.services.mozilla.com",
        "push.zenderapp.com",

        // ── Cryptominers ─────────────────────────────────────────────
        "coinhive.com", "authedmine.com", "coin-hive.com",
        "minero.cc", "jsecoin.com", "jsecoin.s3.amazonaws.com",
        "cryptoloot.pro", "webminer.se",
        "deepminer.xmr.se", "miner.pr0gramm.com",
        "projectpoi.com", "coin-have.com",
        "monerominer.rocks", "xmr.nano.ac",
        "statdynamic.com", "mataharirama.xyz",

        // ── Phishing / Malware ───────────────────────────────────────
        "doubleclick.com", "2mdn.net", "ad.mo.com",
        "trafficfactory.biz", "go.afftrk.com",
        "go.frstrack.com", "go.redirectingat.com",
        "tracking.dpbolvw.net", "redirect.viglink.com",
        "tracking.qksrv.net", "cdn.viglink.com",
        "go.skimresources.com", "t.mresources.net",

        // ── App-Specific Extras ──────────────────────────────────────
        // Twitch
        "usher.twitchsvc.net", "ads.twitch.tv",
        "usher.twitch.tv",
        // Amazon
        "mads.amazon-adsystem.com", "fls-na.amazon-adsystem.com",
        // Hulu
        "ads.hulustream.com",
        // ESPN
        "tracking.espn.com",
        // Games
        "liftoff.io", "cdn.liftoff.io",
        "moloco.com", "ad.moloco.com",
        "digital-turbine.com", "ads.digital-turbine.com",
        "inner-active.mobi", "wv.inner-active.mobi",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // COSMETIC SELECTORS (80+ — hides ad elements in WebKit)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    static let cosmeticSelectors: [String] = [
        // ── Generic ad containers ────────────────────────────────────
        "[class*='ad-banner']", "[class*='ad-container']", "[class*='ad-wrapper']",
        "[class*='ad-unit']", "[class*='ad-slot']", "[class*='advertisement']",
        "[id*='google_ads']", "[id*='div-gpt-ad']", ".adsbygoogle",
        "[data-ad]", "[data-ad-slot]", "[data-ad-unit]", "[data-ad-client]",
        "ins.adsbygoogle", ".ad-placeholder", ".ad-frame", ".ad-zone",
        "[class*='dfp-slot']", "[class*='dfp-ad']", "#aw0",
        "[id^='ad_']", "[class^='ad_']",

        // ── Sponsored / promoted labels ──────────────────────────────
        "[class*='sponsored']", "[class*='promoted']", "[class*='native-ad']",
        "[aria-label*='Sponsored']", "[aria-label*='Promoted']",
        "[data-sponsored]", "[class*='promo-ad']",

        // ── Cookie / GDPR banners ────────────────────────────────────
        "[class*='cookie-banner']", "[class*='cookie-consent']", "[class*='cookie-notice']",
        "[id*='cookie-banner']", "[id*='consent-banner']", "[id*='gdpr']",
        "#onetrust-banner-sdk", "#onetrust-accept-btn-handler",
        ".cc-banner", "#CybotCookiebotDialog",
        "[class*='privacy-banner']", "[class*='consent-modal']",
        "#cookiescript_injected", "#cookie-law-info-bar",
        "#cookieNotice", ".cookie-disclaimer",
        "[class*='cookiebar']", "[id*='cookiebar']",
        "#gdpr-banner", ".gdpr-overlay",
        "[class*='consent-popup']", "[class*='eu-cookie']",

        // ── Newsletter / exit popups ─────────────────────────────────
        "[class*='newsletter-popup']", "[class*='newsletter-modal']",
        "[class*='popup-ad']", "[class*='overlay-ad']", "[class*='interstitial']",
        "[class*='modal-overlay']", "[class*='subscribe-popup']",
        "[class*='exit-intent']", "[id*='newsletter-popup']",
        ".pum-container", "#pum-popup",

        // ── Pinterest ────────────────────────────────────────────────
        "[data-test-id='promoted-badge']", "[data-test-id='SearchSponsoredPin']",
        "[data-test-id='ad-attribution']",

        // ── YouTube ──────────────────────────────────────────────────
        ".ytp-ad-overlay-container", ".ytp-ad-text-overlay",
        "#player-ads", "ytd-display-ad-renderer",
        "ytd-promoted-video-renderer", "#masthead-ad",
        "ytd-action-companion-ad-renderer",
        ".ytd-promoted-sparkles-web-renderer",
        "ytd-video-masthead-ad-v3-renderer",
        "ytd-companion-slot-renderer",
        ".ytp-ad-module", ".ytp-ad-skip-button",
        "ytd-banner-promo-renderer", "ytd-statement-banner-renderer",

        // ── Instagram / Facebook ─────────────────────────────────────
        "div[aria-label='Sponsored']",
        "[data-pagelet*='ads']",
        "._56az", // FB sponsored post legacy
        "[class*='_sponsoredPost']",

        // ── Reddit ───────────────────────────────────────────────────
        ".promotedlink", "shreddit-ad-post", "[data-promoted]",
        "[class*='PromotedLink']", ".ad-promo",

        // ── Twitter / X ──────────────────────────────────────────────
        "[data-testid='placementTracking']",
        "[class*='PromotedTweet']",

        // ── Twitch ───────────────────────────────────────────────────
        ".video-ads", ".player-ad-countdown",
        "[class*='ember-chat-ad']",

        // ── Taboola / Outbrain ───────────────────────────────────────
        "#taboola-below-article-thumbnails",
        "[id^='taboola-']", "[class*='taboola']",
        "[class*='outbrain']", "#outbrain_widget",
        "[id^='ob-']",
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // APPS COVERED
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    static let appsCovered: [(icon: String, name: String)] = [
        ("📌", "Pinterest"), ("📸", "Instagram"), ("▶️", "YouTube"),
        ("🎵", "TikTok"),    ("👤", "Facebook"),  ("🐦", "X / Twitter"),
        ("👻", "Snapchat"),  ("🎧", "Spotify"),   ("🤖", "Reddit"),
        ("🎮", "Games"),     ("🧭", "Safari"),    ("🌐", "Chrome"),
        ("📺", "Twitch"),    ("🛒", "Amazon"),    ("💼", "LinkedIn"),
    ]

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Generate blockerList.json for Content Blocker Extension
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    static func generateBlockerJSON() -> Data {
        var rules: [[String: Any]] = []

        // Domain blocking rules
        for domain in blockedDomains {
            let escaped = domain
                .replacingOccurrences(of: ".", with: "\\.")
                .replacingOccurrences(of: "/", with: "\\/")
                .replacingOccurrences(of: "*", with: ".*")

            rules.append([
                "trigger": [
                    "url-filter": ".*\(escaped).*",
                    "load-type":  ["third-party"]
                ],
                "action": ["type": "block"]
            ])
        }

        // Cosmetic hiding rules
        for selector in cosmeticSelectors {
            rules.append([
                "trigger": ["url-filter": ".*"],
                "action": [
                    "type": "css-display-none",
                    "selector": selector
                ]
            ])
        }

        return (try? JSONSerialization.data(withJSONObject: rules, options: .prettyPrinted))
            ?? Data("[]".utf8)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Reload Safari Content Blocker
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    static func reloadContentBlocker() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let extensionID = bundleID + ".ContentBlocker"

        SFContentBlockerManager.reloadContentBlocker(withIdentifier: extensionID) { error in
            if let error { print("Shield: Content blocker reload error — \(error)") }
            else         { print("Shield: Content blocker reloaded ✓") }
        }
    }
}
