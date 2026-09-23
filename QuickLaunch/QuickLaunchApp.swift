import SwiftUI
import Carbon

@main
struct QuickLaunchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: KeyableWindow?
    var statusItem: NSStatusItem?
    var searchViewModel = SearchViewModel()
    var eventMonitor: Any?
    var globalEventMonitor: Any?
    var hotKeyRef: EventHotKeyRef?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
            button.action = #selector(menuBarClicked)
            button.target = self
        }
        
        createWindow()
        
        // Delay permission check and hotkey setup slightly to let macOS catch up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.checkAccessibilityPermissions()
            self.setupHotkey()
        }
    }
    
    func checkAccessibilityPermissions() {
        // Check multiple times as macOS can be slow to report
        let accessEnabled = AXIsProcessTrusted()
        
        print("🔍 Accessibility check attempt 1: \(accessEnabled)")
        
        if !accessEnabled {
            // Try one more time after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let recheckEnabled = AXIsProcessTrusted()
                print("🔍 Accessibility check attempt 2: \(recheckEnabled)")
                
                if !recheckEnabled {
                    print("⚠️ Accessibility permissions not granted (or macOS hasn't recognized them yet)")
                    print("⚠️ This is normal during development when running from Xcode")
                    print("💡 Try the hotkey anyway - it might still work!")
                    
                    // Uncomment this block if you want to show the alert to end users
                    /*
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        let alert = NSAlert()
                        alert.messageText = "Accessibility Permission Required"
                        alert.informativeText = "QuickLaunch needs accessibility permissions to register the global hotkey (⌘⇧Space).\n\nIf you already granted permission, try removing QuickLaunch from System Settings > Privacy & Security > Accessibility and adding it again, then restart the app."
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "Open System Settings")
                        alert.addButton(withTitle: "Ignore (Try Hotkey Anyway)")
                        
                        if alert.runModal() == .alertFirstButtonReturn {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                        }
                    }
                    */
                } else {
                    print("✅ Accessibility permissions granted (on recheck)")
                }
            }
        } else {
            print("✅ Accessibility permissions granted")
        }
    }
    
    func setupHotkey() {
        print("🔥 Setting up global hotkey (⌘⇧Space)")
        
        // Unregister existing hotkey if any
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
            print("🗑️ Unregistered old hotkey")
        }
        
        // Remove existing monitors if any
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        
        // Use Carbon Event Manager for global hotkey (more reliable)
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType("QLCH".fourCharCodeValue)
        hotKeyID.id = 1
        
        var eventHandler: EventHandlerRef?
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            print("🎯 Carbon hotkey triggered!")
            DispatchQueue.main.async {
                appDelegate.toggleWindow()
            }
            
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        
        // Register ⌘⇧Space (keyCode 49 = Space)
        let keyCode: UInt32 = 49
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        
        var newHotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &newHotKeyRef)
        
        if status == noErr {
            hotKeyRef = newHotKeyRef
            print("✅ Carbon hotkey registered successfully")
        } else {
            print("❌ Failed to register Carbon hotkey with status: \(status)")
        }
    }
    
    func createWindow() {
        window = KeyableWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.level = .floating
        window?.isReleasedWhenClosed = false
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let contentView = SearchView(viewModel: searchViewModel, onEscape: { self.hideWindow() })
        window?.contentView = NSHostingView(rootView: contentView)
        
        // Hide window when it loses focus (user clicks elsewhere)
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.hideWindow()
        }
    }
    
    @objc func menuBarClicked() {
        toggleWindow()
    }
    
    func toggleWindow() {
        if window?.isVisible == true {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    func showWindow() {
        searchViewModel.clear()
        searchViewModel.isActive = true
        
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowWidth: CGFloat = 600
            let windowHeight: CGFloat = 400
            
            // Center horizontally, place in upper third vertically
            let x = screenFrame.origin.x + (screenFrame.width - windowWidth) / 2
            let y = screenFrame.origin.y + screenFrame.height - windowHeight - (screenFrame.height * 0.2)
            
            window?.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideWindow() {
        searchViewModel.isActive = false
        searchViewModel.clear()
        window?.orderOut(nil)
    }
}
// Helper extension for converting string to FourCharCode
extension String {
    var fourCharCodeValue: Int {
        var result: Int = 0
        if let data = self.data(using: .macOSRoman) {
            data.withUnsafeBytes { bytes in
                for i in 0..<min(4, data.count) {
                    result = result << 8 + Int(bytes[i])
                }
            }
        }
        return result
    }
}
