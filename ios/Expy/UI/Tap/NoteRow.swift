import SwiftUI

/// "+ add note" with one-tap recent notes, or the note field once opened.
struct NoteRow: View {
    @Bindable var model: TapModel
    let recentNotes: [String]
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            if model.noteOpen {
                TextField("Add a note", text: $model.note)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(finishNote)
                    .font(.app(13))
            } else {
                Button("+ add note", action: openNote)
                    .font(.app(13)).foregroundStyle(Theme.sub)
                    .frame(minHeight: 44)
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(recentNotes, id: \.self) { n in
                            RecentNoteChip(text: n) { model.useNote(n) }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .excludedFromPageSwipe()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.gutter)
    }

    private func openNote() {
        model.noteOpen = true
        focused = true
    }

    private func finishNote() {
        focused = false
        if model.note.trimmingCharacters(in: .whitespaces).isEmpty { model.noteOpen = false }
    }
}
