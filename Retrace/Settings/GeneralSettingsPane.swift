import AppKit
import SwiftUI
import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import Settings

struct GeneralSettingsPane: View {
  @Default(.searchMode) private var searchMode
  @Default(.commandHistorySize) private var commandHistorySize
  @State private var isZshIntegrationInstalled = ZshIntegration.isInstalled()
  @State private var canSyncUserHistory = ZshIntegration.userHistoryHasContent()

  private let sizeFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimum = 1
    formatter.maximum = 999
    return formatter
  }()

  var body: some View {
    Settings.Container(contentWidth: 620) {
      Settings.Section(title: "", bottomDivider: true) {
        LaunchAtLogin.Toggle {
          Text("LaunchAtLogin", tableName: "GeneralSettings")
        }
      }

      Settings.Section(label: { Text("Open", tableName: "GeneralSettings") }) {
        KeyboardShortcuts.Recorder(for: .popup, onChange: { newShortcut in
          if newShortcut == nil {
            // No shortcut is recorded. Remove keys monitor
            AppState.shared.popup.deinitEventsMonitor()
          } else {
            // User is using shortcut. Ensure keys monitor is initialized
            AppState.shared.popup.initEventsMonitor()
          }
        })
          .help(Text("OpenTooltip", tableName: "GeneralSettings"))
      }

      Settings.Section(
        bottomDivider: true,
        label: { Text("Search", tableName: "GeneralSettings") }
      ) {
        Picker("", selection: $searchMode) {
          ForEach(Search.Mode.allCases) { mode in
            Text(mode.description)
          }
        }
        .labelsHidden()
        .frame(width: 180, alignment: .leading)
      }

      Settings.Section(
        bottomDivider: true,
        label: { Text("CommandHistorySize", tableName: "GeneralSettings") }
      ) {
        HStack {
          TextField("", value: $commandHistorySize, formatter: sizeFormatter)
            .frame(width: 80)
            .help(Text("CommandHistorySizeTooltip", tableName: "GeneralSettings"))
          Stepper("", value: $commandHistorySize, in: 1...999)
            .labelsHidden()
        }
      }

      Settings.Section(
        label: { Text("HistorySources", tableName: "GeneralSettings") }
      ) {
        VStack(alignment: .leading, spacing: 10) {
          Text("ZshIntegrationRequired", tableName: "GeneralSettings")
            .font(.caption)
            .foregroundStyle(.secondary)

          HStack(spacing: 12) {
            Label {
              Text(
                isZshIntegrationInstalled
                  ? "ZshIntegrationInstalled"
                  : "ZshIntegrationNotInstalled",
                tableName: "GeneralSettings"
              )
            } icon: {
              Image(systemName: isZshIntegrationInstalled ? "checkmark.circle" : "circle")
                .foregroundStyle(isZshIntegrationInstalled ? .green : .secondary)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 8) {
              Button {
                installZshIntegration()
              } label: {
                Label {
                  Text("InstallZshIntegration", tableName: "GeneralSettings")
                } icon: {
                  Image(systemName: "terminal")
                }
              }

              Button {
                ZshIntegrationUI.copyBlock()
              } label: {
                Label {
                  Text("CopyZshIntegration", tableName: "GeneralSettings")
                } icon: {
                  Image(systemName: "doc.on.doc")
                }
              }
            }
            .controlSize(.small)
          }

          HStack(spacing: 12) {
            Label {
              Text("RetraceHistorySource", tableName: "GeneralSettings")
            } icon: {
              Image(systemName: "doc.text")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 8) {
              Button {
                ZshIntegrationUI.syncUserHistory()
                canSyncUserHistory = ZshIntegration.userHistoryHasContent()
              } label: {
                Label {
                  Text("SyncUserZshHistory", tableName: "GeneralSettings")
                } icon: {
                  Image(systemName: "arrow.triangle.2.circlepath")
                }
              }
              .disabled(!canSyncUserHistory)
              .help(Text("SyncUserZshHistoryTooltip", tableName: "GeneralSettings"))

              Button(role: .destructive) {
                ZshIntegrationUI.clearRecordedHistory()
              } label: {
                Label {
                  Text("ClearRetraceHistory", tableName: "GeneralSettings")
                } icon: {
                  Image(systemName: "eraser")
                }
              }

              Button {
                openRetraceHistoryInFinder()
              } label: {
                Label {
                  Text("OpenRetraceHistoryInFinder", tableName: "GeneralSettings")
                } icon: {
                  Image(systemName: "folder")
                }
              }
            }
            .controlSize(.small)
          }
        }
        .onAppear {
          isZshIntegrationInstalled = ZshIntegration.isInstalled()
          canSyncUserHistory = ZshIntegration.userHistoryHasContent()
        }
      }
    }
  }

  private func installZshIntegration() {
    ZshIntegrationUI.install(confirmFirst: true)
    isZshIntegrationInstalled = ZshIntegration.isInstalled()
  }

  private func openRetraceHistoryInFinder() {
    let historyURL = HistorySource.retraceZshHistoryURL
    let directoryURL = historyURL.deletingLastPathComponent()

    try? FileManager.default.createDirectory(
      at: directoryURL,
      withIntermediateDirectories: true
    )

    if FileManager.default.fileExists(atPath: historyURL.path) {
      NSWorkspace.shared.activateFileViewerSelecting([historyURL])
    } else {
      NSWorkspace.shared.open(directoryURL)
    }
  }
}

#Preview {
  GeneralSettingsPane()
    .environment(\.locale, .init(identifier: "en"))
}
