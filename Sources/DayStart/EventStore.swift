import Foundation

final class EventStore {
    static let shared = EventStore()

    private let queue = DispatchQueue(label: "local.daystart.store")
    private let fileURL: URL
    private var events: [SessionEvent] = []

    private init() {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("DayStart", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        fileURL = dir.appendingPathComponent("events.json")
        events = Self.load(from: fileURL)
    }

    func allEvents() -> [SessionEvent] {
        queue.sync { events }
    }

    @discardableResult
    func append(_ type: SessionEventType, at date: Date = Date()) -> SessionEvent? {
        queue.sync {
            // Avoid noisy duplicates within 2 seconds of the same type.
            if let last = events.last,
               last.type == type,
               abs(last.timestamp.timeIntervalSince(date)) < 2 {
                return last
            }
            let event = SessionEvent(type: type, timestamp: date)
            events.append(event)
            events.sort { $0.timestamp < $1.timestamp }
            Self.save(events, to: fileURL)
            return event
        }
    }

    func summary(for day: Date = Date(), calendar: Calendar = .current) -> DaySummary {
        let dayEvents = queue.sync {
            events.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
                .sorted { $0.timestamp < $1.timestamp }
        }
        return Self.buildSummary(day: calendar.startOfDay(for: day), events: dayEvents, now: Date())
    }

    func recentSummaries(days: Int = 14, calendar: Calendar = .current) -> [DaySummary] {
        let today = calendar.startOfDay(for: Date())
        return (0..<days).compactMap { offset -> DaySummary? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let summary = summary(for: day, calendar: calendar)
            if summary.events.isEmpty && offset > 0 { return nil }
            return summary
        }
    }

    static func buildSummary(day: Date, events: [SessionEvent], now: Date) -> DaySummary {
        let unlocks = events.filter { $0.type == .unlock || $0.type == .wake }
        let locks = events.filter { $0.type == .lock || $0.type == .sleep }

        let firstUnlock = unlocks.first?.timestamp
        let lastLock = locks.last?.timestamp

        var active: TimeInterval = 0
        var openAt: Date?

        for event in events {
            switch event.type {
            case .unlock, .wake:
                if openAt == nil {
                    openAt = event.timestamp
                }
            case .lock, .sleep:
                if let start = openAt {
                    active += max(0, event.timestamp.timeIntervalSince(start))
                    openAt = nil
                }
            }
        }

        if let start = openAt, Calendar.current.isDateInToday(day) {
            active += max(0, now.timeIntervalSince(start))
        }

        return DaySummary(
            date: day,
            firstUnlock: firstUnlock,
            lastLock: lastLock,
            unlockCount: unlocks.count,
            activeSeconds: active,
            events: events
        )
    }

    private static func load(from url: URL) -> [SessionEvent] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([SessionEvent].self, from: data)) ?? []
    }

    private static func save(_ events: [SessionEvent], to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(events) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
