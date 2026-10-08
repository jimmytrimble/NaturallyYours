//import Fluent
//import Vapor
//
//func routes(_ app: Application) throws {
//    app.get { req async in
//        "It works!"
//    }
//
//    app.get("hello") { req async -> String in
//        "Hello, world!"
//    }
//
//    try app.register(collection: TodoController())
//}
import Fluent
import Vapor

/// Configures authentication routes
public func routes(_ app: Application) throws {
    // Register authentication controllers
    try app.register(collection: UserAuthController())
    try app.register(collection: AdminAuthController())
    try app.register(collection: GuestCheckoutController())
    
    // Register e-commerce controllers
    try app.register(collection: ProductManagementController())
    try app.register(collection: CartController())
    try app.register(collection: FavoritesController())
    try app.register(collection: OrderController())
    try app.register(collection: AdminProductIOController())
    try app.register(collection: MessagingController())
}
