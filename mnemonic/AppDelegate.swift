import AppKit
import Carbon
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var searchPanel: SearchPanel!
    private var hotKeyRef: EventHotKeyRef?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupSearchPanel()
        registerGlobalHotKey()
    }

    // MARK: - Search Panel

    private func setupSearchPanel() {
        let searchView = SearchView(onDismiss: { [weak self] in
            self?.hidePanel()
        })
        let hostingView = NSHostingView(rootView: searchView)
        hostingView.layer?.backgroundColor = .clear

        searchPanel = SearchPanel(contentView: hostingView)
    }

    @objc func togglePanel() {
        if searchPanel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        searchPanel.centerOnScreen()
        searchPanel.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    private func hidePanel() {
        searchPanel.orderOut(nil)
    }

    // MARK: - Global Hot Key (Cmd+Shift+Space)

    private func registerGlobalHotKey() {
        // Store a reference to self for the C callback
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        // Install event handler
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyHandler,
            1,
            &eventType,
            refcon,
            nil
        )

        // Register Cmd+Shift+Space
        let hotKeyID = EventHotKeyID(
            signature: OSType(0x4D4E454D), // "MNEM"
            id: 1
        )
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = 49 // Space

        RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
}

// C-function callback for Carbon hot key events
private func hotKeyHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData else { return OSStatus(eventNotHandledErr) }
    let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async {
        delegate.togglePanel()
    }
    return noErr
}
