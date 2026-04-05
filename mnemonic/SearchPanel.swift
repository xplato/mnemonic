import AppKit
import SwiftUI

final class SearchPanel: NSPanel {

    private let panelWidth: CGFloat = 600
    private let maxPanelHeight: CGFloat = 500
    private let cornerRadius: CGFloat = 12
    private var hostingView: NSView?

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
        self.hostingView = swiftUIView

        let container = NSView(frame: initialFrame)
        container.wantsLayer = true
        container.layer?.cornerRadius = cornerRadius
        container.layer?.masksToBounds = true
        container.autoresizingMask = [.width, .height]
        container.addSubview(visualEffect)
        container.addSubview(swiftUIView)

        contentView = container

        // Observe hosting view's intrinsic content size to resize panel dynamically
        swiftUIView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hostingViewDidResize),
            name: NSView.frameDidChangeNotification,
            object: swiftUIView
        )
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

    @objc private func hostingViewDidResize(_ notification: Notification) {
        guard let hostingView else { return }
        let fittingSize = hostingView.fittingSize
        let newHeight = min(max(fittingSize.height, 56), maxPanelHeight)

        if abs(frame.height - newHeight) > 1 {
            let newOrigin = NSPoint(
                x: frame.origin.x,
                y: frame.origin.y + frame.height - newHeight
            )
            setFrame(
                NSRect(x: newOrigin.x, y: newOrigin.y, width: panelWidth, height: newHeight),
                display: true,
                animate: false
            )
        }
    }
}
