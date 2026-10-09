//
//  AppConfiguration.swift
//  NaturallyYours
//
//  Created by Jamiel Trimble II on 5/28/26.
//

import Foundation

enum AppConfiguration {
    
    // MARK: - Environment
    
    enum Environment {
        case development
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
    }
    
    // MARK: - API Configuration
    
    static var apiBaseURL: String {
        switch Environment.current {
        case .development:
            // For iOS Simulator. Port 8081 because 8080 is taken by another app
            // on the dev Mac — keep this in sync with the port the Vapor server runs on.
            return "http://localhost:8081"

            // For physical device on same network, uncomment and use your Mac's IP:
            // return "http://192.168.1.5:8081"
            
        case .production:
            // Render web service URL. Update this to the exact URL Render assigns your
            // service after the first deploy (Dashboard → your service → top of page),
            // then attach your custom domain if desired.
            return "https://naturallyyours-server.onrender.com"
        }
    }
    
    // MARK: - App Information
    
    static let appName = "Naturally Yours"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Feature Flags
    
    static var enableGuestMode: Bool {
        true // Set to false to require login
    }
    
    static var enableAppleSignIn: Bool {
        false // Enable when implemented
    }
    
    static var enableGoogleSignIn: Bool {
        false // Enable when implemented
    }
    
    static var enableFacebookLogin: Bool {
        false // Enable when implemented
    }
    
    // MARK: - Network Configuration
    
    static let requestTimeout: TimeInterval = 30.0
    static let maxRetryAttempts = 3
    
    // MARK: - Debug Settings
    
    static var enableNetworkLogging: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var enableAnalytics: Bool {
        Environment.current == .production
    }
}
