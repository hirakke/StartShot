import SwiftUI
import SwiftData
import UIKit

struct NightSetupConfirmView: View {
    private enum Field: Hashable {
        case message
    }

    let capturedImage: UIImage?
    let initialMessage: String
    let initialNotificationHour: Int
    let initialNotificationMinute: Int
    let currentDate: Date
    let targetDate: Date
    let onClose: () -> Void
    let onRetake: () -> Void
    let onCompleted: () -> Void
    private let displayImage: UIImage?

    @Environment(\.modelContext) private var modelContext
    @Environment(SettingsStore.self) private var settingsStore
    @Query(sort: \DailyMissionRecord.targetDate) private var records: [DailyMissionRecord]

    @State private var message: String
    @State private var notificationDate: Date
    @State private var errorMessage: String?
    @State private var warningMessage: String?
    @State private var isSaving = false
    @FocusState private var focusedField: Field?

    private let dateService = DateService.shared

    init(
        capturedImage: UIImage?,
        initialMessage: String,
        initialNotificationHour: Int,
        initialNotificationMinute: Int,
        currentDate: Date,
        targetDate: Date,
        onClose: @escaping () -> Void,
        onRetake: @escaping () -> Void,
        onCompleted: @escaping () -> Void
    ) {
        self.capturedImage = capturedImage
        self.initialMessage = initialMessage
        self.initialNotificationHour = initialNotificationHour
        self.initialNotificationMinute = initialNotificationMinute
        self.currentDate = currentDate
        self.targetDate = targetDate
        self.onClose = onClose
        self.onRetake = onRetake
        self.onCompleted = onCompleted
        self.displayImage = Self.makePreviewImage(from: capturedImage, maxDimension: 1200)

        _message = State(initialValue: initialMessage)
        _notificationDate = State(
            initialValue: Self.makeNotificationDate(
                hour: initialNotificationHour,
                minute: initialNotificationMinute,
                baseDate: currentDate
            )
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let maxPreviewWidth = min(max(proxy.size.width - 72, 220), 340)
            let maxPreviewHeight = min(max(proxy.size.height * 0.34, 180), 300)
            let imageAspectRatio = previewAspectRatio
            let fittedSize = fittedPreviewSize(
                maxWidth: maxPreviewWidth,
                maxHeight: maxPreviewHeight,
                aspectRatio: imageAspectRatio
            )
            let isEditingMessage = focusedField == .message

            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("設定！")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.black)

                        Text("この写真を明日のミッションとして保存します")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            Spacer()
                            imagePreview(width: fittedSize.width, height: fittedSize.height)
                            Spacer()
                        }

                        HStack {
                            Text("通知時間")
                                .font(.headline)
                            Spacer()
                            DatePicker(
                                "通知時間",
                                selection: $notificationDate,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.black.opacity(0.04))
                        )

