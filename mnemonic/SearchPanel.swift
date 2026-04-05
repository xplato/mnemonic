import AppKit
import SwiftUI

final class SearchPanel: NSPanel {
  
  private let panelWidth: CGFloat = 750
  private let maxPanelHeight: CGFloat = 600
  private let cornerRadius: CGFloat = 12
  
  var onEscape: (() -> Void)?
  
  init(contentView swiftUIView: NSView) {
    super.init(
      contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: 56),
      styleMask: [.borderless, .nonactivatingPanel],
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
    container.clipsToBounds = true
    container.autoresizingMask = [.width, .height]
    container.addSubview(visualEffect)
    container.addSubview(swiftUIView)
    
    contentView = container
  }
  
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }
  
  override func cancelOperation(_ sender: Any?) {
    onEscape?()
  }
  
  override func keyDown(with event: NSEvent) {
    // Escape is keyCode 53 — route to cancelOperation
    if event.keyCode == 53 {
      cancelOperation(nil)
      return
    }
    super.keyDown(with: event)
  }
  
  func centerOnScreen() {
    guard let screen = NSScreen.main else { return }
    let screenFrame = screen.visibleFrame
    let x = screenFrame.midX - panelWidth / 2
    // Place the top edge of the panel at upper third of the screen
    let topY = screenFrame.minY + screenFrame.height * 3 / 4
    let y = topY - frame.height
    setFrameOrigin(NSPoint(x: x, y: y))
  }
  
  /// Resize the panel to the given content height, keeping the top edge fixed.
  func updateHeight(_ contentHeight: CGFloat) {
    let newHeight = min(max(contentHeight, 56), maxPanelHeight)
    guard abs(frame.height - newHeight) > 1 else { return }
    
    let topY = frame.origin.y + frame.height
    let newFrame = NSRect(
      x: frame.origin.x,
      y: topY - newHeight,
      width: panelWidth,
      height: newHeight
    )
    
    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.25
      // Deceleration curve — fast start, smooth stop (matches Spotlight feel)
      context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 1.0, 0.3, 1.0)
      context.allowsImplicitAnimation = true
      self.animator().setFrame(newFrame, display: true)
    }
  }
}
