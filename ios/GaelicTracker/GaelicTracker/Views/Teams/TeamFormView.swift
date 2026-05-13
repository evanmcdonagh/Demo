import SwiftUI
import PhotosUI

struct TeamFormView: View {
    var editingTeam: Team?
    var onSave: (String, String, String, TeamFormat, Data?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var shortName: String = ""
    @State private var selectedColour: Color = .blue
    @State private var selectedFormat: TeamFormat = .fifteens
    @State private var crestImageData: Data?
    @State private var selectedPhoto: PhotosPickerItem?

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !shortName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Team Details") {
                    TextField("Team Name", text: $name)
                        .autocorrectionDisabled()

                    HStack {
                        TextField("Short Name (max 4)", text: $shortName)
                            .autocorrectionDisabled()
                            .autocapitalization(.allCharacters)
                            .onChange(of: shortName) { _, v in
                                if v.count > 4 { shortName = String(v.prefix(4)) }
                            }
                        Spacer()
                        Text("\(shortName.count)/4")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Picker("Format", selection: $selectedFormat) {
                        ForEach(TeamFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                }

                Section("Appearance") {
                    ColorPicker("Team Colour", selection: $selectedColour)

                    HStack {
                        Text("Team Crest")
                        Spacer()
                        if let data = crestImageData, let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label(crestImageData == nil ? "Add Crest" : "Change", systemImage: "photo")
                                .font(.subheadline)
                        }
                        if crestImageData != nil {
                            Button(role: .destructive) {
                                crestImageData = nil
                                selectedPhoto = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(editingTeam == nil ? "New Team" : "Edit Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            name.trimmingCharacters(in: .whitespaces),
                            shortName.trimmingCharacters(in: .whitespaces).uppercased(),
                            selectedColour.toHex(),
                            selectedFormat,
                            crestImageData
                        )
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let t = editingTeam {
                    name = t.name
                    shortName = t.shortName
                    selectedColour = Color(hex: t.colourHex)
                    selectedFormat = t.format
                    crestImageData = t.crestImageData
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    guard let item,
                          let data = try? await item.loadTransferable(type: Data.self),
                          let ui = UIImage(data: data) else { return }
                    crestImageData = ui.pngDataDownsampled(maxDimension: 256)
                }
            }
        }
    }
}
