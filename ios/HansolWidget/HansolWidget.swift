import WidgetKit
import SwiftUI

// MARK: - 데이터 읽기

struct WidgetData {
    let mealDate: String
    let breakfast: String
    let lunch: String
    let dinner: String
    let timetableDate: String
    let subjects: [String]
    let currentPeriod: Int

    static func load() -> WidgetData {
        let defaults = UserDefaults(suiteName: "group.com.monkshark.hansol_high_school")
        return WidgetData(
            mealDate: defaults?.string(forKey: "meal_date") ?? "",
            breakfast: defaults?.string(forKey: "meal_breakfast") ?? "정보 없음",
            lunch: defaults?.string(forKey: "meal_lunch") ?? "정보 없음",
            dinner: defaults?.string(forKey: "meal_dinner") ?? "정보 없음",
            timetableDate: defaults?.string(forKey: "timetable_date") ?? "",
            subjects: {
                let data = defaults?.string(forKey: "timetable_data") ?? ""
                return data.isEmpty ? [] : data.components(separatedBy: ",")
            }(),
            currentPeriod: defaults?.integer(forKey: "timetable_current") ?? 0
        )
    }
}

// MARK: - Timeline Provider

struct HansolTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> HansolEntry {
        HansolEntry(date: Date(), data: WidgetData(
            mealDate: "4월 7일 (월)",
            breakfast: "찹쌀밥\n된장찌개\n깍두기",
            lunch: "혼합잡곡밥\n마라탕\n배추김치",
            dinner: "찰보리밥\n꽃게탕\n깍두기",
            timetableDate: "4월 7일 (월)",
            subjects: ["국어", "수학", "영어", "과학", "체육", "", ""],
            currentPeriod: 3
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (HansolEntry) -> Void) {
        completion(HansolEntry(date: Date(), data: WidgetData.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HansolEntry>) -> Void) {
        let entry = HansolEntry(date: Date(), data: WidgetData.load())
        // 1시간마다 갱신
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct HansolEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - 테마 색상

struct WidgetColors {
    let primary: Color
    let content: Color
    let sub: Color

    static func resolve(_ colorScheme: ColorScheme) -> WidgetColors {
        if colorScheme == .dark {
            return WidgetColors(
                primary: Color(red: 0.494, green: 0.722, blue: 0.855),  // #7EB8DA
                content: Color(white: 0.8),
                sub: Color(white: 0.53)
            )
        } else {
            return WidgetColors(
                primary: colors.primary,  // #3F72AF
                content: colors.content,
                sub: Color(white: 0.6)
            )
        }
    }
}

// MARK: - 급식 위젯

struct MealWidgetView: View {
    let data: WidgetData
    @Environment(\.colorScheme) var colorScheme

    var colors: WidgetColors { WidgetColors.resolve(colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(data.mealDate)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(colors.primary)

            HStack(alignment: .top, spacing: 8) {
                mealColumn(title: "조식", content: data.breakfast)
                mealColumn(title: "중식", content: data.lunch)
                mealColumn(title: "석식", content: data.dinner)
            }
        }
        .padding(12)
    }

    func mealColumn(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(colors.primary)
            Text(formatMeal(content))
                .font(.system(size: 10))
                .foregroundColor(colors.content)
                .lineLimit(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func formatMeal(_ text: String) -> String {
        if text == "정보 없음" { return text }
        let lines = text.components(separatedBy: "\n").prefix(5)
        return lines.joined(separator: "\n")
    }
}

// MARK: - 시간표 위젯

struct TimetableWidgetView: View {
    let data: WidgetData
    @Environment(\.colorScheme) var colorScheme

    var colors: WidgetColors { WidgetColors.resolve(colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(data.timetableDate)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(colors.primary)
                .padding(.bottom, 2)

            if trimmedSubjects.isEmpty {
                Spacer()
                Text("시간표 정보 없음")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(Array(trimmedSubjects.enumerated()), id: \.offset) { index, subject in
                    HStack(spacing: 4) {
                        Text("\(index + 1)교시")
                            .font(.system(size: 11))
                            .foregroundColor(data.currentPeriod == index + 1 ?
                                colors.primary : .gray)
                            .frame(width: 42, alignment: .leading)
                        Text(subject.isEmpty ? "-" : subject)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(data.currentPeriod == index + 1 ?
                                colors.primary : colors.content)
                    }
                    .padding(.vertical, 1)
                }
            }
        }
        .padding(12)
    }

    var trimmedSubjects: [String] {
        var list = data.subjects
        while !list.isEmpty && (list.last?.isEmpty ?? true) {
            list.removeLast()
        }
        return list
    }
}

// MARK: - 통합 위젯

struct CombinedWidgetView: View {
    let data: WidgetData
    @Environment(\.colorScheme) var colorScheme

    var colors: WidgetColors { WidgetColors.resolve(colorScheme) }

    var body: some View {
        HStack(spacing: 0) {
            // 급식 (왼쪽)
            VStack(alignment: .leading, spacing: 6) {
                Text(data.mealDate)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(colors.primary)

                HStack(alignment: .top, spacing: 6) {
                    miniMealColumn(title: "조식", content: data.breakfast)
                    miniMealColumn(title: "중식", content: data.lunch)
                    miniMealColumn(title: "석식", content: data.dinner)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 6)

            // 구분선
            Rectangle()
                .fill(colors.sub.opacity(0.3))
                .frame(width: 1)
                .padding(.vertical, 4)

            // 시간표 (오른쪽)
            VStack(alignment: .leading, spacing: 2) {
                Text(data.timetableDate)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(colors.primary)
                    .padding(.bottom, 2)

                if trimmedSubjects.isEmpty {
                    Spacer()
                    Text("시간표 정보 없음")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ForEach(Array(trimmedSubjects.enumerated()), id: \.offset) { index, subject in
                        HStack(spacing: 2) {
                            Text("\(index + 1)")
                                .font(.system(size: 9))
                                .foregroundColor(data.currentPeriod == index + 1 ?
                                    colors.primary : .gray)
                                .frame(width: 14, alignment: .trailing)
                            Text(subject.isEmpty ? "-" : subject)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(data.currentPeriod == index + 1 ?
                                    colors.primary : colors.content)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 0.5)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 6)
        }
        .padding(12)
    }

    func miniMealColumn(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(colors.primary)
            Text(formatMeal(content))
                .font(.system(size: 9))
                .foregroundColor(colors.content)
                .lineLimit(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func formatMeal(_ text: String) -> String {
        if text == "정보 없음" { return text }
        let lines = text.components(separatedBy: "\n").prefix(4)
        return lines.joined(separator: "\n")
    }

    var trimmedSubjects: [String] {
        var list = data.subjects
        while !list.isEmpty && (list.last?.isEmpty ?? true) {
            list.removeLast()
        }
        return list
    }
}

// MARK: - 위젯 정의

struct MealWidget: Widget {
    let kind: String = "MealWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HansolTimelineProvider()) { entry in
            MealWidgetView(data: entry.data)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("급식")
        .description("오늘의 급식 (조식/중식/석식)")
        .supportedFamilies([.systemMedium])
    }
}

struct TimetableWidget: Widget {
    let kind: String = "TimetableWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HansolTimelineProvider()) { entry in
            TimetableWidgetView(data: entry.data)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("시간표")
        .description("오늘의 시간표")
        .supportedFamilies([.systemMedium])
    }
}

struct CombinedWidget: Widget {
    let kind: String = "CombinedWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HansolTimelineProvider()) { entry in
            CombinedWidgetView(data: entry.data)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("급식 + 시간표")
        .description("오늘의 급식과 시간표")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - 위젯 번들

@main
struct HansolWidgetBundle: WidgetBundle {
    var body: some Widget {
        MealWidget()
        TimetableWidget()
        CombinedWidget()
    }
}
