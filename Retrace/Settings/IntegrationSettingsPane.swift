import AppKit
import SwiftUI
import Settings

struct IntegrationSettingsPane: View {
  @State private var isZshIntegrationInstalled = ZshIntegration.isInstalled()

  var body: some View {
    Settings.Container(contentWidth: 620) {
      Settings.Section(title: "", bottomDivider: true) {
        VStack(alignment: .leading, spacing: 14) {
          Text("ZshIntegration", tableName: "IntegrationSettings")
            .font(.headline)

          Text("ZshIntegrationPrompt", tableName: "IntegrationSettings")
            .font(.caption)
            .foregroundStyle(.secondary)

          Label {
            Text(
              isZshIntegrationInstalled
                ? "ZshIntegrationInstalled"
                : "ZshIntegrationNotInstalled",
              tableName: "IntegrationSettings"
            )
          } icon: {
            Image(systemName: isZshIntegrationInstalled ? "checkmark.circle" : "circle")
              .foregroundStyle(isZshIntegrationInstalled ? .green : .secondary)
          }
          .font(.caption)
          .foregroundStyle(.secondary)

          Button {
            installZshIntegration()
          } label: {
            Label {
              Text("InstallZshIntegration", tableName: "IntegrationSettings")
            } icon: {
              Image(systemName: "terminal")
            }
          }
          .controlSize(.small)
        }
        .onAppear {
          refreshZshIntegrationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
          refreshZshIntegrationStatus()
        }
      }

      Settings.Section(title: "") {
        VStack(alignment: .leading, spacing: 10) {
          Text("ZshIntegrationExplanationTitle", tableName: "IntegrationSettings")
            .font(.headline)

          IntegrationExplanationRow(
            systemImage: "terminal",
            textKey: "ZshIntegrationExplanationHook"
          )
          IntegrationExplanationRow(
            systemImage: "clock.arrow.circlepath",
            textKey: "ZshIntegrationExplanationTiming"
          )
          IntegrationExplanationRow(
            systemImage: "doc.text",
            textKey: "ZshIntegrationExplanationFile"
          )
        }
      }
    }
  }

  private func installZshIntegration() {
    ZshIntegrationUI.install(confirmFirst: true)
    refreshZshIntegrationStatus()
  }

  private func refreshZshIntegrationStatus() {
    isZshIntegrationInstalled = ZshIntegration.isInstalled()
  }
}

private struct IntegrationExplanationRow: View {
  let systemImage: String
  let textKey: LocalizedStringKey

  var body: some View {
    Label {
      Text(textKey, tableName: "IntegrationSettings")
        .fixedSize(horizontal: false, vertical: true)
    } icon: {
      Image(systemName: systemImage)
        .foregroundStyle(.secondary)
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }
}

#Preview {
  IntegrationSettingsPane()
    .environment(\.locale, .init(identifier: "en"))
}
