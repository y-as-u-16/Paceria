import SwiftUI

struct AddMovementView: View {
    @State private var viewModel: AddMovementViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: AddMovementViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("movement.field.type") {
                    typePicker
                }

                Section {
                    DatePicker("movement.field.performedAt", selection: $viewModel.performedAt)
                    durationField
                } header: {
                    Text("movement.section.detail")
                } footer: {
                    Text("movement.section.detail.footer")
                }

                Section("movement.field.note") {
                    TextField("movement.field.note.placeholder", text: $viewModel.note, axis: .vertical)
                        .lineLimit(1...3)
                }

                if let error = viewModel.error {
                    Label(error.messageKey, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("movement.add.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        Task {
                            if await viewModel.save() { dismiss() }
                        }
                    }
                    .disabled(viewModel.isSaving)
                    .accessibilityIdentifier("movement.save")
                }
            }
        }
    }

    private var typePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                ForEach(MovementType.allCases, id: \.self) { type in
                    Button {
                        viewModel.type = type
                    } label: {
                        Label(type.labelKey, systemImage: type.symbolName)
                            .frame(minHeight: Layout.minimumTouchTarget)
                    }
                    // 選択の強調は System の Button Hierarchy に委ねる。
                    // 独自 Background を敷くと新しい Control Shape を妨げる。
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(viewModel.type == type ? .accentColor : .secondary)
                    // 選択状態を色だけで示さない（04_MVP_AND_ROADMAP.md §11）。
                    .accessibilityAddTraits(viewModel.type == type ? [.isSelected] : [])
                    .accessibilityIdentifier("movement.type.\(type.rawValue)")
                }
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    private var durationField: some View {
        HStack {
            Text("movement.field.duration")
            Spacer()
            TextField(
                "movement.field.duration.placeholder",
                value: $viewModel.durationMinutes,
                format: .number
            )
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .accessibilityIdentifier("movement.duration")
        }
    }
}
