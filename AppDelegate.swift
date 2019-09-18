//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Sean Williams on 30/08/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var downloadedPhotos = [UIImage]()

    let dataController = DataController(modelName: "VirtualTourist")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        checkFirstLaunch()
        dataController.load()
        
        // Inject dataController dependancy to TravelLocationsMapView
        let navigationController = window?.rootViewController as! UINavigationController
        let travelLocationsMapViewController = navigationController.topViewController as! TravelLocationsMapViewController
        travelLocationsMapViewController.dataController = dataController
        
        return true
    }


    func applicationDidEnterBackground(_ application: UIApplication) {
        saveViewContext()
    }


    func applicationWillTerminate(_ application: UIApplication) {
        saveViewContext()
    }

    func saveViewContext () {
        try? dataController.viewContext.save()
    }
    
    func checkFirstLaunch() {
        if UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            print("App has launched before")
        } else {
            print("This is the first launch")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            UserDefaults.standard.set(51.50528421798009, forKey: "lat key")
            UserDefaults.standard.set(-0.18821414496005673, forKey: "lon key")
            UserDefaults.standard.set(5.197731883914713, forKey: "lat delta key")
            UserDefaults.standard.set(4.548340505366269, forKey: "lon delta key")
        }
    }
}

