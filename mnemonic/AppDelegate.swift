import AppKit
import KeyboardShortcuts
import Quartz
import SwiftUI

extension KeyboardShortcuts.Name {
  static let toggleSearch = Self("toggleSearch", default: .init(.space, modifiers: [.command, .shift]))
}

extension Notification.Name {
  static let clearSearchQuery = Notification.Name("clearSearchQuery")
}

final class AppDelegate: NSObject, NSApplicationDelegate {

  private var statusItem: NSStatusItem!
  private var searchPanel: SearchPanel?
  
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
    searchController.database = database
    
    setupStatusItem()
    setupSearchPanel()
    setupGlobalShortcut()
    setupSettingsShortcutMonitor()
    
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
    let searchView = SearchView(
      onHeightChange: { [weak self] height in self?.searchPanel?.updateHeight(height) },
      onOpenSettings: { [weak self] in self?.openSettings() }
    )
      .environment(searchController)
      .environment(modelManager)
      .ignoresSafeArea()
    
    let hostingView = NSHostingView(rootView: searchView)
    hostingView.layer?.backgroundColor = .clear
    hostingView.safeAreaRegions = []
    
    searchPanel = SearchPanel(contentView: hostingView)
    searchPanel?.onEscape = { [weak self] in
      self?.handleEscape()
    }
  }
  
  private func handleEscape() {
    // State 3: detail view → go back to results
    if searchController.selectedResult != nil {
      QuickLookCoordinator.shared.dismiss()
      searchController.deselectResult()
      return
    }
    // State 2: has query → clear query and results
    if searchController.hasSearched || !searchController.results.isEmpty {
      searchController.clearResults()
      // Post notification so SearchView clears its query text field
      NotificationCenter.default.post(name: .clearSearchQuery, object: nil)
      return
    }
    // State 1: empty search bar → hide panel
    hidePanel()
  }
  
  @objc func togglePanel() {
    guard let searchPanel else { return }
    if searchPanel.isKeyWindow {
      hidePanel()
    } else {
      showPanel()
    }
  }
  
  private func showPanel() {
    guard let searchPanel else { return }
    
    // Reset to clean search-bar-only state
    searchController.clearResults()
    
    // Reset height instantly (no animation) before positioning
    let resetFrame = NSRect(x: searchPanel.frame.origin.x, y: searchPanel.frame.origin.y,
                            width: searchPanel.frame.width, height: 56)
    searchPanel.setFrame(resetFrame, display: false)
    
    searchPanel.centerOnScreen()
    searchPanel.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
  
  private func hidePanel() {
    searchPanel?.orderOut(nil)
  }
  
  // MARK: - Settings Window
  
  @objc func openSettings() {
    hidePanel()
    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    NSApp.activate(ignoringOtherApps: true)
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
  
  // MARK: - Keyboard Shortcuts

  /// Intercept Cmd+, so we always hide the search panel before settings opens.
  private func setupSettingsShortcutMonitor() {
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers == "," {
        self?.hidePanel()
      }
      return event // pass through so SwiftUI Settings scene still handles it
    }
  }


  private func setupGlobalShortcut() {
    KeyboardShortcuts.onKeyUp(for: .toggleSearch) { [weak self] in
      self?.togglePanel()
    }
  }
}
