import SwiftUI
import Combine

struct MainTabView: View {
    @StateObject private var tabRouter = AppTabRouter ()
    
    enum Tab {
        case home
        case shop
        case favorites
        case about
        case contact
    }
    
    private var selectedTab: Binding<Tab> {
        Binding(
            get: {
                switch tabRouter.selectedTab {
                case .home: return .home
                case .shop: return .shop
                case .favorites: return .favorites
                case .about: return .about
                case .contact: return .contact
                }
            },
            set: { newValue in
                switch newValue {
                case .home: tabRouter.selectedTab = .home
                case .shop : tabRouter.selectedTab = .shop
                case .favorites: tabRouter.selectedTab = .favorites
                case .about: tabRouter.selectedTab = .about
                case .contact: tabRouter.selectedTab = .contact
                }
            }
        )
    }
    
    var body: some View {
        
    }
}

