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
    guard let frame = NSScreen.forPopup?.visibleFrame else { return nil }

    return NSRect.centered(ofSize: size, in: frame).origin
  }

  private func windowCenterOrigin(size: NSSize) -> NSPoint? {
    guard let frame = NSWorkspace.shared.frontmostApplication?.windowFrame else { return nil }

    return NSRect.centered(ofSize: size, in: frame).origin
  }

  private func statusItemOrigin(size: NSSize, statusBarButton: NSStatusBarButton?) -> NSPoint? {
    guard let statusBarButton, let screen = NSScreen.main else { return nil }

    let rectInWindow = statusBarButton.convert(statusBarButton.bounds, to: nil)
    guard let screenRect = statusBarButton.window?.convertToScreen(rectInWindow) else { return nil }

    var topLeftPoint = NSPoint(x: screenRect.minX, y: screenRect.minY - size.height)
    // Ensure that window doesn't spill over to the right screen.
    if (topLeftPoint.x + size.width) > screen.frame.maxX {
      topLeftPoint.x = screen.frame.maxX - size.width
    }

    return topLeftPoint
  }

  private func lastPositionOrigin(size: NSSize) -> NSPoint? {
    guard let frame = NSScreen.forPopup?.visibleFrame else { return nil }

    let relativePos = Defaults[.windowPosition]
    let anchorX = frame.minX + frame.width * relativePos.x
    let anchorY = frame.minY + frame.height * relativePos.y
    // Anchor is top middle of frame.
    return NSPoint(x: anchorX - size.width / 2, y: anchorY - size.height)
  }

  private func cursorOrigin(size: NSSize) -> NSPoint {
    var point = NSEvent.mouseLocation
    point.y -= size.height
    return point
  }
}
