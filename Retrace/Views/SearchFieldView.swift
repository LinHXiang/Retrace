import SwiftUI

struct SearchFieldView: View {
  private static let height: CGFloat = 28

  var placeholder: LocalizedStringKey
  @Binding var query: String

  @Environment(AppState.self) private var appState

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: Popup.cornerRadius, style: .continuous)
        .fill(Color.secondary)
        .opacity(0.1)
        .frame(height: Self.height)

      HStack(alignment: .center) {
        Image(systemName: "magnifyingglass")
          .frame(width: 11, height: 11)
          .padding(.leading, 5)
          .offset(y: 1)
          .opacity(0.8)

        TextField(placeholder, text: $query)
          .disableAutocorrection(true)
          .lineLimit(1)
          .textFieldStyle(.plain)
          .frame(height: Self.height, alignment: .center)
          .offset(y: 1)
          .onSubmit {
            appState.select()
          }

        if !query.isEmpty {
          Button {
            query = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .frame(width: 11, height: 11)
              .padding(.trailing, 5)
              .offset(y: 1)
          }
          .buttonStyle(.plain)
          .opacity(0.9)
        }
      }
      .frame(height: Self.height, alignment: .center)
    }
  }
}

#Preview {
  return List {
    SearchFieldView(placeholder: "search_placeholder", query: .constant(""))
    SearchFieldView(placeholder: "search_placeholder", query: .constant("search"))
  }
  .frame(width: 300)
  .environment(\.locale, .init(identifier: "en"))
}
