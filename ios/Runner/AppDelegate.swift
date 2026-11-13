import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Banner taps often arrive before the Flutter engine exists.
  private static var pushChannel: FlutterMethodChannel?
  private static var pendingNotificationTap: [String: String]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    AgentPushPermission.requestIfNeeded()
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    let pushChannel = FlutterMethodChannel(
      name: "mangoliving/push",
      binaryMessenger: messenger
    )
    Self.pushChannel = pushChannel
    pushChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "takeNotificationTap":
        let pending = Self.pendingNotificationTap
        Self.pendingNotificationTap = nil
        result(pending)
      case "notificationStatus":
        AgentPushPermission.currentStatus { result($0) }
      case "requestNotificationPermission":
        AgentPushPermission.requestOnMain { result($0) }
      case "openNotificationSettings":
        AgentPushPermission.openSettings()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Firebase leaves the notification-center delegate on FlutterAppDelegate, and
  /// that forward is a no-op until plugins are registered — which is after a
  /// cold-start tap. Capture the payload here, then forward.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let payload = Self.tapPayload(from: response.notification.request.content.userInfo)
    if !payload.isEmpty {
      Self.pendingNotificationTap = payload
      Self.pushChannel?.invokeMethod("onNotificationTap", arguments: payload)
    }

    let once = Once()
    let finish: () -> Void = {
      once.run(completionHandler)
    }
    super.userNotificationCenter(
      center,
      didReceive: response,
      withCompletionHandler: finish
    )
    DispatchQueue.main.async(execute: finish)
  }

  private static func tapPayload(from userInfo: [AnyHashable: Any]) -> [String: String] {
    var payload: [String: String] = [:]
    for (key, value) in userInfo {
      guard let name = key as? String else { continue }
      if let text = value as? String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
          payload[name] = trimmed
        }
      } else if let number = value as? NSNumber {
        payload[name] = number.stringValue
      }
    }
    return payload
  }
}

/// Shows the iOS notification prompt. The system dialog only appears when
/// `requestAuthorization` runs on the main thread after the window is visible.
enum AgentPushPermission {
  private static var requestInFlight = false

  /// Registers for pushes only when the user has already allowed them.
  /// The Allow dialog itself is requested later, once Home is visible.
  static func requestIfNeeded() {
    currentStatus { name in
      guard name == "authorized" || name == "provisional" else { return }
      UIApplication.shared.registerForRemoteNotifications()
    }
  }

  static func currentStatus(completion: @escaping (String) -> Void) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      let name = statusName(settings.authorizationStatus)
      DispatchQueue.main.async {
        completion(name)
      }
    }
  }

  static func requestOnMain(completion: ((String) -> Void)?) {
    DispatchQueue.main.async {
      let center = UNUserNotificationCenter.current()
      center.getNotificationSettings { settings in
        let name = statusName(settings.authorizationStatus)
        DispatchQueue.main.async {
          if settings.authorizationStatus != .notDetermined {
            if name == "authorized" || name == "provisional" {
              UIApplication.shared.registerForRemoteNotifications()
            }
            completion?(name)
            return
          }
          if requestInFlight {
            completion?("notDetermined")
            return
          }
          requestInFlight = true
          center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
              requestInFlight = false
              if granted {
                UIApplication.shared.registerForRemoteNotifications()
              }
              completion?(granted ? "authorized" : "denied")
            }
          }
        }
      }
    }
  }

  static func openSettings() {
    DispatchQueue.main.async {
      let urlString: String
      if #available(iOS 16.0, *) {
        urlString = UIApplication.openNotificationSettingsURLString
      } else {
        urlString = UIApplication.openSettingsURLString
      }
      guard let url = URL(string: urlString) else { return }
      UIApplication.shared.open(url)
    }
  }

  private static func statusName(_ status: UNAuthorizationStatus) -> String {
    switch status {
    case .authorized, .ephemeral:
      return "authorized"
    case .provisional:
      return "provisional"
    case .denied:
      return "denied"
    default:
      return "notDetermined"
    }
  }
}

private final class Once {
  private var done = false

  func run(_ body: () -> Void) {
    if done { return }
    done = true
    body()
  }
}

