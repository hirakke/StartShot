import SwiftUI
import SwiftData
import UIKit

struct MorningStartConfirmView: View {
    let plannedImagePath: String?
    let storedCompletionImagePath: String?
    let capturedImage: UIImage?
    let streakValue: Int
    let isAlreadyCompleted: Bool
    let onClose: () -> Void
    let onRetake: () -> Void
    let onCompleted: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(AppDateProvider.self) private var dateProvider
    @Query(sort: \DailyMissionRecord.targetDate) private var records: [DailyMissionRecord]

    @State private var errorMessage: String?
    @State private var isSaving = false

    private let dateService = DateService.shared
    private var timePolicy: MissionTimePolicy {
        MissionTimePolicy(dateProvider: dateProvider, dateService: dateService)
    }
    private var isDeadlinePassed: Bool {
        !isAlreadyCompleted &&
        dateService.isPastMissionExecutionDeadline(
            targetDate: timePolicy.todayTargetDate,
            at: timePolicy.now
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("今日も1日頑張ろう！")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.black)

                Text("\(streakValue)日連続")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.29, green: 0.71, blue: 0.45))

                Text("昨日決めた一歩と今朝の一歩を見比べて、今日を始める実感を確定します。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("前夜")
                            .font(.headline)
                        StoredImageView(
                            relativePath: plannedImagePath,
                            emptyText: "前夜の設定画像がありません。",
                            height: 220
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("今朝")
                            .font(.headline)

                        currentImageView
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }

                if isAlreadyCompleted {
                    Text("今日はすでに達成済みです。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if isDeadlinePassed {
                    Text("このミッションは期限切れです。次のミッションを設定しましょう。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button(action: finishMorningStart) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(isAlreadyCompleted ? "ホームに戻る" : "1日を始める！")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.black)
                .disabled((capturedImage == nil && storedCompletionImagePath == nil) || isSaving || isDeadlinePassed)

                if !isAlreadyCompleted && !isDeadlinePassed {
                    Button("撮り直す", action: onRetake)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("今日も1日頑張ろう！")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("戻る", action: onClose)
            }
        }
        .alert("完了できませんでした", isPresented: Binding(
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

    private var currentImageView: some View {
        Group {
            if let capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFill()
            } else {
                StoredImageView(
                    relativePath: storedCompletionImagePath,
                    emptyText: "今朝の撮影画像がありません。",
                    height: 220
                )
            }
        }
    }

    private func finishMorningStart() {
        if isAlreadyCompleted {
            onCompleted()
            return
        }

        isSaving = true

        do {
            let currentDate = timePolicy.now
            let targetDate = timePolicy.todayTargetDate
            try MissionWriteUseCase.finishMorningStart(
                targetDate: targetDate,
                capturedImage: capturedImage,
                records: records,
                modelContext: modelContext,
                currentDate: currentDate,
                dateService: dateService
            )

            isSaving = false
            onCompleted()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
}
