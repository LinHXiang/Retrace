import AppKit
import Defaults

enum MenuIcon: String, CaseIterable, Identifiable, Defaults.Serializable {
  case retrace

  var id: Self { self }

  var image: NSImage {
    switch self {
    case .retrace:
      return NSImage(named: .retraceStatusBar)!
    }
  }
}
