import Charts
import SwiftData
import SwiftUI

/// Week / Month / Year / Custom with ‹ › navigation, stat tiles, budgets,
/// bar chart, greyscale donut, category breakdown, top 5, export.
struct AnalyticsView: View {
    @Query(filter: #Predicate<Entry> { $0.deletedAt == nil }) private var entries: [Entry]
    @Query private var allCategories: [ExpenseCategory]
    @Query(filter: #Predicate<Budget> { $0.deletedAt == nil }) private var budgets: [Budget]
    @Query private var settingsList: [AppSettings]
    @Environment(\.showSettings) private var showSettings

    @State private var kind: PeriodKind = .month
    @State private var offset = 0
    @State private var customFrom = Calendar.current.date(byAdding: .day, value: -29, to: Date())!
    @State private var customTo = Date()
    @State private var selectedBar: Date?
    @State private var selectedAngle: Double?
    @State private var selectedCategory: String?
    @State private var exporting: ExportKind?
    @State private var shareURL: ShareItem?

    static let greys: [Color] = ["#FFFFFF", "#C7C7CC", "#9A9AA0", "#76767C", "#56565B", "#3D3D41", "#2C2C2E"].map(Color.init(hex:))

    private var base: String { settingsList.first?.baseCurrency ?? "INR" }
    private var cycleDay: Int { settingsList.first?.cycleStartDay ?? 1 }
    private var range: DateRange { Periods.range(kind, offset: offset, cycleDay: cycleDay, from: customFrom, to: customTo) }
    private func category(_ id: String) -> ExpenseCategory? { allCategories.first { $0.id == id } ?? allCategories.first { $0.id == Defaults.otherCategoryId } }

    var body: some View {
        let r = range
        let stats = Analytics.stats(entries, range: r, kind: kind)
        let prev = Analytics.stats(entries, range: Periods.previous(kind, offset: offset, cycleDay: cycleDay, from: customFrom, to: customTo), kind: kind)
        let budget = kind == .month && offset == 0 ? Analytics.budgets(budgets, stats: stats, range: r) : nil
        let slices = Self.fold(stats.categories)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Analytics").font(.tTitle).frame(maxWidth: .infinity).frame(height: 56)

                ScrollView(.horizontal, showsIndicators: false) {
                    Pills(options: [(PeriodKind.week, "Week"), (.month, "Month"), (.year, "Year"), (.custom, "Custom")], selection: $kind)
                }
                .onChange(of: kind) { offset = 0; clearSelection() }

                periodNav(r).padding(.top, 16)

                // Stat tiles
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                    statTile("Spent", Fmt.money(stats.spent, base), big: true) {
                        if prev.spent > 0 {
                            let change = (stats.spent - prev.spent) / prev.spent
                            Text("\(change > 0 ? "▲" : "▼") \(Int(abs(change * 100).rounded()))% vs previous")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(change > 0 ? Theme.danger : .white)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(change > 0 ? Theme.danger.opacity(0.15) : .white.opacity(0.1)))
                        }
                    }
                    .gridCellColumns(2)
                    statTile("Credit", Fmt.money(stats.credit, base))
                    statTile("Net", Fmt.money(stats.net, base))
                    statTile("Avg / day", Fmt.money(stats.avgPerDay, base))
                    statTile("Entries", "\(stats.count)")
                }
                .padding(.top, 20)

                if let budget, budget.total != nil || !budget.categories.isEmpty {
                    card("Budget") {
                        VStack(alignment: .leading, spacing: 16) {
                            if let t = budget.total { budgetBar(t, label: "Monthly budget", big: true) }
                            ForEach(budget.categories) { b in
                                let c = category(b.categoryId ?? "")
                                budgetBar(b, label: "\(c?.emoji ?? "") \(c?.name ?? "")", big: false)
                            }
                            Text("\(budget.daysLeft) days left in this cycle").font(.tFootnote).foregroundStyle(Theme.sub)
                        }
                    }
                }

                if stats.count == 0 {
                    EmptyStateView(emoji: "📊", title: "No data for this period", message: "Entries you log will show up here.")
                } else {
                    if !stats.buckets.isEmpty { card("Spending over time") { barChart(stats.buckets) } }
                    if !stats.categories.isEmpty {
                        card("By category") {
                            donut(slices, total: stats.spent)
                            breakdown(stats.categories, slices: slices).padding(.top, 16)
                        }
                    }
                    if !stats.top.isEmpty { card("Top expenses", padded: false) { topList(stats.top) } }

                    HStack(spacing: 6) {
                        exportButton("Excel", .xlsx, r)
                        exportButton("CSV", .csv, r)
                    }
                    .padding(.top, 28)
                }

                if kind == .month && offset == 0 && budget?.total == nil {
                    Button("Set a monthly budget in Settings ›") { showSettings() }
                        .font(.tFootnote).foregroundStyle(Theme.sub)
                        .frame(maxWidth: .infinity).padding(.top, 24)
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 32)
        }
        .background(Theme.canvas)
        .sheet(item: $shareURL) { ShareSheet(items: [$0.url]) }
    }

    // MARK: - Pieces

    private func clearSelection() { selectedBar = nil; selectedCategory = nil; selectedAngle = nil }

    @ViewBuilder private func periodNav(_ r: DateRange) -> some View {
        if kind == .custom {
            HStack {
                DatePicker("", selection: $customFrom, in: ...customTo, displayedComponents: .date).labelsHidden()
                Text("–").foregroundStyle(Theme.sub)
                DatePicker("", selection: $customTo, in: customFrom..., displayedComponents: .date).labelsHidden()
            }
            .frame(maxWidth: .infinity)
        } else {
            HStack {
                navButton("chevron.left", disabled: false) { offset -= 1 }
                Spacer()
                Text(r.label).font(.system(size: 16, weight: .semibold))
                Spacer()
                navButton("chevron.right", disabled: offset >= 0) { offset += 1 }
            }
        }
    }

    private func navButton(_ icon: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            clearSelection()
            action()
        } label: {
            Image(systemName: icon).font(.system(size: 15, weight: .bold)).frame(width: 40, height: 40)
                .background(Circle().fill(Theme.raised))
        }
        .foregroundStyle(.white)
        .disabled(disabled)
        .opacity(disabled ? 0.25 : 1)
    }

    private func statTile(_ label: String, _ value: String) -> some View {
        statTile(label, value, big: false) { EmptyView() }
    }

    private func statTile<Extra: View>(_ label: String, _ value: String, big: Bool, @ViewBuilder extra: () -> Extra) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.tFootnote).foregroundStyle(Theme.sub)
            Text(value).font(.system(size: big ? 32 : 20, weight: .bold)).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.6)
            extra()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).fill(Theme.card))
    }

    private func card(_ title: String, padded: Bool = true, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: title)
            VStack(alignment: .leading, spacing: 0) { content() }
                .padding(padded ? 16 : 0)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).fill(Theme.card))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        }
        .padding(.top, 28)
    }

    private func budgetBar(_ b: BudgetLine, label: String, big: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).font(.system(size: big ? 16 : 15, weight: .semibold)).lineLimit(1)
                Spacer()
                Text("\(Fmt.money(b.spent, base)) / \(Fmt.money(b.amount, base))").font(.tFootnote).monospacedDigit()
                    .foregroundStyle(b.over ? Theme.danger : Theme.sub)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.raised)
                    Capsule().fill(b.over ? Theme.danger : .white).frame(width: g.size.width * min(1, b.pct))
                }
            }
            .frame(height: big ? 10 : 6)
            Text(b.over ? "⚠︎ Over budget by \(Fmt.money(-b.remaining, base))" : "\(Fmt.money(b.remaining, base)) left · \(Fmt.money(b.perDay, base))/day")
                .font(.system(size: 13, weight: b.over ? .semibold : .regular))
                .foregroundStyle(b.over ? Theme.danger : Theme.sub)
        }
    }

    private func barChart(_ buckets: [Bucket]) -> some View {
        let sel = buckets.first { b in selectedBar.map { $0 >= b.start && $0 < b.end } ?? false }
        let every = buckets.count <= 12 ? 1 : buckets.count <= 31 ? 5 : Int(ceil(Double(buckets.count) / 6))
        return VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(sel?.long ?? "Tap a bar for details").font(.tFootnote).foregroundStyle(Theme.sub)
                Text(sel.map { Fmt.money($0.total, base) } ?? " ").font(.tHeadline).monospacedDigit()
            }
            Chart(Array(buckets.enumerated()), id: \.element.id) { i, b in
                BarMark(x: .value("Period", b.start, unit: buckets.count > 45 || kind == .year ? .month : .day),
                        y: .value("Spent", b.total), width: .ratio(0.62))
                    .cornerRadius(4, style: .continuous)
                    .foregroundStyle(sel == nil || sel?.id == b.id ? (sel?.id == b.id ? Color.white : Theme.sub) : Theme.sub.opacity(0.35))
            }
            .chartXSelection(value: $selectedBar)
            .chartXAxis {
                AxisMarks(values: buckets.enumerated().filter { $0.offset % every == 0 }.map(\.element.start)) { v in
                    AxisValueLabel {
                        if let d = v.as(Date.self), let b = buckets.first(where: { $0.start == d }) {
                            Text(b.short).font(.system(size: 10)).foregroundStyle(Theme.sub)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 4])).foregroundStyle(Theme.well)
                    AxisValueLabel { if let d = v.as(Double.self) { Text(Fmt.compact(d)).font(.system(size: 10)).foregroundStyle(Theme.faint) } }
                }
            }
            .frame(height: 170)
        }
    }

    static func fold(_ cats: [CategoryTotal]) -> [CategoryTotal] {
        guard cats.count > 7 else { return cats }
        let rest = cats.dropFirst(6)
        return Array(cats.prefix(6)) + [CategoryTotal(categoryId: "__rest", total: rest.map(\.total).reduce(0, +), pct: rest.map(\.pct).reduce(0, +))]
    }

    private func donut(_ slices: [CategoryTotal], total: Double) -> some View {
        let active = slices.first { $0.categoryId == selectedCategory }
        return Chart(Array(slices.enumerated()), id: \.element.id) { i, s in
            SectorMark(angle: .value("Spent", s.total), innerRadius: .ratio(0.64), angularInset: 1.5)
                .foregroundStyle(Self.greys[min(i, Self.greys.count - 1)])
                .opacity(selectedCategory == nil || selectedCategory == s.categoryId ? 1 : 0.25)
        }
        .chartLegend(.hidden)
        .chartAngleSelection(value: $selectedAngle)
        .onChange(of: selectedAngle) { _, angle in
            guard let angle else { return }
            var acc = 0.0
            for s in slices {
                acc += s.total
                if angle <= acc {
                    selectedCategory = selectedCategory == s.categoryId ? nil : s.categoryId
                    Haptics.selection()
                    break
                }
            }
        }
        .frame(height: 210)
        .overlay {
            VStack(spacing: 2) {
                Text(active.map(sliceName) ?? "Spent").font(.tFootnote).foregroundStyle(Theme.sub).lineLimit(1)
                Text(Fmt.money(active?.total ?? total, base)).font(.system(size: 18, weight: .bold)).monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.6)
                if let active { Text("\(Int((active.pct * 100).rounded()))%").font(.tFootnote).foregroundStyle(Theme.sub) }
            }
            .frame(width: 120)
        }
    }

    private func sliceName(_ s: CategoryTotal) -> String {
        s.categoryId == "__rest" ? "Others" : (category(s.categoryId)?.name ?? "Other")
    }

    private func breakdown(_ cats: [CategoryTotal], slices: [CategoryTotal]) -> some View {
        VStack(spacing: 12) {
            ForEach(cats) { c in
                let idx = slices.firstIndex { $0.categoryId == c.categoryId } ?? (slices.count - 1)
                let key = slices.contains { $0.categoryId == c.categoryId } ? c.categoryId : "__rest"
                let cat = category(c.categoryId)
                Button {
                    Haptics.selection()
                    selectedCategory = selectedCategory == key ? nil : key
                } label: {
                    HStack(spacing: 10) {
                        Circle().fill(Self.greys[min(idx, Self.greys.count - 1)]).frame(width: 10, height: 10)
                        Text(cat?.emoji ?? "✨").font(.system(size: 18))
                        VStack(spacing: 6) {
                            HStack {
                                Text(cat?.name ?? "Other").font(.tBodySemibold).lineLimit(1)
                                Spacer()
                                Text(Fmt.money(c.total, base)).font(.tBody).monospacedDigit()
                            }
                            HStack(spacing: 8) {
                                GeometryReader { g in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Theme.raised)
                                        Capsule().fill(Theme.sub).frame(width: g.size.width * c.pct)
                                    }
                                }
                                .frame(height: 4)
                                Text("\(Int((c.pct * 100).rounded()))%").font(.tFootnote).foregroundStyle(Theme.sub).frame(width: 40, alignment: .trailing)
                            }
                        }
                    }
                    .opacity(selectedCategory == nil || selectedCategory == key ? 1 : 0.4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func topList(_ top: [Entry]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(top.enumerated()), id: \.element.id) { i, e in
                let c = category(e.categoryId)
                HStack(spacing: 12) {
                    EmojiCircle(emoji: c?.emoji ?? "✨", colorHex: c?.colorHex ?? "#9DB0C4", size: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(e.note.isEmpty ? (c?.name ?? "Other") : e.note).font(.tBodySemibold).lineLimit(1)
                        Text("\(c?.name ?? "Other") · \(Fmt.shortDate.string(from: e.date)), \(Fmt.time.string(from: e.date))")
                            .font(.tFootnote).foregroundStyle(Theme.sub)
                    }
                    Spacer()
                    Text(Fmt.money(e.amountInBase, base)).font(.system(size: 15, weight: .bold)).monospacedDigit()
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                if i < top.count - 1 { Rectangle().fill(Theme.well).frame(height: 0.5).padding(.leading, 16) }
            }
        }
    }

    private func exportButton(_ title: String, _ kind: ExportKind, _ r: DateRange) -> some View {
        Button {
            exporting = kind
            Task {
                defer { exporting = nil }
                do { shareURL = ShareItem(url: try Exporter.export(kind, range: r)) }
                catch { ToastCenter.shared.error(error.localizedDescription) }
            }
        } label: {
            HStack(spacing: 8) {
                if exporting == kind { ProgressView().tint(.white) } else { Image(systemName: "square.and.arrow.up") }
                Text(title)
            }
            .font(.tBodySemibold)
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.raised))
        }
        .buttonStyle(PressableStyle())
    }
}

struct ShareItem: Identifiable {
    let url: URL
    var id: URL { url }
}

/// UIKit share sheet (Save to Files, AirDrop, Mail, Numbers…).
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
