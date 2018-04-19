//
//  ViewController.swift
//  NetKitExample
//
//  Created by Aziz Uysal on 2/17/16.
//  Copyright © 2016 Aziz Uysal. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: .fileDownloaded, object: nil)
    NotificationCenter.default.removeObserver(self, name: .receivedWeather, object: nil)
    NotificationCenter.default.removeObserver(self, name: .receivedCities, object: nil)
    NotificationCenter.default.removeObserver(self, name: .commentsDownloaded, object: nil)
    NotificationCenter.default.removeObserver(self, name: .postsDownloaded, object: nil)
    NotificationCenter.default.removeObserver(self, name: .postsCreated, object: nil)
    NotificationCenter.default.removeObserver(self, name: .postsUpdated, object: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NotificationCenter.default.addObserver(forName: .postsDownloaded, object: nil, queue: nil, using: handleNotification(_:))
    NotificationCenter.default.addObserver(forName: .postsCreated, object: nil, queue: nil, using: handleNotification(_:))
    NotificationCenter.default.addObserver(forName: .postsUpdated, object: nil, queue: nil, using: handleNotification(_:))
    NotificationCenter.default.addObserver(forName: .commentsDownloaded, object: nil, queue: nil, using: handleNotification(_:))
    NotificationCenter.default.addObserver(forName: .receivedCities, object: nil, queue: nil, using: handleNotification(_:))
    NotificationCenter.default.addObserver(forName: .receivedWeather, object: nil, queue: nil, using: handleNotification(_:))
    NotificationCenter.default.addObserver(forName: .fileDownloaded, object: nil, queue: nil, using: handleNotification(_:))
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Important: use json-server with following options, otherwise below steps will not execute as expected
    // json-server --delay 2000 --watch db.json
    
    // This will timeout as the sync method has a timeout value of 1 second.
    let json = ServiceController.getPostsSync()
    print("waiting")
    print(json)
    
    print("starting async methods")

    // This will execute and finish before weather service even though it is delayed 2 seconds
    // If you change resumeAndWait() to resume(), it will start execution before weather call, but weather call will finish earlier.
    ServiceController.getPosts()
    
    let post1 = Post()
    post1.id = 2
    post1.title = "TEST CREATE"
    post1.author = "netkit"
    ServiceController.addPost(post1)
    
    let post2 = Post()
    post2.id = 1
    post2.title = "TEST UPDATE"
    post2.author = "netkit"
    ServiceController.updatePost(post2)
    
    ServiceController.getPosts()
    
    // This will finish after weather call below because they are both in the same serial queue, but this is executed by resume() which returns before the call is finalized.
    ServiceController.getComments()
    
    ServiceController.getCities("Turkey")
    
    // Experiment changing downloadQueue from serial to concurrent, or use resume() instead of resumeAndWait(), or use dispatch_async instead of dispatch_sync
    for _ in 1...10 {
      ServiceController.downloadFile("5MB.zip")
      ServiceController.downloadFile("20MB.zip")
      ServiceController.downloadFile("100MB.zip")
    }
    print("********* finished queueing *********")
  }
  
  private func handleNotification(_ notification: Notification) {
    if let error = notification.userInfo?[ServiceResult.error] {
      print("\(notification.name.rawValue) error: \(error)")
    } else if let filename = notification.userInfo?[DownloadService.fileName] {
      print("\(notification.name.rawValue) file downloaded: \(filename)")
    } else {
      print("\(notification.name.rawValue) was successful")
    }
  }
}
