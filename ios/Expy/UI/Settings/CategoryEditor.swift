import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Name, colour and emoji for a debit or credit category.
struct CategoryEditor: View {
    let category: ExpenseCategory?
    /// Kind for a new category; an existing one keeps its own.
    var kind = TransactionKind.expense
    @State private var name = ""
    @State private var emoji = "✨"
    @State private var color = Defaults.categoryColors[0]
    @State private var typed = ""
    @Environment(\.dismiss) private var dismiss

    private func pickColor(_ c: String) {
        color = c
        Haptics.selection()
    }

    private func pickEmoji(_ e: String) {
        emoji = e
        Haptics.selection()
    }

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
                                Button { pickColor(c) } label: {
                                    Circle().fill(Color(hex: c)).frame(width: 32, height: 32)
                                        .overlay(Circle().stroke(Color(hex: c), lineWidth: 2).padding(-4).opacity(c == color ? 1 : 0))
                                        .frame(width: 44, height: 44)
                                }
                                .accessibilityLabel("Color \(c)")
                                .accessibilityAddTraits(c == color ? .isSelected : [])
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
                                Button { pickEmoji(e) } label: {
                                    Text(e).font(.app(26))
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(e == emoji ? Theme.well : .clear))
                                }
                                .accessibilityAddTraits(e == emoji ? .isSelected : [])
                            }
                        }
                    }
                }
                .padding(Theme.gutter)
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: category == nil ? "Add category" : "Save") {
                    DataStore.shared.saveCategory(id: category?.id, kind: category?.kind ?? kind, name: String(name.trimmingCharacters(in: .whitespaces).prefix(40)), emoji: emoji, colorHex: color)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, Theme.gutter).padding(.bottom, 8)
            }
            .navigationTitle(category == nil ? (kind == .credit ? "New credit category" : "New debit category") : "Edit category")
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
