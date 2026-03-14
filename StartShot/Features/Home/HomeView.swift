import SwiftData
import SwiftUI

private enum HomeLayout {
    static let horizontalPadding: CGFloat = 18
    static let topPadding: CGFloat = 18
    static let sectionSpacing: CGFloat = 28
    static let dividerOpacity: Double = 0.08
    static let buttonHeight: CGFloat = 58
    static let streakBoxSize = CGSize(width: 116, height: 116)
    static let missionImageSize = CGSize(width: 162, height: 196)
    static let missionPairImageSize = CGSize(width: 112, height: 144)
}

struct HomeView: View {
    let homeMissionState: HomeMissionState
    let dailyMissionStatus: DailyMissionStatus
    let currentStreak: Int
    let streakMessage: String
    let configuredImagePath: String?
    let beforeImagePath: String?
    let afterImagePath: String?
    let onPrimaryAction: () -> Void
    let onConfiguredImageEdit: () -> Void

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                StreakCardView(streakCount: currentStreak, message: streakMessage)
                    .padding(.top, HomeLayout.topPadding)

                MissionSectionView(
                    homeMissionState: homeMissionState,
                    dailyMissionStatus: dailyMissionStatus,
                    configuredImagePath: configuredImagePath,
                    beforeImagePath: beforeImagePath,
                    afterImagePath: afterImagePath,
                    onPrimaryTap: onPrimaryAction,
                    onConfiguredImageEdit: onConfiguredImageEdit
                )
                .padding(.top, HomeLayout.sectionSpacing)
                .padding(.horizontal, HomeLayout.horizontalPadding)

                Spacer(minLength: 24)
            }
            .padding(.bottom, 8)
        }
    }
}

struct StreakCardView: View {
    let streakCount: Int
    let message: String

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ストリーク")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.black)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Rectangle()
                    .fill(Color.black.opacity(HomeLayout.dividerOpacity))
                    .frame(width: 1, height: 110)

                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.black)
                    Text("\(streakCount)日")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: HomeLayout.streakBoxSize.width, height: HomeLayout.streakBoxSize.height)
            }
            .padding(.horizontal, HomeLayout.horizontalPadding)

            Divider()
                .overlay(Color.black.opacity(HomeLayout.dividerOpacity))
        }
    }
}

struct MissionSectionView: View {
    let homeMissionState: HomeMissionState
    let dailyMissionStatus: DailyMissionStatus
    let configuredImagePath: String?
    let beforeImagePath: String?
    let afterImagePath: String?
    let onPrimaryTap: () -> Void
    let onConfiguredImageEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(sectionTitle)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.black)

            switch homeMissionState {
            case .empty:
                emptyContent
            case .configured:
                configuredContent
            case .completed:
                completedContent
            }
        }
    }

    private var sectionTitle: String {
        switch dailyMissionStatus {
        case .configuredForTomorrow:
            return "明日のミッション"
        case .readyForToday, .completedToday, .notConfigured:
            return "今日のミッション"
        }
    }

    private var primaryButtonTitle: String {
        switch dailyMissionStatus {
        case .notConfigured:
            return "設定する"
        case .configuredForTomorrow:
            return "設定済み"
        case .readyForToday:
            return "1日を始める"
        case .completedToday:
            return "達成済み"
        }
    }

    private var helperText: String {
        switch dailyMissionStatus {
        case .notConfigured:
            return "まだミッションがありません。明日の朝いちばんにやることを先に決めておきます。"
        case .configuredForTomorrow:
            return "明日のスタート地点が保存されています。必要なら撮り直して整えられます。"
        case .readyForToday:
            return "今日はこの一歩から始めます。「1日を始める」から朝の実行に進めます。"
        case .completedToday:
            return "今朝の開始アクションは達成済みです。次の1日に備えて明日分も準備できます。"
        }
    }

    private var configuredContent: some View {
        VStack(spacing: 18) {
            HStack {
                Spacer()
                MissionPreviewCard(
                    relativePath: configuredImagePath,
                    size: HomeLayout.missionImageSize,
                    placeholderIcon: dailyMissionStatus == .configuredForTomorrow ? "moon.stars.fill" : "sun.max.fill",
                    showExternalBadge: dailyMissionStatus == .configuredForTomorrow,
                    onExternalBadgeTap: onConfiguredImageEdit
                )
                Spacer()
            }

            Text(helperText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if dailyMissionStatus == .readyForToday {
                Button(primaryButtonTitle, action: onPrimaryTap)
                    .buttonStyle(
                        MissionFilledButtonStyle(
                            background: Color(red: 0.29, green: 0.71, blue: 0.45),
                            foreground: .white
                        )
                    )
            } else {
                Button(primaryButtonTitle, action: onPrimaryTap)
                    .buttonStyle(MissionOutlineButtonStyle())
                    .disabled(true)
                    .opacity(0.55)
            }
        }
    }

    private var completedContent: some View {
        VStack(spacing: 18) {
            HStack(spacing: 14) {
                MissionPreviewCard(
                    relativePath: beforeImagePath,
                    size: HomeLayout.missionPairImageSize,
                    placeholderIcon: "moon.stars.fill"
                )

                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.5))

                MissionPreviewCard(
                    relativePath: afterImagePath,
                    size: HomeLayout.missionPairImageSize,
                    placeholderIcon: "sun.max.fill"
                )
            }
            .frame(maxWidth: .infinity)

            Text(helperText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(primaryButtonTitle, action: onPrimaryTap)
                .buttonStyle(MissionFilledButtonStyle(background: .black, foreground: .white))
                .disabled(true)
                .opacity(0.55)
        }
    }

    private var emptyContent: some View {
        VStack(spacing: 14) {
            Text(helperText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(primaryButtonTitle, action: onPrimaryTap)
                .buttonStyle(
                    MissionFilledButtonStyle(
                        background: Color(red: 0.29, green: 0.71, blue: 0.45),
                        foreground: .white
                    )
                )
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct MissionPreviewCard: View {
    let relativePath: String?
    let size: CGSize
    let placeholderIcon: String
    var showExternalBadge: Bool = false
    var onExternalBadgeTap: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let relativePath, let image = PhotoFileStore.image(for: relativePath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )

            if showExternalBadge {
                Button(action: { onExternalBadgeTap?() }) {
                    ZStack {
                        Circle()
                            .fill(Color.black)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .offset(x: -10, y: -10)
                .accessibilityLabel("ミッションを編集")
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.gray.opacity(0.12), Color.gray.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.7))
                        .frame(width: size.width * 0.52, height: size.height * 0.16)
                    Image(systemName: placeholderIcon)
                        .font(.system(size: size.width * 0.28, weight: .regular))
                        .foregroundStyle(.black.opacity(0.8))
                }
            }
    }
}

private struct MissionOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: HomeLayout.buttonHeight)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private struct MissionFilledButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: HomeLayout.buttonHeight)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

