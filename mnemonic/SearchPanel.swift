import AppKit
import SwiftUI

final class SearchPanel: NSPanel {

    private let panelWidth: CGFloat = 600
    private let panelHeight: CGFloat = 56
    private let cornerRadius: CGFloat = 12

    init(contentView swiftUIView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        hidesOnDeactivate = true
        isMovableByWindowBackground = true
        animationBehavior = .utilityWindow
        titleVisibility = .hidden
        titlebarAppearsTransparent = true

        // Rounded visual effect background
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = cornerRadius
        visualEffect.layer?.masksToBounds = true
        visualEffect.autoresizingMask = [.width, .height]

        // SwiftUI hosting view on top
        swiftUIView.frame = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
        swiftUIView.autoresizingMask = [.width, .height]

        let container = NSView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        container.wantsLayer = true
        container.layer?.cornerRadius = cornerRadius
        container.layer?.masksToBounds = true
        container.autoresizingMask = [.width, .height]
        container.addSubview(visualEffect)
        container.addSubview(swiftUIView)

        contentView = container
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func centerOnScreen() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - frame.width / 2
        // Position in the upper third of the screen, like Spotlight
        let y = screenFrame.midY + screenFrame.height / 6
        setFrameOrigin(NSPoint(x: x, y: y))
    }
}
