import SwiftUI

struct SlideoutContentView: View {
  @Environment(AppState.self) private var appState

  var body: some View {
    VStack {
      if let item = appState.navigator.leadCommandItem {
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
