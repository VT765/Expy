import SwiftData
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Categories

/// "Tap a category to edit, drag to reorder." Emoji, name, red ✕, ≡ handle.
struct CategoriesSection: View {
    @Query(filter: #Predicate<ExpenseCategory> { $0.deletedAt == nil }, sort: \ExpenseCategory.order)
    private var categories: [ExpenseCategory]
    @State private var editing: EditTarget?
    @State private var deleting: ExpenseCategory?
    @State private var dragging: String?

    enum EditTarget: Identifiable {
        case new, existing(ExpenseCategory)
        var id: String { if case .existing(let c) = self { return c.id }; return "new" }
        var category: ExpenseCategory? { if case .existing(let c) = self { return c }; return nil }
    }

    var body: some View {
        SettingsSection(title: "Categories", hint: "Tap a category to edit, drag to reorder.") {
            VStack(spacing: 0) {
                ForEach(categories) { c in
                    row(c)
                    Rectangle().fill(Theme.well).frame(height: 0.5)
                }
                Button { editing = .new } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "plus").font(.system(size: 18, weight: .semibold)).frame(width: 30)
                        Text("Add category").font(.system(size: 16, weight: .semibold))
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).frame(height: 58)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).fill(Theme.card))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        }
        .sheet(item: $editing) { t in CategoryEditor(category: t.category) }
        .alert(item: $deleting) { c in
            let n = DataStore.shared.fetch(Entry.self).filter { $0.categoryId == c.id && $0.deletedAt == nil }.count
            return Alert(title: Text("Delete \(c.name)?"),
                         message: Text(n > 0 ? "\(n) \(n == 1 ? "entry moves" : "entries move") to Other." : ""),
                         primaryButton: .destructive(Text("Delete")) { DataStore.shared.deleteCategory(c) },
                         secondaryButton: .cancel())
        }
    }

    private func row(_ c: ExpenseCategory) -> some View {
        HStack(spacing: 0) {
            Button { editing = .existing(c) } label: {
                HStack(spacing: 16) {
                    Text(c.emoji).font(.system(size: 24)).frame(width: 30)
                    Text(c.name).font(.system(size: 16, weight: .semibold)).lineLimit(1)
                    Spacer()
                }
                .padding(.leading, 16).frame(height: 60)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if c.id != Defaults.otherCategoryId {
                Button { deleting = c } label: {
                    Image(systemName: "xmark").font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.danger).frame(width: 48, height: 60)
                }
                .accessibilityLabel("Delete \(c.name)")
            }
            Image(systemName: "line.3.horizontal").font(.system(size: 18, weight: .medium)).foregroundStyle(Theme.sub)
                .frame(width: 52, height: 60)
                .contentShape(Rectangle())
                .draggable(c.id) {
                    HStack { Text(c.emoji); Text(c.name).bold() }
                        .padding(12).background(Capsule().fill(Theme.raised))
                        .onAppear { dragging = c.id }
                }
                .accessibilityLabel("Drag to reorder")
        }
        .background(Theme.card)
        .opacity(dragging == c.id ? 0.4 : 1)
        .dropDestination(for: String.self) { ids, _ in
            defer { dragging = nil }
            guard let id = ids.first, id != c.id else { return false }
            var ordered = categories
            guard let from = ordered.firstIndex(where: { $0.id == id }), let to = ordered.firstIndex(where: { $0.id == c.id }) else { return false }
            let moved = ordered.remove(at: from)
            ordered.insert(moved, at: to)
            withAnimation(.spring(response: 0.3)) { DataStore.shared.reorderCategories(ordered) }
            Haptics.success()
            return true
        }
    }
}

struct CategoryEditor: View {
    let category: ExpenseCategory?
    @State private var name = ""
    @State private var emoji = "✨"
    @State private var color = Defaults.categoryColors[0]
    @State private var typed = ""
    @Environment(\.dismiss) private var dismiss

