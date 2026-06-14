import SwiftUI
import UIKit
import UserNotifications

#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
@MainActor
struct DraftedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appModel = AppModel.bootstrap()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appModel)
                .preferredColorScheme(.dark)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseBootstrap.configureIfPossible()
        UNUserNotificationCenter.current().delegate = self
        return true
    }
}

enum FirebaseBootstrap {
    static var hasGoogleServiceInfo: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }

    static func configureIfPossible() {
        guard hasGoogleServiceInfo else { return }

        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif
    }
}
