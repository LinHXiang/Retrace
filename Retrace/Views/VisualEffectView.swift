import SwiftUI

struct PanelBackgroundView: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    backgroundColor
      .overlay {
        RoundedRectangle(cornerRadius: Popup.cornerRadius + Popup.horizontalPadding)
          .stroke(borderColor, lineWidth: 1)
      }
    .clipShape(.rect(cornerRadius: Popup.cornerRadius + Popup.horizontalPadding))
  }

  private var backgroundColor: Color {
    colorScheme == .dark
      ? Color(red: 0.06, green: 0.06, blue: 0.055).opacity(0.98)
      : Color(red: 0.965, green: 0.96, blue: 0.94).opacity(0.98)
  }

  private var borderColor: Color {
    colorScheme == .dark
      ? Color.white.opacity(0.12)
      : Color.black.opacity(0.12)
  }
}

#Preview {
  PanelBackgroundView()
}
