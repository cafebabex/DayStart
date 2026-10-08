import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var tracker: SessionTracker
    @State private var launchAtLogin = LoginItemManager.isEnabled || FileManager.default.fileExists(
        atPath: FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/local.daystart.app.plist").path
    )

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEE"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            todayCard
            Divider()
            history
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 320)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("DayStart")
                    .font(.headline)
                Text("本地锁屏 / 解锁时间记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "clock.fill")
                .foregroundStyle(.tint)
        }
    }

    private var todayCard: some View {
        let summary = tracker.todaySummary
        return VStack(alignment: .leading, spacing: 8) {
            Text("今天")
                .font(.subheadline.weight(.semibold))

            metricRow(
                title: "第一次使用电脑",
                value: summary.firstUnlock.map { timeFormatter.string(from: $0) } ?? "尚未记录",
                emphasize: true
            )
            metricRow(
                title: "最近锁定",
                value: summary.lastLock.map { timeFormatter.string(from: $0) } ?? "—"
            )
            metricRow(
                title: "累计使用",
                value: summary.activeDurationText
            )
            metricRow(
                title: "解锁次数",
                value: "\(summary.unlockCount)"
            )
        }
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("最近几天")
                .font(.subheadline.weight(.semibold))

            if tracker.recentSummaries.isEmpty {
                Text("暂无记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(tracker.recentSummaries.prefix(7)) { day in
                    HStack {
                        Text(dayFormatter.string(from: day.date))
                            .font(.caption)
                        Spacer()
                        Text(day.firstUnlock.map { timeFormatter.string(from: $0) } ?? "—")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(day.firstUnlock == nil ? .secondary : .primary)
                    }
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("登录时自动启动", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    _ = LoginItemManager.setEnabled(newValue)
                }

            HStack {
                Button("刷新") {
                    tracker.refresh()
                }
                Spacer()
                Button("打开数据目录") {
                    openDataFolder()
                }
                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .buttonStyle(.borderless)
        }
    }

    private func metricRow(title: String, value: String, emphasize: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(emphasize ? .body.weight(.semibold).monospacedDigit() : .caption.monospacedDigit())
        }
    }

    private func openDataFolder() {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("DayStart", isDirectory: true)
        NSWorkspace.shared.open(url)
    }
}
