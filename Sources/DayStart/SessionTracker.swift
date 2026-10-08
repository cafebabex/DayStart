import AppKit
import Foundation

@MainActor
final class SessionTracker: ObservableObject {
    static let shared = SessionTracker()

    @Published private(set) var todaySummary: DaySummary
    @Published private(set) var recentSummaries: [DaySummary] = []
    @Published private(set) var lastEvent: SessionEvent?

    private var observers: [NSObjectProtocol] = []
    private var workspaceObservers: [NSObjectProtocol] = []
    private var refreshTimer: Timer?

    private init() {
        todaySummary = EventStore.shared.summary()
        recentSummaries = EventStore.shared.recentSummaries()
    }

    func start() {
        stop()
        registerNotifications()

        // If app launches while session is already unlocked, record an unlock
        // only when there is no open session today yet.
        bootstrapIfNeeded()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        refresh()
    }

    func stop() {
        let center = DistributedNotificationCenter.default()
        observers.forEach { center.removeObserver($0) }
        observers.removeAll()

        let workspace = NSWorkspace.shared.notificationCenter
        workspaceObservers.forEach { workspace.removeObserver($0) }
        workspaceObservers.removeAll()

        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func refresh() {
        todaySummary = EventStore.shared.summary()
        recentSummaries = EventStore.shared.recentSummaries()
    }

    private func bootstrapIfNeeded() {
        let summary = EventStore.shared.summary()
        // No unlock recorded today, and screen is presumably unlocked (we're running UI).
        if summary.firstUnlock == nil {
            record(.unlock)
        }
    }

    private func registerNotifications() {
        let dist = DistributedNotificationCenter.default()

        observers.append(dist.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.record(.lock) }
        })

        observers.append(dist.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.record(.unlock) }
        })

        let workspace = NSWorkspace.shared.notificationCenter

        workspaceObservers.append(workspace.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.record(.sleep) }
        })

        workspaceObservers.append(workspace.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.record(.wake) }
        })

        workspaceObservers.append(workspace.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.record(.sleep) }
        })

        workspaceObservers.append(workspace.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.record(.wake) }
        })
    }

    private func record(_ type: SessionEventType) {
        if let event = EventStore.shared.append(type) {
            lastEvent = event
        }
        refresh()
    }
}