#Preview("Configured Tomorrow") {
    HomeView(
        homeMissionState: .configured,
        dailyMissionStatus: .configuredForTomorrow,
        currentStreak: 2,
        streakMessage: "明日の自分を助けよう",
        configuredImagePath: "preview-tomorrow",
        beforeImagePath: nil,
        afterImagePath: nil,
        onPrimaryAction: {},
        onConfiguredImageEdit: {}
    )
    .modelContainer(previewContainer(for: .configured))
}

#Preview("Ready Today") {
    HomeView(
        homeMissionState: .configured,
        dailyMissionStatus: .readyForToday,
        currentStreak: 2,
        streakMessage: "明日の自分を助けよう",
        configuredImagePath: "preview-today-before",
        beforeImagePath: "preview-today-before",
        afterImagePath: nil,
        onPrimaryAction: {},
        onConfiguredImageEdit: {}
    )
    .modelContainer(previewContainer(for: .ready))
}

#Preview("Completed") {
    HomeView(
        homeMissionState: .completed,
        dailyMissionStatus: .completedToday,
        currentStreak: 3,
        streakMessage: "明日の自分を助けよう",
        configuredImagePath: "preview-today-before",
        beforeImagePath: "preview-today-before",
        afterImagePath: "preview-today-after",
        onPrimaryAction: {},
        onConfiguredImageEdit: {}
    )
    .modelContainer(previewContainer(for: .completed))
}

#Preview("Empty") {
    HomeView(
        homeMissionState: .empty,
        dailyMissionStatus: .notConfigured,
        currentStreak: 0,
        streakMessage: "明日の自分を助けよう",
        configuredImagePath: nil,
        beforeImagePath: nil,
        afterImagePath: nil,
        onPrimaryAction: {},
        onConfiguredImageEdit: {}
    )
    .modelContainer(previewContainer(for: .empty))
}

private enum PreviewMissionState {
    case configured
    case ready
    case completed
    case empty
}

private func previewContainer(for state: PreviewMissionState) -> ModelContainer {
    let schema = Schema([DailyMissionRecord.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])

    let dateService = DateService.shared
    let today = dateService.startOfDay(for: .now)
    let tomorrow = dateService.tomorrow(from: today)
    let yesterday = dateService.yesterday(from: today)

    switch state {
    case .configured:
        let record = DailyMissionRecord(
            targetDate: tomorrow,
            plannedPhotoPath: "preview-tomorrow",
            plannedCapturedAt: .now,
            messageForTomorrow: "まずは机に座る"
        )
        container.mainContext.insert(record)
    case .ready:
        let record = DailyMissionRecord(
            targetDate: today,
            plannedPhotoPath: "preview-today-before",
            plannedCapturedAt: yesterday,
            messageForTomorrow: "まずはこれから始めよう"
        )
        container.mainContext.insert(record)
    case .completed:
        let record = DailyMissionRecord(
            targetDate: today,
            plannedPhotoPath: "preview-today-before",
            plannedCapturedAt: yesterday,
            messageForTomorrow: "まずは机に向かう",
            actualPhotoPath: "preview-today-after",
            actualCapturedAt: .now,
            completionConfirmedAt: .now
        )
        container.mainContext.insert(record)
    case .empty:
        break
    }

    return container
}
