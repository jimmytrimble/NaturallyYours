import SwiftUI

/// Admin order log with status management.
struct AdminOrdersView: View {
    @Environment(AdminService.self) private var adminService

    @State private var orders: [OrderDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        List {
            ForEach(orders) { order in
                NavigationLink {
                    AdminOrderDetailView(order: order) { updated in
                        if let idx = orders.firstIndex(where: { $0.id == updated.id }) {
                            orders[idx] = updated
                        }
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(order.orderNumber)
                                .font(.nyBody(15)).fontWeight(.semibold)
                                .foregroundStyle(.nyBlack)
                            Spacer()
                            Text(order.formattedTotal).foregroundStyle(.nyBlack)
                        }
                        HStack {
                            Text(order.customerName)
                            Spacer()
                            StatusTag(status: order.status)
                        }
                        .font(.nyCaption(12))
                        .foregroundStyle(.nyGray)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if isLoading && orders.isEmpty { ProgressView() }
            else if !isLoading && orders.isEmpty {
                ContentUnavailableView("No Orders", systemImage: "list.bullet.rectangle")
            }
        }
        .navigationTitle("Orders")
        .navigationBarTitleDisplayMode(.inline)
        .adminToolbar()
        .alert("Something went wrong", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        do {
            orders = try await adminService.loadOrders()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

struct StatusTag: View {
    let status: OrderStatus

    private var color: Color {
        switch status {
        case .paid: return .nySuccess
        case .fulfilled: return .nyPink
        case .pendingPayment: return .nyWarning
        case .cancelled, .refunded: return .nyError
        }
    }

    var body: some View {
        Text(status.displayName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Admin order detail

struct AdminOrderDetailView: View {
    let order: OrderDTO
    let onUpdate: (OrderDTO) -> Void

    @Environment(AdminService.self) private var adminService
    @State private var currentStatus: OrderStatus
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var showError = false

    init(order: OrderDTO, onUpdate: @escaping (OrderDTO) -> Void) {
        self.order = order
        self.onUpdate = onUpdate
        self._currentStatus = State(initialValue: order.status)
    }

    var body: some View {
        List {
            Section("Status") {
                HStack {
                    Text("Current")
                    Spacer()
                    if isUpdating { ProgressView() } else { StatusTag(status: currentStatus) }
                }
                Picker("Change status", selection: $currentStatus) {
                    ForEach(OrderStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                .onChange(of: currentStatus) { old, new in
                    if old != new { updateStatus(new) }
                }
            }

            Section("Customer") {
                labeledRow("Name", order.customerName)
                labeledRow("Email", order.email)
                if let phone = order.phone, !phone.isEmpty { labeledRow("Phone", phone) }
                if let note = order.customerNote, !note.isEmpty { labeledRow("Note", note) }
            }

            Section("Items") {
                ForEach(order.items) { item in
                    HStack {
                        Text(item.productName).font(.nyBody(14))
                        Spacer()
                        Text("×\(item.quantity)").foregroundStyle(.nyGray)
                        Text(item.formattedLineTotal)
                    }
                    .font(.nyBody(14))
                }
            }

            Section("Summary") {
                labeledRow("Subtotal", order.formattedSubtotal)
                labeledRow("Shipping", order.formattedShipping)
                labeledRow("Tax", order.formattedTax)
                labeledRow("Total", order.formattedTotal)
            }

            Section("Ship To") {
                VStack(alignment: .leading, spacing: 2) {
                    Text(order.shippingLine1)
                    if let l2 = order.shippingLine2, !l2.isEmpty { Text(l2) }
                    Text("\(order.shippingCity), \(order.shippingState) \(order.shippingPostalCode)")
                    Text(order.shippingCountry)
                }
                .font(.nyBody(14))
            }
        }
        .navigationTitle(order.orderNumber)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Couldn't Update", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private func labeledRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.nyGray)
            Spacer()
            Text(value).foregroundStyle(.nyBlack).multilineTextAlignment(.trailing)
        }
        .font(.nyBody(14))
    }

    private func updateStatus(_ status: OrderStatus) {
        guard let id = order.id else { return }
        isUpdating = true
        Task {
            do {
                let updated = try await adminService.updateOrderStatus(id: id, status: status)
                currentStatus = updated.status
                onUpdate(updated)
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
                showError = true
                currentStatus = order.status
            }
            isUpdating = false
        }
    }
}
