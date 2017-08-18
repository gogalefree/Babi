//
//  AppDelegate.swift
//  Babi
//
//  Created by Guy Freedman on 3/28/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import SwiftyBeaver
let log = SwiftyBeaver.self

@available(iOS 10.0, *)
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  var providerDelegate: ProviderDelegate = ProviderDelegate(callManager: CallManager())
  //let callManager = CallManager()
  
  class var shared: AppDelegate {
    return UIApplication.shared.delegate as! AppDelegate
  }
  
  func displayIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)?) {
    providerDelegate.reportIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo, completion: completion)
  }
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    UINavigationBar.appearance().tintColor = UIColor.black
    UINavigationBar.appearance().isTranslucent = true
    UINavigationBar.appearance().setBackgroundImage(UIImage(named: "kob_navBar_normal.jpeg"), for: .default)
    UIApplication.shared.isIdleTimerDisabled = true
    FireBaseController.shared.setup()
    Model.shared.setUp()
    LocationNotifications.shared.registerUserNotifications(application: application)
    FireBaseController.shared.signIn()
    registerSwiftyBeaver()
    return true
  }
  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    
    var token = deviceToken.description as NSString
    token = token.trimmingCharacters(in: CharacterSet(charactersIn: "<>")) as NSString
    token = token.replacingOccurrences(of: " ", with: "") as NSString
    RemoteNotificationsController.sharedInstance.savePushNotificationsTokenInUD(token as String)
  }
  
  func application(_ application: UIApplication, didReceive notification: UILocalNotification) {}
  
  func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
    if let id = identifier {
      if id == kCallActionIdentifier {
        let userInfo = notification.userInfo as [AnyHashable: Any]?
        
        if let userInfo = userInfo{
          
          let phoneNumber = userInfo["phoneNumber"] as! String
          PhoneDialer.callGate(phoneNumber)
        }
      }
    }
  }
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
    return URLController.shared.open(url, options: options)
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
    UIApplication.shared.applicationIconBadgeNumber = 0
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    UIApplication.shared.applicationIconBadgeNumber = 0
    if UserDefaults.standard.bool(forKey: kSleepModeKey) {
      let container = window?.rootViewController as! MainContainerController
      container.wakeUpFromSleepMode()
    }
    Model.shared.usageUpdater.incrementDidBecomeActive()
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    self.saveContext()
  }
  
  // MARK: - Core Data stack
  
  lazy var applicationDocumentsDirectory: URL = {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.gogalefree.Babi" in the application's documents Application Support directory.
    let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return urls[urls.count-1]
  }()
  
  lazy var managedObjectModel: NSManagedObjectModel = {
    // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
    let modelURL = Bundle.main.url(forResource: "Babi", withExtension: "momd")!
    return NSManagedObjectModel(contentsOf: modelURL)!
  }()
  
  lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
    // Create the coordinator and store
    var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
    let url = self.applicationDocumentsDirectory.appendingPathComponent("Babi.sqlite")
    var error: NSError? = nil
    var failureReason = "There was an error creating or loading the application's saved data."
    do {
      try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
    } catch var error1 as NSError {
      error = error1
      coordinator = nil
      // Report any error we got.
      var dict = [String: AnyObject]()
      dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
      dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
      dict[NSUnderlyingErrorKey] = error
      error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
      // Replace this with code to handle the error appropriately.
      // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
      NSLog("Unresolved error \(String(describing: error)), \(error!.userInfo)")
      //abort()
    } catch {
      log.error("could not initiate core data stack")
      fatalError()
    }
    return coordinator
  }()
  
  lazy var managedObjectContext: NSManagedObjectContext? = {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
    let coordinator = self.persistentStoreCoordinator
    if coordinator == nil {
      return nil
    }
    var managedObjectContext = NSManagedObjectContext()
    managedObjectContext.persistentStoreCoordinator = coordinator
    return managedObjectContext
  }()
  
  // MARK: - Core Data Saving support
  
  func saveContext () {
    if let moc = self.managedObjectContext {
      var error: NSError? = nil
      if moc.hasChanges {
        do {
          try moc.save()
        } catch let error1 as NSError {
          error = error1
          // Replace this implementation with code to handle the error appropriately.
          // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
          log.error("Unresolved error \(String(describing: error)), \(error!.userInfo)")
          //  abort()
        }
      }
    }
  }
    
  func tokenRefreshNotification(_ notification: Notification) {
    if let refreshedToken = FIRInstanceID.instanceID().token() {
      RemoteNotificationsController.sharedInstance.savePushNotificationsTokenInUD(refreshedToken)
      print("InstanceID token: \(refreshedToken)")
    }
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
    print("did recive remote notification: ")
  }
    
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    
    if application.applicationState != .active {
      let badge = UIApplication.shared.applicationIconBadgeNumber + 1
      application.applicationIconBadgeNumber = badge
    }
    completionHandler(.newData)
  }
  
  func registerSwiftyBeaver() {
    
    let console = ConsoleDestination()
    log.addDestination(console)
    let cloud = SBPlatformDestination(appID: "7eZroO",
                                      appSecret: "fAag0inofy6ylw1alr19v9ccorlmnoCd",
                                      encryptionKey: "r0gq0zcmuawrwJcgecgzpQraz8e2dGbv")
    log.addDestination(cloud)
    // the second file with different properties and custom filename
    //let file2 = FileDestination()
    //file2.logFileURL = URL(fileURLWithPath: "/tmp/babiLog.log")  // tmp is just possible for a macOS app
    //log.addDestination(file2)
    //let token = FIRInstanceID.instanceID().token()
    //print(String(describing:token))
    //sendPush()
  }
}

