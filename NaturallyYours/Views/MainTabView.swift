import SwiftUI

/// Root tab bar for the signed-in / guest storefront experience. Owns the shared
/// services and injects them (plus `AuthService`) into the environment so every
/// screen can reach the same cart, favorites, catalog, and messaging state.
struct MainTabView: View {
    @ObservedObject var authService: AuthService

    @State private var productService = ProductService()
    @State private var cart = CartStore()
    @State private var favorites = FavoritesStore()
    @State private var messaging = MessagingService()

    @State private var selection: Tab = .home

    enum Tab: Hashable {
        case home, shop, cart, favorites, account
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView(authService: authService)
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.home)

            NavigationStack {
                ShopView()
            }
            .tabItem { Label("Shop", systemImage: "bag") }
            .tag(Tab.shop)

            CartView()
                .tabItem { Label("Cart", systemImage: "cart") }
                .tag(Tab.cart)
                .badge(cart.itemCount)

            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart") }
                .tag(Tab.favorites)

            AccountView()
                .tabItem { Label("Account", systemImage: "person") }
                .tag(Tab.account)
        }
        .tint(.nyPink)
        .environment(productService)
        .environment(cart)
        .environment(favorites)
        .environment(messaging)
        .environmentObject(authService)
        .task {
            await productService.loadProducts()
            await cart.refresh()
            if authService.isAuthenticated {
                await favorites.refresh()
            }
        }
    }
}
