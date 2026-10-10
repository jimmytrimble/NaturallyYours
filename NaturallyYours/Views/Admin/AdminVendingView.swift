import SwiftUI

/// Admin list of vending machines, grouped by campus, with the ability to add machines
/// and drill into each machine's slot inventory.
struct AdminVendingView: View {
    @Environment(AdminService.self) private var adminService

    @State private var machines: [VendingMachine] = []
    @State private var isLoading = false
    @State private var showNewMachine = false
    @State private var errorMessage: String?
    @State private var showError = false

    private var campuses: [String] {
        Array(Set(machines.map(\.campus))).sorted()
    }

    var body: some View {
        List {
            if machines.isEmpty && !isLoading {
                ContentUnavailableView {
                    Label("No Vending Machines", systemImage: "cabinet")
                } description: {
                    Text("Add a machine to start tracking its on-hand stock by campus.")
                } actions: {
                    Button("Add Machine") { showNewMachine = true }
                        .buttonStyle(.borderedProminent).tint(.nyPink)
                }
            } else {
                ForEach(campuses, id: \.self) { campus in
                    Section(campus) {
                        ForEach(machines.filter { $0.campus == campus }) { machine in
                            NavigationLink {
                                AdminVendingMachineView(machineID: machine.id, onChange: { Task { await load() } })
                            } label: {
                                machineRow(machine)
                            }
                        }
                    }
                }
            }
        }
        .overlay { if isLoading && machines.isEmpty { ProgressView() } }
        .navigationTitle("Vending")
        .navigationBarTitleDisplayMode(.inline)
        .adminToolbar()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { showNewMachine = true } label: {
                    Image(systemName: "plus").foregroundStyle(.nyPink)
                }
            }
        }
        .sheet(isPresented: $showNewMachine, onDismiss: { Task { await load() } }) {
            AdminVendingMachineEditSheet()
                .environment(adminService)
        }
        .alert("Something went wrong", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: { Text(errorMessage ?? "Please try again.") }
        .task { await load() }
        .refreshable { await load() }
    }

    private func machineRow(_ machine: VendingMachine) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(machine.name)
                .font(.nyBody(15)).fontWeight(.semibold).foregroundStyle(.nyBlack)
            HStack(spacing: 10) {
                if let loc = machine.location, !loc.isEmpty {
                    Text(loc)
                }
                Text("\(machine.slotCount) slots")
                if machine.needsRestockCount > 0 {
                    Label("\(machine.needsRestockCount) low", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.nyWarning)
                }
            }
            .font(.nyCaption(12))
            .foregroundStyle(.nyGray)
        }
        .padding(.vertical, 2)
    }

    private func load() async {
        isLoading = true
        do { machines = try await adminService.loadVendingMachines() }
        catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

// MARK: - New / edit machine

struct AdminVendingMachineEditSheet: View {
    @Environment(AdminService.self) private var adminService
    @Environment(\.dismiss) private var dismiss

    /// When set, edits an existing machine; otherwise creates a new one.
    var existing: VendingMachine? = nil

    @State private var name = ""
    @State private var campus = ""
    @State private var location = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !campus.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Machine") {
                    TextField("Name (e.g. Student Center)", text: $name)
                    TextField("Campus", text: $campus)
                    TextField("Location / notes (optional)", text: $location)
                }
            }
            .navigationTitle(existing == nil ? "New Machine" : "Edit Machine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!isValid || isSaving)
                }
            }
            .alert("Couldn't Save", isPresented: $showError) {
                Button("OK") { showError = false }
            } message: { Text(errorMessage ?? "Please try again.") }
            .onAppear {
                if let existing {
                    name = existing.name
                    campus = existing.campus
                    location = existing.location ?? ""
                }
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                let loc = location.isEmpty ? nil : location
                if let existing, let id = existing.id {
                    _ = try await adminService.updateVendingMachine(
                        id: id, UpdateVendingMachineRequest(name: name, campus: campus, location: loc))
                } else {
                    _ = try await adminService.createVendingMachine(
                        CreateVendingMachineRequest(name: name, campus: campus, location: loc))
                }
                dismiss()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                showError = true
            }
            isSaving = false
        }
    }
}
