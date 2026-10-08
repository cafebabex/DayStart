import Foundation
import ServiceManagement

enum LoginItemManager {
    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                return true
            } catch {
                // Fallback for non-bundled / unsigned local builds.
                return setLaunchAgentEnabled(enabled)
            }
        }
        return setLaunchAgentEnabled(enabled)
    }

    private static var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/local.daystart.app.plist")
    }

    private static func setLaunchAgentEnabled(_ enabled: Bool) -> Bool {
        let url = launchAgentURL
        if enabled {
            guard let exe = Bundle.main.executableURL?.path ?? ProcessInfo.processInfo.arguments.first else {
                return false
            }
            let appPath: String
            if exe.contains(".app/Contents/MacOS/") {
                appPath = URL(fileURLWithPath: exe)
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .path
            } else {
                appPath = exe
            }

            let plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>local.daystart.app</string>
                <key>ProgramArguments</key>
                <array>
                    <string>/usr/bin/open</string>
                    <string>-a</string>
                    <string>\(appPath)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
            </dict>
            </plist>
            """
            do {
                try plist.write(to: url, atomically: true, encoding: .utf8)
                _ = try? shell("/bin/launchctl", "unload", url.path)
                _ = try shell("/bin/launchctl", "load", url.path)
                return true
            } catch {
                return false
            }
        } else {
            _ = try? shell("/bin/launchctl", "unload", url.path)
            try? FileManager.default.removeItem(at: url)
            return true
        }
    }

    private static func shell(_ executable: String, _ args: String...) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
