import UIKit
import UserNotifications
import WebKit
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

extension Notification.Name {
    static let footlightInboundURL = Notification.Name("footlight.cue.inboundURL")
}

final class FootlightStageBootstrap: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
#if canImport(FirebaseCore)
        FirebaseApp.configure()
#endif
        _ = FootlightSignalHub.shared

        UNUserNotificationCenter.current().delegate = self

        URLCache.shared = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 150 * 1024 * 1024
        )

        FootlightPlateRuntime.footlight_prime(with: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            FootlightPlateRuntime.footlight_dropStandby()
        }

        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
#if canImport(FirebaseMessaging)
        Messaging.messaging().apnsToken = deviceToken
#endif
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
}

extension FootlightStageBootstrap: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        FootlightSignalHub.shared.footlight_rememberMessage(
            response.notification.request.content.userInfo
        )
        completionHandler()
    }
}
