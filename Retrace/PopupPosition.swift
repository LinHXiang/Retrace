import AppKit.NSEvent
import Defaults
import Foundation

enum PopupPosition: String, CaseIterable, Identifiable, CustomStringConvertible, Defaults.Serializable {
  case cursor
  case statusItem
  case window
  case center
  case lastPosition

  var id: Self { self }

  var description: String {
    switch self {
    case .cursor:
      return NSLocalizedString("PopupAtCursor", tableName: "AppearanceSettings", comment: "")
    case .statusItem:
      return NSLocalizedString("PopupAtMenuBarIcon", tableName: "AppearanceSettings", comment: "")
    case .window:
      return NSLocalizedString("PopupAtWindowCenter", tableName: "AppearanceSettings", comment: "")
    case .center:
      return NSLocalizedString("PopupAtScreenCenter", tableName: "AppearanceSettings", comment: "")
    case .lastPosition:
      return NSLocalizedString("PopupAtLastPosition", tableName: "AppearanceSettings", comment: "")
    }
  }

  func origin(size: NSSize, statusBarButton: NSStatusBarButton?) -> NSPoint {
    switch self {
    case .center:
      return screenCenterOrigin(size: size) ?? cursorOrigin(size: size)
    case .window:
      return windowCenterOrigin(size: size) ?? cursorOrigin(size: size)
    case .statusItem:
      return statusItemOrigin(size: size, statusBarButton: statusBarButton) ?? cursorOrigin(size: size)
    case .lastPosition:
      return lastPositionOrigin(size: size) ?? cursorOrigin(size: size)
    default:
      return cursorOrigin(size: size)
    }
  }

  private func screenCenterOrigin(size: NSSize) -> NSPoint? {
    guard let screen = NSScreen.forPopup else { return nil }

    return constrainedOrigin(
      NSRect.centered(ofSize: size, in: screen.visibleFrame).origin,
      size: size,
      screen: screen
    )
  }

  private func windowCenterOrigin(size: NSSize) -> NSPoint? {
    guard let frame = NSWorkspace.shared.frontmostApplication?.windowFrame else { return nil }

    let origin = NSRect.centered(ofSize: size, in: frame).origin
    return constrainedOrigin(origin, size: size, screen: screen(containing: frame))
  }

  private func statusItemOrigin(size: NSSize, statusBarButton: NSStatusBarButton?) -> NSPoint? {
    guard let statusBarButton else { return nil }

    let rectInWindow = statusBarButton.convert(statusBarButton.bounds, to: nil)
    guard let screenRect = statusBarButton.window?.convertToScreen(rectInWindow) else { return nil }

    let origin = NSPoint(x: screenRect.minX, y: screenRect.minY - size.height)
    return constrainedOrigin(origin, size: size, screen: statusBarButton.window?.screen)
  }

  private func lastPositionOrigin(size: NSSize) -> NSPoint? {
    guard let screen = NSScreen.forPopup else { return nil }

    let relativePos = Defaults[.windowPosition]
    let frame = screen.visibleFrame
    let anchorX = frame.minX + frame.width * relativePos.x
    let anchorY = frame.minY + frame.height * relativePos.y
    // Anchor is top middle of frame.
    return constrainedOrigin(
      NSPoint(x: anchorX - size.width / 2, y: anchorY - size.height),
      size: size,
      screen: screen
    )
  }

  private func cursorOrigin(size: NSSize) -> NSPoint {
    var point = NSEvent.mouseLocation
    let cursorScreen = screen(containing: point)
    point.y -= size.height
    return constrainedOrigin(point, size: size, screen: cursorScreen)
  }

  private func constrainedOrigin(_ origin: NSPoint, size: NSSize, screen: NSScreen?) -> NSPoint {
    guard let frame = (screen ?? NSScreen.forPopup ?? NSScreen.main)?.visibleFrame else {
      return origin
    }

    var point = origin
    point.x = clamped(point.x, min: frame.minX, max: frame.maxX - size.width)
    point.y = clamped(point.y, min: frame.minY, max: frame.maxY - size.height)
    return point
  }

  private func clamped(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
    if maxValue < minValue { return minValue }
    return min(max(value, minValue), maxValue)
  }

  private func screen(containing point: NSPoint) -> NSScreen? {
    NSScreen.screens.first { $0.frame.contains(point) }
  }

  private func screen(containing rect: NSRect) -> NSScreen? {
    screen(containing: NSPoint(x: rect.midX, y: rect.midY))
  }
}