                        VStack(alignment: .leading, spacing: 12) {
                            Text("明日の自分への一言")
                                .font(.headline)

                            TextField("まずはこれから始めよう", text: $message)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: .message)
                                .submitLabel(.done)
                                .onSubmit {
                                    focusedField = nil
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.black.opacity(0.04))
                                )
                                .id(Field.message)
                        }

                        Button(action: saveMission) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("完了")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(StartShotFilledButtonStyle())
                        .disabled(capturedImage == nil || isSaving)
                        .frame(maxWidth: .infinity)

                        if !isEditingMessage {
                            HStack {
                                Spacer()
                                Button("撮り直す") {
                                    focusedField = nil
                                    HapticFeedback.selection()
                                    onRetake()
                                }
                                .buttonStyle(StartShotOutlineButtonStyle())
                                Spacer()
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 16)
                    .frame(minHeight: proxy.size.height, alignment: .top)
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        focusedField = nil
                    }
                )
                .onChange(of: focusedField) { _, newField in
                    guard newField == .message else {
                        return
                    }
                    withAnimation(.easeOut(duration: 0.2)) {
                        scrollProxy.scrollTo(Field.message, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("設定！")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("戻る") {
                    focusedField = nil
                    HapticFeedback.selection()
                    onClose()
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    focusedField = nil
                }
            }
        }
        .alert("保存できませんでした", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("通知の設定を完了できませんでした", isPresented: Binding(
            get: { warningMessage != nil },
            set: { if !$0 { warningMessage = nil } }
        )) {
            Button("OK") {
                warningMessage = nil
                onCompleted()
            }
        } message: {
            Text("ミッション自体は保存済みです。\n\(warningMessage ?? "")")
        }
    }

    private var previewAspectRatio: CGFloat {
        guard let image = displayImage ?? capturedImage else {
            return 3.0 / 4.0
        }

        let width = max(image.size.width, 1)
        let height = max(image.size.height, 1)
        return width / height
    }

    private func fittedPreviewSize(maxWidth: CGFloat, maxHeight: CGFloat, aspectRatio: CGFloat) -> CGSize {
        let clampedAspectRatio = max(aspectRatio, 0.1)
        var width = maxWidth
        var height = width / clampedAspectRatio

        if height > maxHeight {
            height = maxHeight
            width = height * clampedAspectRatio
        }

        return CGSize(width: width, height: height)
    }

    private func imagePreview(width: CGFloat, height: CGFloat) -> some View {
        Group {
            if let image = displayImage ?? capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.black.opacity(0.05))
                    .overlay {
                        Text("撮影画像がありません。")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: width, height: height)
        .background(Color.black.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private static func makePreviewImage(from image: UIImage?, maxDimension: CGFloat) -> UIImage? {
        guard let image else {
            return nil
        }

        let original = image.size
        let longestSide = max(original.width, original.height)
        guard longestSide > maxDimension, maxDimension > 0 else {
            return image
        }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(width: original.width * scale, height: original.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    private func saveMission() {
        guard let capturedImage else {
            return
        }

        isSaving = true

        let time = Calendar.current.dateComponents([.hour, .minute], from: notificationDate)
        let hour = time.hour ?? initialNotificationHour
        let minute = time.minute ?? initialNotificationMinute
        let draft = NightSetupDraft(
            image: capturedImage,
            targetDate: targetDate,
            messageForTomorrow: message,
            notificationHour: hour,
            notificationMinute: minute,
            currentDate: currentDate
        )

        Task { @MainActor in
            do {
                let result = try await MissionWriteUseCase.saveNightSetup(
                    draft: draft,
                    records: records,
                    modelContext: modelContext,
                    settingsStore: settingsStore,
                    dateService: dateService
                )
                isSaving = false
                switch result {
                case .saved:
                    focusedField = nil
                    HapticFeedback.success()
                    onCompleted()
                case .savedWithNotificationWarning(let message):
                    HapticFeedback.success()
                    warningMessage = message
                }
            } catch {
                HapticFeedback.error()
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }

    private static func makeNotificationDate(hour: Int, minute: Int, baseDate: Date) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? baseDate
    }
}

#Preview("With Captured Image") {
    NavigationStack {
        NightSetupConfirmView(
            capturedImage: previewCapturedImage(),
            initialMessage: "昨日決めた一歩から始めよう",
            initialNotificationHour: 7,
            initialNotificationMinute: 30,
            currentDate: SystemDateProvider().now,
            targetDate: DateService.shared.missionTargetDateForNewPlan(from: SystemDateProvider().now),
            onClose: {},
            onRetake: {},
            onCompleted: {}
        )
    }
    .environment(SettingsStore())
    .modelContainer(for: DailyMissionRecord.self, inMemory: true)
}

#Preview("No Image") {
    NavigationStack {
        NightSetupConfirmView(
            capturedImage: nil,
            initialMessage: "まずはこれから始めよう",
            initialNotificationHour: 8,
            initialNotificationMinute: 0,
            currentDate: SystemDateProvider().now,
            targetDate: DateService.shared.missionTargetDateForNewPlan(from: SystemDateProvider().now),
            onClose: {},
            onRetake: {},
            onCompleted: {}
        )
    }
    .environment(SettingsStore())
    .modelContainer(for: DailyMissionRecord.self, inMemory: true)
}

private func previewCapturedImage() -> UIImage {
    let size = CGSize(width: 720, height: 1280)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        UIColor(white: 0.95, alpha: 1).setFill()
        context.fill(CGRect(origin: .zero, size: size))

        UIColor(white: 0.78, alpha: 1).setFill()
        context.fill(CGRect(x: 80, y: 180, width: 560, height: 760))

        UIColor(white: 0.62, alpha: 1).setFill()
        context.fill(CGRect(x: 150, y: 260, width: 420, height: 130))
        context.fill(CGRect(x: 150, y: 430, width: 420, height: 130))
        context.fill(CGRect(x: 150, y: 600, width: 420, height: 130))
    }
}
