//
//  PathPalApp.swift
//  PathPal
//
//  Created by Suji Lee on 12/26/23.
//

import SwiftUI
import GoogleMaps
import Firebase
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
}

@main
struct PathPalApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        FirebaseApp.configure()
        if let GOOGLE_MAPS_API_KEY = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String {
            GMSServices.provideAPIKey(GOOGLE_MAPS_API_KEY)
        }
        //        if let GOOGLE_PLACES_API_KEY = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY") as? String {
        //            GMSPlacesClient.provideAPIKey(GOOGLE_PLACES_API_KEY)
        //        }
        //        if let GOOGLE_DIRECTIONS_API_KEY = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_DIRECTIONS_API_KEY") as? String {
        //            GMSServices.provideAPIKey(GOOGLE_DIRECTIONS_API_KEY)
        //        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
