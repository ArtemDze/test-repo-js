import Foundation
import UIKit

enum FootlightCueConfig {
    static let footlight_appID: String = footlight_readInfo("APP_ID", fallback: "id6797531429")
    static let footlight_firebaseFunctionName: String = footlight_readInfo("FIREBASE_FUNCTION", fallback: "JestoraPatternStudio")
    static let footlight_firebaseRegion: String = footlight_readInfo("FIREBASE_REGION", fallback: "europe-central2")
    static let footlight_debugTestURL: String = footlight_readInfo("DEBUG_TEST_URL", fallback: "https://tds.openapp.app/admin/test/1")

    private static let footlight_xidKey = "fl_xid"
    private static let footlight_legacyXidKey = "footlight_cue_external_id"

    static func footlight_externalID() -> String {
        if let existing = UserDefaults.standard.string(forKey: footlight_xidKey) {
            return existing
        }
        if let legacy = UserDefaults.standard.string(forKey: footlight_legacyXidKey) {
            UserDefaults.standard.set(legacy, forKey: footlight_xidKey)
            UserDefaults.standard.removeObject(forKey: footlight_legacyXidKey)
            return legacy
        }
        let minted = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(minted, forKey: footlight_xidKey)
        return minted
    }

    static func footlight_regionCode() -> String {
        if #available(iOS 16, *) {
            return Locale.current.region?.identifier ?? "unknown"
        }
        return Locale.current.regionCode ?? "unknown"
    }

    private static func footlight_readInfo(_ key: String, fallback: String) -> String {
        let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String
        guard let raw, !raw.isEmpty, raw != "$(\(key))" else { return fallback }
        return raw
    }
}
