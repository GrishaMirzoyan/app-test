import SwiftUI
import UniformTypeIdentifiers
import LearningGateCore

/// Lists imported decks and offers CSV / Anki .apkg import.
struct DeckListView: View {
    @EnvironmentObject private var services: AppServices
    @State private var decks: [Deck] = []
    @State private var importing = false
    @State private var importError: String?

    /// Allowed import types: CSV/text and Anki packages (matched by extension).
    private var allowedTypes: [UTType] {
        var types: [UTType] = [.commaSeparatedText, .plainText, .text]
        if let apkg = UTType(filenameExtension: "apkg") { types.append(apkg) }
        return types
    }

    var body: some View {
        NavigationStack {
            Group {
                if decks.isEmpty {
                    ContentUnavailableView {
                        Label("No decks yet", systemImage: "rectangle.stack.badge.plus")
                    } description: {
                        Text("Import a CSV or Anki .apkg deck to start earning breaks.")
                    } actions: {
                        Button("Import deck") { importing = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(decks) { deck in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(deck.name).font(.headline)
                            Text("\(deck.cards.count) card\(deck.cards.count == 1 ? "" : "s")")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Decks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { importing = true } label: { Image(systemName: "plus") }
                }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: allowedTypes) { result in
                handleImport(result)
            }
            .alert("Import failed", isPresented: .constant(importError != nil)) {
                Button("OK") { importError = nil }
            } message: {
                Text(importError ?? "")
            }
            .onAppear(perform: reload)
        }
    }

    private func reload() {
        decks = (try? services.cardStore.allDecks()) ?? []
    }

    private func handleImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            // Security-scoped access is required for files picked outside our sandbox.
            let needsStop = url.startAccessingSecurityScopedResource()
            defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            try services.localDeckSource.importFile(named: url.lastPathComponent, data: data)
            reload()
        } catch let error as LearningGateError {
            importError = describe(error)
        } catch {
            importError = error.localizedDescription
        }
    }

    private func describe(_ error: LearningGateError) -> String {
        switch error {
        case .importFailed(let message): return message
        case .storageFailed(let message): return "Couldn’t save: \(message)"
        case .deckNotFound, .cardNotFound: return "Something went wrong importing this deck."
        }
    }
}
