import SwiftUI

enum ConsoleTheme {
  static let accent = Color(red: 0.84, green: 1, blue: 0.20)
  static let panel = Color(white: 0.08)
  static let surface = Color(white: 0.15)
}

struct CutCorner: Shape {
  func path(in rect: CGRect) -> Path {
    let cut = min(9, rect.height / 3)
    return Path { path in
      path.move(to: rect.origin)
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
      path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
      path.closeSubpath()
    }
  }
}

struct PanelBackgroundView: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 12)
      .fill(ConsoleTheme.panel)
      .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.22)) }
  }
}
