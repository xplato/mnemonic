import AppKit
import Carbon
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var searchPanel: SearchPanel?
    private var settingsWindow: NSWindow?
    private var hotKeyRef: EventHotKeyRef?

    // Shared state — owned by AppDelegate, injected into views via environment
    let searchController = SearchController()
    private(set) var database: AppDatabase!
    private(set) var directoryStore: DirectoryStore!
    let modelManager = CLIPModelManager()

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        database = try! AppDatabase.makeShared()
        directoryStore = DirectoryStore(database: database)

        setupStatusItem()
        setupSearchPanel()
        registerGlobalHotKey()

        // Try to initialize CLIP services (succeeds if models already downloaded)
        Task { await initializeServicesIfNeeded() }
    }

    // MARK: - Status Item (Menu Bar)

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "Mnemonic")
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Open Search", action: #selector(togglePanel), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Mnemonic", action: #selector(quitApp), keyEquivalent: "q")

        statusItem.menu = menu
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Search Panel

    private func setupSearchPanel() {
        let searchView = SearchView(onDismiss: { [weak self] in
            self?.hidePanel()
        })
        .environment(searchController)
        .environment(modelManager)

        let hostingView = NSHostingView(rootView: searchView)
        hostingView.layer?.backgroundColor = .clear

        searchPanel = SearchPanel(contentView: hostingView)
        observeSearchControllerForResize()
    }

    /// Observe SearchController state changes to resize the panel dynamically.
    private func observeSearchControllerForResize() {
        withObservationTracking {
            _ = self.searchController.results.count
            _ = self.searchController.hasSearched
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.resizeSearchPanel()
                self?.observeSearchControllerForResize()
            }
        }
    }

    private func resizeSearchPanel() {
        let searchBarHeight: CGFloat = 56
        var height = searchBarHeight

        if searchController.hasSearched || !searchController.results.isEmpty {
            height += 1 // Divider
            if searchController.results.isEmpty {
                height += 60
            } else {
                let columns = 3
                let rows = ceil(Double(searchController.results.count) / Double(columns))
                height += min(CGFloat(rows) * 146 + 20, 400)
            }
        }

        searchPanel?.updateHeight(height)
    }

    @objc func togglePanel() {
        guard let searchPanel else { return }
        if searchPanel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        searchPanel?.centerOnScreen()
        searchPanel?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    private func hidePanel() {
        searchPanel?.orderOut(nil)
    }

    // MARK: - Settings Window

    @objc func openSettings() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let settingsView = SettingsView()
            .environment(directoryStore as DirectoryStore)
            .environment(modelManager)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Mnemonic Settings"
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()

        settingsWindow = window
    }

    // MARK: - CLIP Service Initialization

    func initializeServicesIfNeeded() async {
        modelManager.checkModelsExist()
        guard modelManager.modelsReady else { return }
        guard modelManager.indexingService == nil else { return }

        do {
            // Initialize encoders off the main thread (CoreML EP init is heavy)
            let visionPath = modelManager.visionModelPath
            let textPath = modelManager.textModelPath
            let modelsDir = CLIPModelManager.modelsDirectory

            let (imageEncoder, textEncoder) = try await Task.detached {
                let img = try CLIPImageEncoder(modelPath: visionPath)
                let txt = try await CLIPTextEncoder(modelPath: textPath, tokenizerFolder: modelsDir)
                return (img, txt)
            }.value

            let idxService = IndexingService(database: database, imageEncoder: imageEncoder)
            let srchService = SearchService(database: database, textEncoder: textEncoder)

            modelManager.indexingService = idxService
            searchController.searchService = srchService
        } catch {
            print("Failed to initialize CLIP: \(error)")
        }
    }

    // MARK: - Global Hot Key (Cmd+Shift+Space)

    private func registerGlobalHotKey() {
        let refcon = Unmanaged.passUnretained(self).toOpaque()

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
