import AppKit
import SwiftUI

@main
struct DayStartApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var tracker = SessionTracker.shared

    var body: some Scene {
        MenuBarExtra {
            ContentView(tracker: tracker)
        } label: {
            Label(menuTitle, systemImage: "clock")
        }
        .menuBarExtraStyle(.window)
    }

    private var menuTitle: String {
        if let first = tracker.todaySummary.firstUnlock {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return f.string(from: first)
        }
        return "DayStart"
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        SessionTracker.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        SessionTracker.shared.stop()
    }
}
