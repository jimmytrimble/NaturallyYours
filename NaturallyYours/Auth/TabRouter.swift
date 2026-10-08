import Combine
import SwiftUI

final class AppTabRouter: ObservableObject {
    
    enum Tab: Hashable {
        case home
        case shop
        case favorites
        case about
        case contact
    }
    
    @Published var selectedTab: Tab = .home
}
