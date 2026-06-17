import SwiftUI

struct CommandPreviewView: View {
  @Bindable var item: CommandHistoryItemDecorator

  private var attributedPreview: AttributedString {
    let previewText = item.previewText
    var attributedString = AttributedString(previewText)
    ShellSyntaxHighlighter.apply(&attributedString, for: previewText)
    return attributedString
  }

  var body: some View {
    HStack(spacing: 0) {
      Divider()
        .padding(.vertical, Popup.verticalSeparatorPadding)

      ScrollView {
        Text(attributedPreview)
          .font(AppFont.regular())
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .topLeading)
          .padding(.horizontal, Popup.previewPadding)
          .padding(.vertical, Popup.previewPadding)
      }
      .frame(width: Popup.previewWidth)
    }
  }
}
