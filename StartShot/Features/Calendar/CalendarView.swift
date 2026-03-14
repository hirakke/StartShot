import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(AppDateProvider.self) private var dateProvider
    @Query(sort: \DailyMissionRecord.targetDate) private var records: [DailyMissionRecord]

    @State private var displayedMonth: Date
    @State private var selectedDate: Date

    private let dateService = DateService.shared

    init() {
        let placeholder = Date.distantPast
        _displayedMonth = State(initialValue: DateService.shared.startOfMonth(for: placeholder))
        _selectedDate = State(initialValue: DateService.shared.startOfDay(for: placeholder))
    }

    private var gridDays: [Date] {
        dateService.daysForMonthGrid(containing: displayedMonth)
    }

    private var achievedRecordByDay: [String: DailyMissionRecord] {
        var map: [String: DailyMissionRecord] = [:]

        for record in records {
            guard dateService.isSameMonth(record.targetDate, displayedMonth) else {
                continue
            }
            guard record.actualPhotoPath != nil else {
                continue
            }
            let status = MissionLifecycleService.resolvedStatus(
                for: record,
                referenceDate: dateProvider.now,
                dateService: dateService
            )
            guard status == .achieved else {
                continue
            }

            map[dateService.dayString(for: record.targetDate)] = record
        }

        return map
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button {
                        displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()
                    Text(dateService.monthTitle(for: displayedMonth))
                        .font(.title3.bold())
                    Spacer()

                    Button {
                        displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }

                let weekSymbols = Calendar.current.shortStandaloneWeekdaySymbols
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 12) {
                    ForEach(weekSymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    ForEach(gridDays, id: \.self) { day in
                        let dayKey = dateService.dayString(for: day)
                        if let achievedRecord = achievedRecordByDay[dayKey] {
                            NavigationLink {
                                CalendarMissionDetailView(record: achievedRecord)
                            } label: {
                                CalendarDayCell(
                                    date: day,
                                    selectedDate: selectedDate,
                                    isInDisplayedMonth: dateService.isSameMonth(day, displayedMonth),
                                    completionImagePath: achievedRecord.actualPhotoPath
                                )
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    selectedDate = day
                                }
                            )
                        } else {
                            CalendarDayCell(
                                date: day,
                                selectedDate: selectedDate,
                                isInDisplayedMonth: dateService.isSameMonth(day, displayedMonth),
                                completionImagePath: nil
                            )
                            .onTapGesture {
                                selectedDate = day
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .onAppear {
            let now = dateProvider.now
            displayedMonth = dateService.startOfMonth(for: now)
            selectedDate = dateService.startOfDay(for: now)
        }
    }
}

private struct CalendarMissionDetailView: View {
    let record: DailyMissionRecord
    private let dateService = DateService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(dateService.dayString(for: record.targetDate))
                    .font(.headline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Text("設定画像")
                        .font(.headline)
                    StoredImageView(
                        relativePath: record.plannedPhotoPath,
                        emptyText: "設定画像がありません。",
                        height: 220
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("達成画像")
                        .font(.headline)
                    StoredImageView(
                        relativePath: record.actualPhotoPath,
                        emptyText: "達成画像がありません。",
                        height: 220
                    )
                }
            }
            .padding(20)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationTitle("記録")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let selectedDate: Date
    let isInDisplayedMonth: Bool
    let completionImagePath: String?

    private let dateService = DateService.shared

    var body: some View {
        ZStack {
            if let completionImagePath, let image = PhotoFileStore.image(for: completionImagePath), isInDisplayedMonth {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .overlay(Color.black.opacity(0.18))
            }

            VStack(spacing: 6) {
                Text(dateService.dayNumberString(for: date))
                    .font(.system(size: 16, weight: dateService.isSameDay(date, selectedDate) ? .bold : .regular))
                    .foregroundStyle(dayNumberColor)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, minHeight: 62)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cellBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    dateService.isSameDay(date, selectedDate) ? Color.black : Color.clear,
                    lineWidth: 2
                )
        )
    }

    private var dayNumberColor: Color {
        if completionImagePath != nil, isInDisplayedMonth {
            return .white
        }
        if !isInDisplayedMonth {
            return .secondary.opacity(0.4)
        }
        return .primary
    }

    private var cellBackgroundColor: Color {
        guard completionImagePath == nil else {
            return .clear
        }
        if dateService.isSameDay(date, selectedDate) {
            return Color.accentColor.opacity(0.14)
        }
        return .clear
    }
}
