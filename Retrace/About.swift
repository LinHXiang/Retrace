import Cocoa

class About {
  private var credits: NSMutableAttributedString {
    let string = NSMutableAttributedString(string: "GitHub",
                                           attributes: [NSAttributedString.Key.foregroundColor: NSColor.labelColor])
    string.addAttribute(.link, value: "https://github.com/LinHXiang/Retrace", range: NSRange(location: 0, length: 6))
    string.setAlignment(.center, range: NSRange(location: 0, length: string.length))
    return string
  }

  @objc
  func openAbout(_ sender: NSMenuItem?) {
    NSApp.activate(ignoringOtherApps: true)
    NSApp.orderFrontStandardAboutPanel(options: [NSApplication.AboutPanelOptionKey.credits: credits])
  }
}
