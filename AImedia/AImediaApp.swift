//
//  AImediaApp.swift
//  AImedia
//
//  Created by Chibuike  Henry on 2025-01-12.
//

import SwiftUI

@main
struct AImediaApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


//delegate to clear core data on app termination

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func applicationWillTerminate(_ application: UIApplication) {
        // Clear Core Data on termination
        CoreDataManager.shared.clearAllData()
        
        
        print("Core Data cleared on app termination")
    }
}






