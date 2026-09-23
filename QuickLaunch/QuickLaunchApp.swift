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
    var hotKeyRef: EventHotKeyRef?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        createWindow()
        setupHotkey()
    }
    
    // MARK: - Menu bar
    
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "magnifyingglass",
                                            accessibilityDescription: "QuickLaunch")
        
        let menu = NSMenu()
        
        let openItem = NSMenuItem(title: "Open QuickLaunch", action: #selector(openFromMenu), keyEquivalent: "")
        openItem.target = self
        
        let quitItem = NSMenuItem(title: "Quit QuickLaunch", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        
        menu.addItem(openItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
        statusItem?.menu = menu
    }
    
    @objc func openFromMenu() {
        showWindow()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Global hotkey (⌘⇧Space)
    
    func setupHotkey() {
        if let existing = hotKeyRef {
            UnregisterEventHotKey(existing)
            hotKeyRef = nil
        }
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        
        // Carbon callbacks are C function pointers, so AppDelegate is passed in via userData
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async {
                appDelegate.toggleWindow()
            }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType("QLCH".fourCharCodeValue)
        hotKeyID.id = 1
        
        let keyCode: UInt32 = 49  // Space
        let modifiers = UInt32(cmdKey | shiftKey)
        
        var newHotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID,
                                         GetApplicationEventTarget(), 0, &newHotKeyRef)
        
        if status == noErr {
            hotKeyRef = newHotKeyRef
        } else {
            #if DEBUG
            print("Failed to register hotkey, status: \(status)")
            #endif
        }
    }
    
    // MARK: - Window
    
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
        
        let contentView = SearchView(viewModel: searchViewModel, onEscape: { [weak self] in
            self?.hideWindow()
        })
        window?.contentView = NSHostingView(rootView: contentView)
        
        // Hide when the user clicks anywhere else
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.hideWindow()
        }
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
            
            // Centered horizontally, in the upper part of the screen
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

// MARK: - Helpers

extension String {
    /// Packs up to 4 ASCII characters into a FourCharCode (used for the hotkey signature)
    var fourCharCodeValue: Int {
        var result = 0
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