    private static let emojis = Array("🍔🍕🍜☕🍺🍰🥗🍱🛒🥦🍎🥛🚕🚗⛽🚌🚇🛵✈️🏨🧳🏖️🗺️🚲🛍️👕👟💄🎁💍📱💻🎧📦🪑🛋️🧾💡💧🔥📶🏠🔑🧹🧺🛠️🐶🌱💊🏥🦷🧘🏋️💇💅🧴👶🎓📚✏️🎬🎮🎵🎟️⚽🎨📺😎🎉💳🏦📈💰💸🤝❤️🙏🎗️🚬🍷👤⭐✨📌").map(String.init)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 12) {
                        EmojiCircle(emoji: emoji, colorHex: color, size: 52)
                        TextField("Category name", text: $name).fieldStyle()
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "Color")
                        FlowLayout(spacing: 10) {
                            ForEach(Defaults.categoryColors, id: \.self) { c in
                                Circle().fill(Color(hex: c)).frame(width: 32, height: 32)
                                    .overlay(Circle().stroke(Color(hex: c), lineWidth: 2).padding(-4).opacity(c == color ? 1 : 0))
                                    .onTapGesture { color = c; Haptics.selection() }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            SectionLabel(text: "Emoji")
                            TextField("Type any 🙂", text: $typed)
                                .multilineTextAlignment(.center)
                                .frame(width: 120, height: 36)
                                .background(Capsule().fill(Theme.raised))
                                .onChange(of: typed) { _, v in
                                    if let first = v.first(where: { $0.unicodeScalars.contains { $0.properties.isEmojiPresentation || $0.properties.isEmoji && $0.value > 0x238C } }) {
                                        emoji = String(first)
                                    }
                                    if !typed.isEmpty { typed = "" }
                                }
                        }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 8), spacing: 4) {
                            ForEach(Self.emojis, id: \.self) { e in
                                Text(e).font(.system(size: 26))
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(e == emoji ? Theme.well : .clear))
                                    .onTapGesture { emoji = e; Haptics.selection() }
                            }
                        }
                    }
                }
                .padding(Theme.gutter)
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: category == nil ? "Add category" : "Save") {
                    DataStore.shared.saveCategory(id: category?.id, name: String(name.trimmingCharacters(in: .whitespaces).prefix(40)), emoji: emoji, colorHex: color)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, Theme.gutter).padding(.bottom, 8)
            }
            .navigationTitle(category == nil ? "New category" : "Edit category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.tint(Theme.sub) } }
        }
        .presentationBackground(Theme.card)
        .onAppear {
            if let category {
                name = category.name; emoji = category.emoji; color = category.colorHex
            } else {
                color = Defaults.categoryColors.randomElement()!
            }
        }
    }
}

// MARK: - Category budgets

struct CategoryBudgetsView: View {
    @Query(filter: #Predicate<ExpenseCategory> { $0.deletedAt == nil }, sort: \ExpenseCategory.order)
    private var categories: [ExpenseCategory]
    @Query(filter: #Predicate<Budget> { $0.deletedAt == nil }) private var budgets: [Budget]
    @Query private var settingsList: [AppSettings]
    @State private var editing: ExpenseCategory?

    private var base: String { settingsList.first?.baseCurrency ?? "INR" }
    private func amount(_ id: String) -> Double { budgets.first { $0.categoryId == id }?.amount ?? 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text("Monthly limits per category. Progress shows on Analytics.")
                    .font(.tFootnote).foregroundStyle(Theme.sub).padding(.bottom, 10)
                ForEach(categories) { c in
                    let a = amount(c.id)
                    SettingsRow(title: "\(c.emoji)  \(c.name)", value: a > 0 ? Fmt.money(a, base) : "Not set") { editing = c }
                }
            }
            .padding(Theme.gutter)
        }
        .background(Theme.canvas)
        .navigationTitle("Category budgets")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { c in
            AmountSheet(title: "\(c.emoji) \(c.name)", currency: base, value: amount(c.id)) {
                DataStore.shared.setBudget(categoryId: c.id, amount: $0)
            }
        }
    }
}

// MARK: - Exchange rates

struct ExchangeRatesView: View {
    @Query private var settingsList: [AppSettings]
    @State private var editing: Currencies.Info?
    @State private var refreshing = false
    @State private var tick = 0 // re-render after refresh

    private var settings: AppSettings? { settingsList.first }
    private var base: String { settings?.baseCurrency ?? "INR" }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text("From Frankfurter · updated \(RatesService.shared.fetchedAt?.formatted(.relative(presentation: .named)) ?? "never"). Tap a rate to override it.")
                    .font(.tFootnote).foregroundStyle(Theme.sub).multilineTextAlignment(.center).padding(.bottom, 10)
                ForEach(Currencies.all.filter { $0.code != base }) { c in
                    let rate = DataStore.shared.rate(for: c.code)
                    let manual = settings?.rateOverrides[c.code] != nil
                    SettingsRow(title: "1 \(c.code)", subtitle: c.name, value: nil, chevron: false, action: { editing = c }) {
                        HStack(spacing: 6) {
                            if manual {
                                Text("manual").font(.system(size: 11, weight: .semibold))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(Theme.well))
                            }
                            Text(rate.map { "\(Currencies.symbol(base))\(String(format: $0 < 0.1 ? "%.4f" : "%.2f", $0))" } ?? "—")
                                .font(.tBody).foregroundStyle(Theme.sub).monospacedDigit()
                        }
                    }
                }
            }
            .padding(Theme.gutter)
            .id(tick)
        }
        .background(Theme.canvas)
        .navigationTitle("Exchange rates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(refreshing ? "Updating…" : "Refresh") {
                    refreshing = true
                    Task {
                        defer { refreshing = false; tick += 1 }
                        do { try await RatesService.shared.refresh(base: base, force: true); ToastCenter.shared.show("Rates updated") }
                        catch { ToastCenter.shared.error("Could not fetch rates") }
                    }
                }
                .disabled(refreshing)
                .tint(.white)
            }
        }
        .sheet(item: $editing) { c in
            AmountSheet(title: "1 \(c.code) in \(base)", hint: "Manual rates override the live rate for new and existing entries.",
                        currency: base, value: settings?.rateOverrides[c.code] ?? 0, removeLabel: "Use live") { v in
                DataStore.shared.updateSettings { s in
                    if v > 0 { s.rateOverrides[c.code] = v } else { s.rateOverrides.removeValue(forKey: c.code) }
                }
                DataStore.shared.rebaseEntries()
            }
        }
    }
}
