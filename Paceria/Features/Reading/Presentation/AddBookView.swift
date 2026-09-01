import SwiftUI

struct AddBookView: View {
    @State private var viewModel: AddBookViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFocused: Bool

    init(viewModel: AddBookViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("reading.field.title", text: $viewModel.title)
                        .focused($isTitleFocused)
                        .accessibilityIdentifier("book.title")
                    TextField("reading.field.author", text: $viewModel.author)
                        .accessibilityIdentifier("book.author")
                } footer: {
                    Text("reading.field.author.footer")
                }

                Section("reading.field.status") {
                    Picker("reading.field.status", selection: $viewModel.status) {
                        ForEach(ReadingStatus.displayOrder, id: \.self) { status in
                            Text(status.labelKey).tag(status)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                if let error = viewModel.error {
                    Label(error.messageKey, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(Typography.caption)
                }
            }
            .navigationTitle("reading.add.title")
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
                    .disabled(!viewModel.canSave || viewModel.isSaving)
                    .accessibilityIdentifier("book.save")
                }
            }
            // 手入力を30秒以内に終わらせるため、開いた直後から入力できる状態にする。
            .onAppear { isTitleFocused = true }
        }
    }
}
