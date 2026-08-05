import UIKit
import UserNotifications
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

final class FootlightSignalHub: NSObject {

    static let shared = FootlightSignalHub()

    private static let footlight_tokenAccount = "fl_ft"

    private var footlight_pendingMessage: [AnyHashable: Any]?

    func footlight_rememberMessage(_ userInfo: [AnyHashable: Any]) {
        footlight_pendingMessage = userInfo
    }

    func footlight_takePendingMessage() -> [AnyHashable: Any]? {
        defer { footlight_pendingMessage = nil }
        return footlight_pendingMessage
    }

    override init() {
        super.init()
#if canImport(FirebaseMessaging)
        Messaging.messaging().delegate = self
#endif
    }

    func footlight_fetchToken() async -> String? {
#if canImport(FirebaseMessaging)
        do {
            let token = try await Messaging.messaging().token()
            footlight_persistToken(token)
            return token
        } catch {
            return footlight_cachedToken()
        }
#else
        return footlight_cachedToken()
#endif
    }

    private func footlight_cachedToken() -> String? {
        if let current = FootlightInkVault.footlight_read(account: Self.footlight_tokenAccount) { return current }
        if let legacy = FootlightInkVault.footlight_read(account: "fcm_token") {
            try? FootlightInkVault.footlight_store(legacy, account: Self.footlight_tokenAccount)
            FootlightInkVault.footlight_remove(account: "fcm_token")
            return legacy
        }
        return nil
    }

    private func footlight_persistToken(_ token: String) {
        try? FootlightInkVault.footlight_store(token, account: Self.footlight_tokenAccount)
    }

    func footlight_ensureAuthorization() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            return settings.authorizationStatus
        }
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        return granted ? .authorized : .denied
    }

    func footlight_openSystemSettings() async {
        await MainActor.run {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }
    }

    func footlight_registerAndReport() async {
        let status = await footlight_ensureAuthorization()
        let accepted = (status == .authorized)

        if accepted {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }

        let token = await footlight_fetchToken()

        let tokenField: String
        if !accepted {
            tokenField = "NOT_AUTH"
        } else if let token {
            tokenField = token
        } else {
            tokenField = "NO_TOKEN"
        }

        let payload: [String: Any] = [
            "external_id": FootlightCueConfig.footlight_externalID(),
            "app_id": FootlightCueConfig.footlight_appID,
            "action": "fcm_token",
            "is_accepted": accepted,
            "fcm_token": tokenField
        ]
        FootlightGateClient.footlight_pushEvent(payload)
    }
}

#if canImport(FirebaseMessaging)
extension FootlightSignalHub: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        try? FootlightInkVault.footlight_store(fcmToken, account: "fl_ft")
    }
}
#endif
