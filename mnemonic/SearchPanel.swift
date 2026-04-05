import AppKit
import SwiftUI

final class SearchPanel: NSPanel {

    private let panelWidth: CGFloat = 600
    private let maxPanelHeight: CGFloat = 500
    private let cornerRadius: CGFloat = 12

    init(contentView swiftUIView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: 56),
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

        let initialFrame = NSRect(x: 0, y: 0, width: panelWidth, height: 56)

        // Rounded visual effect background
        let visualEffect = NSVisualEffectView(frame: initialFrame)
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = cornerRadius
        visualEffect.layer?.masksToBounds = true
        visualEffect.autoresizingMask = [.width, .height]

        // SwiftUI hosting view on top
        swiftUIView.frame = initialFrame
        swiftUIView.autoresizingMask = [.width, .height]

        let container = NSView(frame: initialFrame)
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
        let y = screenFrame.midY + screenFrame.height / 6
        setFrameOrigin(NSPoint(x: x, y: y))
    }

    /// Resize the panel to the given content height, keeping the top edge fixed.
    func updateHeight(_ contentHeight: CGFloat) {
        let newHeight = min(max(contentHeight, 56), maxPanelHeight)
        guard abs(frame.height - newHeight) > 1 else { return }

        let newOrigin = NSPoint(
            x: frame.origin.x,
            y: frame.origin.y + frame.height - newHeight
        )
        setFrame(
            NSRect(x: newOrigin.x, y: newOrigin.y, width: panelWidth, height: newHeight),
            display: true,
            animate: true
        )
    }
}
