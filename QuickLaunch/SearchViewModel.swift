import SwiftUI
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var isActive = false
    @Published var apps: [AppInfo] = []
    @Published var selectedIndex = 0
    @Published var recentApps: [AppInfo] = []
    @Published var clipboardHistory: [ClipboardItem] = []
    
    private var clipboardTimer: Timer?
    private var lastClipboardContent: String = ""
    
    let systemCommands: [SystemCommand]
    let emojis: [EmojiItem] = [
        EmojiItem(emoji: "😀", name: "grinning", keywords: ["smile", "happy", "face"]),
        EmojiItem(emoji: "😂", name: "joy", keywords: ["laugh", "crying", "funny", "lol"]),
        EmojiItem(emoji: "🥹", name: "holding back tears", keywords: ["emotional", "touched", "cry"]),
        EmojiItem(emoji: "😍", name: "heart eyes", keywords: ["love", "crush", "adore"]),
        EmojiItem(emoji: "🤔", name: "thinking", keywords: ["hmm", "consider", "wonder"]),
        EmojiItem(emoji: "😎", name: "cool", keywords: ["sunglasses", "awesome", "chill"]),
        EmojiItem(emoji: "🥺", name: "pleading", keywords: ["puppy", "eyes", "please", "beg"]),
        EmojiItem(emoji: "😭", name: "sobbing", keywords: ["cry", "sad", "tears", "sob"]),
        EmojiItem(emoji: "🔥", name: "fire", keywords: ["hot", "lit", "flame"]),
        EmojiItem(emoji: "✨", name: "sparkles", keywords: ["magic", "shine", "star"]),
        EmojiItem(emoji: "💀", name: "skull", keywords: ["dead", "death", "dying"]),
        EmojiItem(emoji: "👀", name: "eyes", keywords: ["look", "see", "watching"]),
        EmojiItem(emoji: "💯", name: "hundred", keywords: ["perfect", "score", "100"]),
        EmojiItem(emoji: "🎉", name: "party", keywords: ["celebrate", "tada", "congrats"]),
        EmojiItem(emoji: "❤️", name: "red heart", keywords: ["love", "heart"]),
        EmojiItem(emoji: "💔", name: "broken heart", keywords: ["sad", "heartbreak"]),
        EmojiItem(emoji: "👍", name: "thumbs up", keywords: ["yes", "ok", "good", "agree"]),
        EmojiItem(emoji: "👎", name: "thumbs down", keywords: ["no", "bad", "disagree"]),
        EmojiItem(emoji: "🙏", name: "pray", keywords: ["please", "thanks", "hope", "hands"]),
        EmojiItem(emoji: "💪", name: "muscle", keywords: ["strong", "flex", "power"]),
        EmojiItem(emoji: "🤝", name: "handshake", keywords: ["deal", "agree", "partner"]),
        EmojiItem(emoji: "🚀", name: "rocket", keywords: ["launch", "fast", "ship"]),
        EmojiItem(emoji: "💰", name: "money bag", keywords: ["rich", "cash", "dollar"]),
        EmojiItem(emoji: "⚡", name: "lightning", keywords: ["fast", "electric", "power"]),
        EmojiItem(emoji: "🌙", name: "moon", keywords: ["night", "sleep", "dark"]),
        EmojiItem(emoji: "☀️", name: "sun", keywords: ["sunny", "bright", "day"]),
        EmojiItem(emoji: "🌈", name: "rainbow", keywords: ["colorful", "pride"]),
        EmojiItem(emoji: "🍕", name: "pizza", keywords: ["food", "slice"]),
        EmojiItem(emoji: "🍺", name: "beer", keywords: ["drink", "alcohol", "cheers"]),
        EmojiItem(emoji: "☕", name: "coffee", keywords: ["drink", "morning", "cafe"]),
        EmojiItem(emoji: "🎵", name: "music", keywords: ["song", "note", "sound"]),
        EmojiItem(emoji: "💻", name: "laptop", keywords: ["computer", "work", "code"]),
        EmojiItem(emoji: "📱", name: "phone", keywords: ["mobile", "cell", "iphone"]),
        EmojiItem(emoji: "✅", name: "check", keywords: ["done", "complete", "yes"]),
        EmojiItem(emoji: "❌", name: "x", keywords: ["no", "wrong", "cancel"]),
        EmojiItem(emoji: "⚠️", name: "warning", keywords: ["alert", "caution"]),
        EmojiItem(emoji: "💡", name: "lightbulb", keywords: ["idea", "bright", "think"]),
        EmojiItem(emoji: "🎯", name: "target", keywords: ["goal", "aim", "bullseye"]),
        EmojiItem(emoji: "📈", name: "chart up", keywords: ["growth", "increase", "stonks"]),
        EmojiItem(emoji: "📉", name: "chart down", keywords: ["decline", "decrease", "loss"])
    ]
    
    init() {
        systemCommands = [
            SystemCommand(name: "Lock Screen", icon: "lock.fill", color: .blue) {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
                task.arguments = ["displaysleepnow"]
                try? task.run()
            },
            SystemCommand(name: "Sleep", icon: "moon.fill", color: .indigo) {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
                task.arguments = ["sleepnow"]
                try? task.run()
            },
            SystemCommand(name: "Empty Trash", icon: "trash.fill", color: .red) {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                task.arguments = ["-e", "tell application \"Finder\" to empty trash"]
                try? task.run()
            },
            SystemCommand(name: "Toggle Dark Mode", icon: "moon.circle.fill", color: .purple) {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                task.arguments = ["-e", "tell app \"System Events\" to tell appearance preferences to set dark mode to not dark mode"]
                try? task.run()
            },
            SystemCommand(name: "Screenshot", icon: "camera.fill", color: .orange) {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                task.arguments = ["-i", "-c"]
                try? task.run()
            },
            SystemCommand(name: "Show Desktop", icon: "menubar.dock.rectangle", color: .green) {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                task.arguments = ["-e", "tell application \"Finder\" to set visible of every process to false"]
                try? task.run()
            },
            SystemCommand(name: "Force Quit Apps", icon: "xmark.app.fill", color: .red) {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/CoreServices/Applications/Force Quit Applications.app"))
            },
            SystemCommand(name: "Activity Monitor", icon: "chart.bar.fill", color: .green) {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
            }
        ]
        
        loadRecentApps()
        loadApps()
        startClipboardMonitor()
    }
    
    var currentMode: SearchMode {
        if searchText.isEmpty {
            return .recent
        } else if searchText.hasPrefix("=") {
            return .calculator
        } else if searchText.hasPrefix("g ") || searchText.hasPrefix("google ") {
            return .google
        } else if searchText.hasPrefix("yt ") || searchText.hasPrefix("youtube ") {
            return .youtube
        } else if searchText.hasPrefix("gh ") || searchText.hasPrefix("github ") {
            return .github
        } else if searchText.hasPrefix("cb") || searchText.hasPrefix("clipboard") || searchText.hasPrefix("paste") {
            return .clipboard
        } else if searchText.hasPrefix(":") || searchText.hasPrefix("emoji ") {
            return .emoji
        } else if searchText.hasPrefix(">") || searchText.hasPrefix("sys ") || searchText.hasPrefix("system ") {
            return .system
        } else if searchText.hasPrefix("def ") || searchText.hasPrefix("define ") {
            return .define
        } else {
            return .apps
        }
    }
    
    // MARK: - Calculator
    
    var calculatorResult: String? {
        guard searchText.hasPrefix("=") else { return nil }
        let expression = searchText.dropFirst().trimmingCharacters(in: .whitespaces)
        guard !expression.isEmpty, let value = MathEvaluator.evaluate(expression) else { return nil }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.usesGroupingSeparator = false  // copy "1234", not "1,234"
        return formatter.string(from: NSNumber(value: value))
    }
    
    // MARK: - Query parsing
    
    var searchQuery: String {
        if searchText.hasPrefix("g ") {
            return String(searchText.dropFirst(2))
        } else if searchText.hasPrefix("google ") {
            return String(searchText.dropFirst(7))
        } else if searchText.hasPrefix("yt ") {
            return String(searchText.dropFirst(3))
        } else if searchText.hasPrefix("youtube ") {
            return String(searchText.dropFirst(8))
        } else if searchText.hasPrefix("gh ") {
            return String(searchText.dropFirst(3))
        } else if searchText.hasPrefix("github ") {
            return String(searchText.dropFirst(7))
        } else if searchText.hasPrefix("def ") {
            return String(searchText.dropFirst(4))
        } else if searchText.hasPrefix("define ") {
            return String(searchText.dropFirst(7))
        }
        return searchText
    }
    
    var emojiQuery: String {
        if searchText.hasPrefix(":") {
            return String(searchText.dropFirst())
        } else if searchText.hasPrefix("emoji ") {
            return String(searchText.dropFirst(6))
        }
        return ""
    }
    
    var filteredEmojis: [EmojiItem] {
        let query = emojiQuery.lowercased()
        if query.isEmpty { return Array(emojis.prefix(12)) }
        
        return emojis.filter { emoji in
            emoji.name.contains(query) ||
            emoji.keywords.contains { $0.contains(query) }
        }.prefix(12).map { $0 }
    }
    
    var filteredSystemCommands: [SystemCommand] {
        let query = searchText
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "sys ", with: "")
            .replacingOccurrences(of: "system ", with: "")
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
        
        if query.isEmpty { return systemCommands }
        
        return systemCommands.filter { cmd in
            cmd.name.lowercased().contains(query)
        }
    }
    
    // MARK: - App & file search
    
    var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return recentApps
        }
        
        if currentMode != .apps {
            return []
        }
        
        let searchLower = searchText.lowercased()
        
        // Score cached apps/files: exact > prefix > substring > fuzzy
        let scored = apps.compactMap { app -> (AppInfo, Int)? in
            let nameLower = app.name.lowercased()
            
            if nameLower == searchLower {
                return (app, 100)
            } else if nameLower.hasPrefix(searchLower) {
                return (app, 80)
            } else if nameLower.contains(searchLower) {
                return (app, 60)
            } else {
                // Fuzzy match: query characters appear in order
                var searchIndex = searchLower.startIndex
                for char in nameLower {
                    if searchIndex < searchLower.endIndex && char == searchLower[searchIndex] {
                        searchIndex = searchLower.index(after: searchIndex)
                    }
                }
                if searchIndex == searchLower.endIndex {
                    return (app, 40)
                }
            }
            return nil
        }
        
        var results = scored.sorted { $0.1 > $1.1 }.map { $0.0 }
        
        // Fall back to Spotlight when the cache comes up short
        if results.count < 5 && searchText.count >= 2 {
            let additionalFiles = searchFilesWithSpotlight(query: searchText)
            for file in additionalFiles where !results.contains(where: { $0.path == file.path }) {
                results.append(file)
            }
        }
        
        return Array(results.prefix(7))
    }
    
    func searchFilesWithSpotlight(query: String) -> [AppInfo] {
        var foundFiles: [AppInfo] = []
        let realHome = FileManager.default.homeDirectoryForCurrentUser.path
        
        let searchLocations = [
            realHome + "/Downloads",
            realHome + "/Desktop",
            realHome + "/Documents",
            realHome
        ]
        
        for location in searchLocations {
            let task = Process()
            let pipe = Pipe()
            
            task.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
            // Case-insensitive filename match (more reliable than mdfind -name)
            task.arguments = [
                "kMDItemFSName == '*\(query)*'c",
                "-onlyin", location
            ]
            task.standardOutput = pipe
            task.standardError = FileHandle.nullDevice
            
            do {
                try task.run()
                task.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let paths = output.split(separator: "\n").map(String.init)
                    
                    for path in paths.prefix(5) {
                        let url = URL(fileURLWithPath: path)
                        let ext = url.pathExtension.lowercased()
                        
                        // Skip directories and hidden files
                        var isDirectory: ObjCBool = false
                        if !FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) || isDirectory.boolValue {
                            continue
                        }
                        if url.lastPathComponent.hasPrefix(".") {
                            continue
                        }
                        
                        let isScriptExt = ["command", "sh", "bash", "zsh", "py", "rb", "pl", "js", "swift"].contains(ext)
                        
                        var isExecutable = false
                        if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
                           let permissions = attrs[.posixPermissions] as? NSNumber {
                            isExecutable = (permissions.uint16Value & 0o111) != 0
                        }
                        
                        // Scripts, executables, or extensionless files (likely binaries)
                        if isScriptExt || isExecutable || ext.isEmpty {
                            let name = url.lastPathComponent
                            let icon = NSWorkspace.shared.icon(forFile: path)
                            
                            if !foundFiles.contains(where: { $0.path == path }) {
                                foundFiles.append(AppInfo(name: name, path: path, icon: icon, isFile: true))
                            }
                        }
                    }
                }
            } catch {
                #if DEBUG
                print("mdfind failed for \(location): \(error)")
                #endif
            }
            
            if foundFiles.count >= 5 {
                break
            }
        }
        
        return foundFiles
    }
    
    // MARK: - Indexing
    
    func loadApps() {
        var foundApps: [AppInfo] = []
        let realHome = FileManager.default.homeDirectoryForCurrentUser.path
        
        // .app bundles
        let appDirs = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            realHome + "/Applications"
        ]
        
        for dir in appDirs {
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: dir) {
                for item in contents where item.hasSuffix(".app") {
                    let path = "\(dir)/\(item)"
                    let name = item.replacingOccurrences(of: ".app", with: "")
                    let icon = NSWorkspace.shared.icon(forFile: path)
                    foundApps.append(AppInfo(name: name, path: path, icon: icon, isFile: false))
                }
            }
        }
        
        // Scripts and executables in common user folders
        let homeDirs = [
            realHome + "/Downloads",
            realHome + "/Desktop",
            realHome + "/Documents",
            realHome,
            realHome + "/bin",
            realHome + "/.local/bin",
            "/usr/local/bin"
        ]
        
        let executableExtensions = ["command", "sh", "py", "rb", "pl", "js", "swift", "app"]
        
        for dir in homeDirs {
            guard let enumerator = FileManager.default.enumerator(
                at: URL(fileURLWithPath: dir),
                includingPropertiesForKeys: [.isRegularFileKey, .isExecutableKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }
            
            for case let fileURL as URL in enumerator {
                // Limit depth to keep the scan fast
                let depth = fileURL.pathComponents.count - URL(fileURLWithPath: dir).pathComponents.count
                if depth > 3 {
                    enumerator.skipDescendants()
                    continue
                }
                
                let path = fileURL.path
                let item = fileURL.lastPathComponent
                let ext = fileURL.pathExtension.lowercased()
                
                // .app bundles were already collected above
                if ext == "app" { continue }
                
                if executableExtensions.contains(ext) {
                    let name = (item as NSString).deletingPathExtension
                    let icon = NSWorkspace.shared.icon(forFile: path)
                    foundApps.append(AppInfo(name: name, path: path, icon: icon, isFile: true))
                } else if !item.hasPrefix(".") {
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
                       let permissions = attrs[.posixPermissions] as? NSNumber {
                        let isExecutable = (permissions.uint16Value & 0o111) != 0
                        if isExecutable {
                            let icon = NSWorkspace.shared.icon(forFile: path)
                            foundApps.append(AppInfo(name: item, path: path, icon: icon, isFile: true))
                        }
                    }
                }
            }
        }
        
        apps = foundApps.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    // MARK: - Clipboard
    
    func startClipboardMonitor() {
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let content = NSPasteboard.general.string(forType: .string) {
                if content != self.lastClipboardContent && !content.isEmpty {
                    self.lastClipboardContent = content
                    let item = ClipboardItem(content: content, timestamp: Date())
                    DispatchQueue.main.async {
                        self.clipboardHistory.insert(item, at: 0)
                        if self.clipboardHistory.count > 20 {
                            self.clipboardHistory = Array(self.clipboardHistory.prefix(20))
                        }
                    }
                }
            }
        }
    }
    
    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
    
    // MARK: - Selection
    
    func clear() {
        searchText = ""
        selectedIndex = 0
    }
    
    func moveSelection(_ direction: Int) {
        var count: Int
        switch currentMode {
        case .apps, .recent: count = filteredApps.count
        case .clipboard: count = clipboardHistory.count
        case .emoji: count = filteredEmojis.count
        case .system: count = filteredSystemCommands.count
        default: count = 1
        }
        
        if count == 0 { return }
        let newIndex = selectedIndex + direction
        if newIndex >= 0 && newIndex < count {
            selectedIndex = newIndex
        }
    }
    
    // MARK: - Recents
    
    func addToRecent(_ app: AppInfo) {
        recentApps.removeAll { $0.path == app.path }
        recentApps.insert(app, at: 0)
        if recentApps.count > 5 {
            recentApps = Array(recentApps.prefix(5))
        }
        saveRecentApps()
    }
    
    func saveRecentApps() {
        let paths = recentApps.map { $0.path }
        UserDefaults.standard.set(paths, forKey: "recentAppPaths")
    }
    
    func loadRecentApps() {
        guard let paths = UserDefaults.standard.array(forKey: "recentAppPaths") as? [String] else {
            return
        }
        
        var loaded: [AppInfo] = []
        for path in paths where FileManager.default.fileExists(atPath: path) {
            let name = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
            let icon = NSWorkspace.shared.icon(forFile: path)
            let isFile = !path.hasSuffix(".app")
            loaded.append(AppInfo(name: name, path: path, icon: icon, isFile: isFile))
        }
        recentApps = loaded
    }
}
