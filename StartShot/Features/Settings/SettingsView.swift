import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(AppDateProvider.self) private var dateProvider

    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        @Bindable var settingsStore = settingsStore
        @Bindable var dateProvider = dateProvider

        Form {
            Section("通知") {
                Toggle("毎日リマインド", isOn: $settingsStore.notificationsEnabled)

                DatePicker(
                    "通知時刻",
                    selection: Binding(
                        get: { settingsStore.reminderDate },
                        set: { settingsStore.updateReminderTime($0) }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .disabled(!settingsStore.notificationsEnabled)
            }

#if DEBUG
            Section("デバッグ時刻") {
                Toggle("擬似時刻を使う", isOn: $dateProvider.usesMockDate)

                DatePicker(
                    "擬似現在時刻",
                    selection: $dateProvider.mockNow
                )
                .disabled(!dateProvider.usesMockDate)

                Text("現在判定時刻: \(debugNowText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                    ForEach(DebugTimePreset.allCases) { preset in
                        Button(preset.label) {
                            dateProvider.applyPreset(preset)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
#endif
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                if isSaving {
                    ProgressView()
                } else {
                    Button("保存") {
                        saveSettings()
                    }
                }
            }
        }
        .alert("設定を保存できませんでした", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func saveSettings() {
        isSaving = true

        Task {
            do {
                try await NotificationService.refreshReminder(using: settingsStore)
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    settingsStore.notificationsEnabled = false
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }

#if DEBUG
    private var debugNowText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = .current
        return formatter.string(from: dateProvider.now)
    }
#endif
}
