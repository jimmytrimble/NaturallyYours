import Vapor
import Fluent

/// Admin-only overview counts — handy for verifying a fresh deploy seeded correctly.
struct AdminStatsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let group = routes.grouped("api", "admin", "stats")
            .grouped(Admin.sessionAuthenticator())
            .grouped(AdminAuthenticatedMiddleware())
        group.get(use: stats)
    }

    func stats(req: Request) async throws -> AdminStatsDTO {
        let totalProducts = try await Product.query(on: req.db).count()
        let activeProducts = try await Product.query(on: req.db).filter(\.$isActive == true).count()
        let users = try await User.query(on: req.db).count()
        let admins = try await Admin.query(on: req.db).count()
        let orders = try await Order.query(on: req.db).count()
        let conversations = try await Conversation.query(on: req.db).count()
        let openConversations = try await Conversation.query(on: req.db).filter(\.$status == .open).count()

        return AdminStatsDTO(
            totalProducts: totalProducts,
            activeProducts: activeProducts,
            inactiveProducts: totalProducts - activeProducts,
            users: users,
            admins: admins,
            orders: orders,
            conversations: conversations,
            openConversations: openConversations
        )
    }
}

struct AdminStatsDTO: Content {
    let totalProducts: Int
    let activeProducts: Int
    let inactiveProducts: Int
    let users: Int
    let admins: Int
    let orders: Int
    let conversations: Int
    let openConversations: Int
}
