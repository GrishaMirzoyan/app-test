import SwiftUI
import LearningGateCore

/// One lesson, Duolingo-style: a progress bar, one exercise at a time,
/// instant feedback, and a completion screen that shows the earned minute(s)
/// and offers to unlock the gated apps with the banked time.
struct LessonView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: LessonViewModel

    init(lesson: Lesson, services: AppServices) {
        _model = StateObject(wrappedValue: LessonViewModel(lesson: lesson, services: services))
    }

    var body: some View {
        NavigationStack {
            content
                .padding()
                .navigationTitle(model.lessonTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
        }
        .interactiveDismissDisabled(model.feedback != nil)
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .exercising:
            exercising
        case let .completed(earnedMinutes, bankedMinutes):
            completed(earned: earnedMinutes, banked: bankedMinutes)
        case let .unlocked(minutes):
            unlocked(minutes: minutes)
        }
    }

    // MARK: - Exercising

    @ViewBuilder
    private var exercising: some View {
        if let exercise = model.currentExercise {
            VStack(spacing: 20) {
                ProgressView(value: model.progress)

                Text(instruction(for: exercise))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                promptCard(for: exercise)
                answerArea(for: exercise)
                Spacer(minLength: 0)
                footer
            }
        }
    }

    private func instruction(for exercise: Exercise) -> String {
        switch exercise.kind {
        case .choice: return "Choose the right answer"
        case .wordOrder: return "Build the sentence"
        case .typeAnswer: return "Type the answer in English"
        }
    }

    private func promptCard(for exercise: Exercise) -> some View {
        let prompt: String
        switch exercise.kind {
        case let .choice(text, _, _), let .wordOrder(text, _, _), let .typeAnswer(text, _, _):
            prompt = text
        }
        return Text(prompt)
            .font(prompt.count <= 3 ? .system(size: 64) : .title2.bold())
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func answerArea(for exercise: Exercise) -> some View {
        switch exercise.kind {
        case let .choice(_, choices, _):
            choiceButtons(choices)
        case .wordOrder:
            wordOrderArea
        case .typeAnswer:
            TextField("Your answer", text: $model.typedAnswer)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { model.submit() }
        }
    }

    private func choiceButtons(_ choices: [String]) -> some View {
        VStack(spacing: 8) {
            ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                Button {
                    model.selectedChoiceIndex = index
                } label: {
                    Text(choice).frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(model.selectedChoiceIndex == index ? .accentColor : .secondary)
            }
        }
    }

    private var wordOrderArea: some View {
        VStack(spacing: 16) {
            // The sentence being built.
            chipRow(model.arrangedChips, emptyHint: "Tap the words below") { chip in
                model.returnChip(chip)
            }
            Divider()
            // The remaining word bank.
            chipRow(model.bankChips, emptyHint: "") { chip in
                model.pickChip(chip)
            }
        }
    }

    private func chipRow(
        _ chips: [LessonViewModel.WordChip],
        emptyHint: String,
        onTap: @escaping (LessonViewModel.WordChip) -> Void
    ) -> some View {
        Group {
            if chips.isEmpty {
                Text(emptyHint)
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, minHeight: 40)
            } else {
                FlowingChips(chips: chips, onTap: onTap)
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch model.feedback {
        case nil:
            Button {
                model.submit()
            } label: {
                Text("Check").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.canSubmit)
        case .correct:
            feedbackBanner(
                title: "Correct!", detail: nil,
                color: .green, systemImage: "checkmark.circle.fill"
            )
        case .incorrect(let correctAnswer):
            feedbackBanner(
                title: "Not quite — you'll see it again", detail: correctAnswer,
                color: .red, systemImage: "xmark.circle.fill"
            )
        }
    }

    private func feedbackBanner(
        title: String, detail: String?, color: Color, systemImage: String
    ) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    if let detail {
                        Text("Answer: \(detail)").font(.subheadline)
                    }
                }
                Spacer()
            }
            .foregroundStyle(color)

            Button {
                model.continueAfterFeedback()
            } label: {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(color)
        }
        .padding()
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Completion

    private func completed(earned: Int, banked: Int) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "party.popper")
                .font(.system(size: 56)).foregroundStyle(.tint)
            Text("Lesson complete 🎉").font(.title2.bold())
            Text("+\(earned) minute\(earned == 1 ? "" : "s") earned")
                .font(.headline)
            Text("You have \(banked) minute\(banked == 1 ? "" : "s") of app time banked.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()

            Button {
                model.unlockApps()
            } label: {
                Text("Unlock my apps · \(banked) min").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(banked == 0)

            Button {
                dismiss()
            } label: {
                Text("Keep learning").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private func unlocked(minutes: Int) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "lock.open.fill")
                .font(.system(size: 56)).foregroundStyle(.tint)
            Text("Apps unlocked").font(.title2.bold())
            Text("Enjoy your \(minutes) minute\(minutes == 1 ? "" : "s") — the gate comes back after that.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Done").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

/// Simple wrapping chip layout for the word bank.
private struct FlowingChips: View {
    let chips: [LessonViewModel.WordChip]
    let onTap: (LessonViewModel.WordChip) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(chips) { chip in
                Button {
                    onTap(chip)
                } label: {
                    Text(chip.word)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.thinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Minimal left-to-right wrapping layout (iOS 16+ `Layout`).
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let width = proposal.width ?? rows.map(\.width).max() ?? 0
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in computeRows(proposal: proposal, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var current = Row()
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.indices.append(index)
            current.height = max(current.height, size.height)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
