import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(AppDateProvider.self) private var dateProvider
    @Query(sort: \DailyMissionRecord.targetDate) private var records: [DailyMissionRecord]

    // Root-level UI state only: selected tab and active full-screen flow.
    @State private var viewModel = RootViewModel()

    private let dateService = DateService.shared

    private var timePolicy: MissionTimePolicy {
        MissionTimePolicy(dateProvider: dateProvider, dateService: dateService)
    }

    // One derived snapshot used by both tab contents and flow destinations.
    private var snapshot: RootMissionSnapshot {
        RootMissionSnapshot.build(
            records: records,
            timePolicy: timePolicy,
            dateService: dateService
        )
    }

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                NavigationStack {
                    HomeView(
                        homeMissionState: snapshot.homeState,
                        dailyMissionStatus: snapshot.dailyStatus,
                        currentStreak: snapshot.currentStreak,
                        streakMessage: "明日の自分を助けよう",
                        configuredImagePath: snapshot.configuredImagePath,
                        beforeImagePath: snapshot.todayRecord?.plannedPhotoPath,
                        afterImagePath: snapshot.todayRecord?.actualPhotoPath,
                        onPrimaryAction: {
                            viewModel.handleHomePrimaryAction(status: snapshot.dailyStatus)
                        },
                        onConfiguredImageEdit: {
                            viewModel.handleConfiguredMissionEdit(
                                status: snapshot.dailyStatus,
                                configuredImagePath: snapshot.configuredImagePath,
                                targetDate: snapshot.configuredTargetDate
                            )
                        }
                    )
                    .navigationTitle("Home")
                    .navigationBarTitleDisplayMode(.automatic)
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            Button {
                                HapticFeedback.selection()
                                viewModel.showSettings()
                            } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
                }
            }

            Tab("Calendar", systemImage: "calendar", value: .calendar) {
                NavigationStack {
                    CalendarView()
                        .navigationTitle("Calendar")
                        .navigationBarTitleDisplayMode(.automatic)
                }
            }
        }
        // Keep the native tab bar style while forcing a full-width bar presentation.
        .toolbar(.visible, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.regularMaterial, for: .tabBar)
        .fullScreenCover(item: $viewModel.activeFlow) { flow in
            NavigationStack {
                flowDestination(for: flow, snapshot: snapshot)
            }
        }
        .onChange(of: viewModel.activeFlow) { _, newFlow in
            if newFlow == nil {
                viewModel.clearTransientState()
            }
        }
    }

    @ViewBuilder
    private func flowDestination(for flow: ActiveFlow, snapshot: RootMissionSnapshot) -> some View {
        // Camera/setup screens are not tabs; they are modal flows from Home actions.
        switch flow {
        case .nightCapture:
            NightCaptureView(
                onClose: { viewModel.closeFlow() },
                onCapture: { image in
                    viewModel.handleNightCapture(image, defaultTargetDate: snapshot.nextPlanTargetDate)
                }
            )

        case .nightSetupConfirm:
            NightSetupConfirmView(
                capturedImage: viewModel.pendingNightImage,
                initialMessage: snapshot.nextPlanRecord?.messageForTomorrow ?? settingsStore.selfMessage,
                initialNotificationHour: snapshot.nextPlanRecord?.notificationHour ?? settingsStore.notificationHour,
                initialNotificationMinute: snapshot.nextPlanRecord?.notificationMinute ?? settingsStore.notificationMinute,
                currentDate: timePolicy.now,
                targetDate: viewModel.nightSetupTargetDate ?? snapshot.nextPlanTargetDate,
                onClose: { viewModel.closeFlow() },
                onRetake: { viewModel.retakeNightCapture() },
                onCompleted: { viewModel.returnHomeAndCloseFlow() }
            )

        case .morningCapture:
            MorningCaptureView(
                plannedImagePath: snapshot.todayRecord?.plannedPhotoPath,
                missionMessage: snapshot.todayRecord?.messageForTomorrow,
                onClose: { viewModel.closeFlow() },
                onGuideToSetup: { viewModel.retakeNightCapture() },
                onCapture: { image in
                    viewModel.handleMorningCapture(image)
                }
            )

        case .morningStartConfirm:
            MorningStartConfirmView(
                plannedImagePath: snapshot.todayRecord?.plannedPhotoPath,
                storedCompletionImagePath: snapshot.todayRecord?.actualPhotoPath,
                capturedImage: viewModel.pendingMorningImage,
                streakValue: snapshot.dailyStatus == .completedToday ? snapshot.currentStreak : snapshot.projectedStreak,
                isAlreadyCompleted: snapshot.dailyStatus == .completedToday,
                onClose: { viewModel.closeFlow() },
                onRetake: { viewModel.retakeMorningCapture() },
                onCompleted: { viewModel.returnHomeAndCloseFlow() }
            )

        case .settings:
            SettingsView()
        }
    }
}
