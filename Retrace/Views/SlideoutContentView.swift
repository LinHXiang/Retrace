import SwiftUI

struct SlideoutContentView: View {
  @Environment(AppState.self) private var appState

  var body: some View {
    VStack {
      ToolbarView()

      if let item = appState.navigator.leadHistoryItem {
        PreviewItemView(item: item)
      } else {
        EmptyView()
      }
    }
    .padding(.horizontal)
    .padding(.bottom)
    .padding(.top, Popup.verticalPadding)
  }
}
