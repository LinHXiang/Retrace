import Defaults
import SwiftUI

struct FooterView: View {
  @Bindable var footer: Footer

  @Environment(AppState.self) private var appState
  @Default(.showFooter) private var showFooter

  var body: some View {
    VStack(spacing: 0) {
      Divider()
        .padding(.horizontal, Popup.horizontalSeparatorPadding)
        .padding(.bottom, Popup.verticalSeparatorPadding)

      HStack(spacing: 8) {
        if appState.history.editingCommand == nil {
          Text("↵ Copy")
          Text("⌘D Favorite")
        } else {
          Text("↵ Save")
          Text("Esc Cancel")
        }
        Spacer()
      }
      .font(AppFont.regular(size: 11))
      .foregroundStyle(.secondary)
      .padding(.horizontal, 10)
      ForEach(footer.visibleItems) { item in
        FooterItemView(item: item)
      }
    }
    .opacity(showFooter ? 1 : 0)
    .frame(maxHeight: showFooter ? nil : 0)
    .padding(.bottom, showFooter ? Popup.verticalPadding : 0)
    .readHeight(appState, into: \.popup.footerHeight)
  }
}
