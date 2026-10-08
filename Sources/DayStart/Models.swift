import Foundation

enum SessionEventType: String, Codable, CaseIterable {
    case unlock
    case lock
    case wake
    case sleep
}

struct SessionEvent: Codable, Identifiable, Equatable {
    let id: UUID
    let type: SessionEventType
    let timestamp: Date

    init(id: UUID = UUID(), type: SessionEventType, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
    }
}

struct DaySummary: Identifiable, Equatable {
    let date: Date
    let firstUnlock: Date?
    let lastLock: Date?
    let unlockCount: Int
    let activeSeconds: TimeInterval
    let events: [SessionEvent]

    var id: Date { date }

    var activeDurationText: String {
        Self.formatDuration(activeSeconds)
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours) 小时 \(minutes) 分"
        }
        return "\(minutes) 分"
    }
}
