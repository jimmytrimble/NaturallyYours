import SwiftUI

/// Manage a single vending machine's slot inventory: adjust on-hand counts, edit/add/
/// remove slots. `onChange` lets the parent list refresh its restock badges.
struct AdminVendingMachineView: View {
    let machineID: UUID?
    var onChange: () -> Void = {}

    @Environment(AdminService.self) private var adminService

    @State private var machine: VendingMachine?
    @State private var isLoading = false
    @State private var showAddSlot = false
    @State private var editingSlot: VendingSlot?
    @State private var showEditMachine = false
    @State private var busyIDs: Set<UUID> = []
    @State private var errorMessage: String?
    @State private var showError = false

    private var slots: [VendingSlot] {
        (machine?.slots ?? []).sorted { $0.slotNumber < $1.slotNumber }
    }

    var body: some View {
        List {
            if let machine {
                Section {
                    summaryRow(machine)
                }
            }
            Section("Slots (\(slots.count))") {
                if slots.isEmpty {
                    Text("No slots yet. Add one to start tracking stock.")
                        .font(.nyBody(14)).foregroundStyle(.nyGray)
                } else {
                    ForEach(slots) { slot in
                        slotRow(slot)
                    }
                }
            }
        }
        .overlay { if isLoading && machine == nil { ProgressView() } }
        .navigationTitle(machine?.name ?? "Machine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showAddSlot = true } label: { Label("Add Slot", systemImage: "plus") }
                    Button { showEditMachine = true } label: { Label("Edit Machine", systemImage: "pencil") }
                    if let machine {
                        Button(role: .destructive) { deleteMachine(machine) } label: {
                            Label("Delete Machine", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundStyle(.nyPink)
                }
            }
        }
        .sheet(isPresented: $showAddSlot, onDismiss: { Task { await load() } }) {
            AdminVendingSlotEditSheet(machineID: machineID, slot: nil)
                .environment(adminService)
        }
        .sheet(item: $editingSlot, onDismiss: { Task { await load() } }) { slot in
            AdminVendingSlotEditSheet(machineID: machineID, slot: slot)
                .environment(adminService)
        }
        .sheet(isPresented: $showEditMachine, onDismiss: { Task { await load() } }) {
            AdminVendingMachineEditSheet(existing: machine)
                .environment(adminService)
        }
        .alert("Something went wrong", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: { Text(errorMessage ?? "Please try again.") }
        .task { await load() }
        .refreshable { await load() }
    }

    private func summaryRow(_ machine: VendingMachine) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(machine.campus)\(machine.location.map { " · \($0)" } ?? "")")
                .font(.nyBody(14)).foregroundStyle(.nyGray)
            if machine.needsRestockCount > 0 {
                Label("\(machine.needsRestockCount) slot(s) need restocking", systemImage: "exclamationmark.triangle.fill")
                    .font(.nyCaption(13)).foregroundStyle(.nyWarning)
            }
        }
    }

    private func slotRow(_ slot: VendingSlot) -> some View {
        HStack(spacing: 12) {
            Text("\(slot.slotNumber)")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(.nyPink)
                .frame(width: 34, height: 34)
                .background(Color.nySoftPink)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(slot.productName)
                    .font(.nyBody(15)).foregroundStyle(.nyBlack).lineLimit(1)
                Text("On hand \(slot.onHand) · Hold \(slot.hold)")
                    .font(.nyCaption(12))
                    .foregroundStyle(slot.needsRestock ? .nyWarning : .nyGray)
            }

            Spacer()

            if let id = slot.id, busyIDs.contains(id) {
                ProgressView()
            } else {
                // Quick on-hand adjust (the common restocking action).
                HStack(spacing: 14) {
                    Button { adjust(slot, by: -1) } label: {
                        Image(systemName: "minus.circle").foregroundStyle(.nyGray)
                    }
                    .buttonStyle(.plain)
                    .disabled(slot.onHand <= 0)
                    Button { adjust(slot, by: 1) } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(.nyPink)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { editingSlot = slot }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { deleteSlot(slot) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Actions

    private func load() async {
        guard let machineID else { return }
        isLoading = true
        do { machine = try await adminService.vendingMachine(id: machineID) }
        catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            showError = true
        }
        isLoading = false
        onChange()
    }

    private func adjust(_ slot: VendingSlot, by delta: Int) {
        guard let id = slot.id else { return }
        let newValue = max(0, slot.onHand + delta)
        busyIDs.insert(id)
        Task {
            do {
                _ = try await adminService.updateVendingSlot(id: id, UpdateVendingSlotRequest(onHand: newValue))
                await load()
            } catch { present(error) }
            busyIDs.remove(id)
        }
    }

    private func deleteSlot(_ slot: VendingSlot) {
        guard let id = slot.id else { return }
        Task {
            do { try await adminService.deleteVendingSlot(id: id); await load() }
            catch { present(error) }
        }
    }

    private func deleteMachine(_ machine: VendingMachine) {
        guard let id = machine.id else { return }
        Task {
            do { try await adminService.deleteVendingMachine(id: id); onChange() }
            catch { present(error) }
        }
    }

    private func present(_ error: Error) {
        errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        showError = true
    }
}

// MARK: - Add / edit slot

struct AdminVendingSlotEditSheet: View {
    let machineID: UUID?
    let slot: VendingSlot?

    @Environment(AdminService.self) private var adminService
    @Environment(\.dismiss) private var dismiss

    @State private var slotNumber = ""
    @State private var productName = ""
    @State private var onHand = ""
    @State private var hold = "10"
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false

    private var isValid: Bool {
        Int(slotNumber) != nil &&
        !productName.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(onHand) != nil && Int(hold) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Slot") {
                    TextField("Slot number", text: $slotNumber).keyboardType(.numberPad)
                    TextField("Product name", text: $productName)
                }
                Section("Stock") {
                    TextField("On hand", text: $onHand).keyboardType(.numberPad)
                    TextField("Hold (par)", text: $hold).keyboardType(.numberPad)
                }
                if slot != nil {
                    Section {
                        Button(role: .destructive) { delete() } label: {
                            Label("Delete Slot", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(slot == nil ? "Add Slot" : "Edit Slot")
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
                if let slot {
                    slotNumber = "\(slot.slotNumber)"
                    productName = slot.productName
                    onHand = "\(slot.onHand)"
                    hold = "\(slot.hold)"
                }
            }
        }
    }

    private func save() {
        guard let number = Int(slotNumber), let on = Int(onHand), let h = Int(hold) else { return }
        isSaving = true
        Task {
            do {
                if let slot, let id = slot.id {
                    _ = try await adminService.updateVendingSlot(
                        id: id,
                        UpdateVendingSlotRequest(slotNumber: number, productName: productName, onHand: on, hold: h)
                    )
                } else if let machineID {
                    _ = try await adminService.addVendingSlot(
                        machineID: machineID,
                        CreateVendingSlotRequest(slotNumber: number, productName: productName, onHand: on, hold: h)
                    )
                }
                dismiss()
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                showError = true
            }
            isSaving = false
        }
    }

    private func delete() {
        guard let slot, let id = slot.id else { return }
        Task {
            do { try await adminService.deleteVendingSlot(id: id); dismiss() }
            catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                showError = true
            }
        }
    }
}
