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
    NSNotificationCenter.defaultCenter().removeObserver(self, name: GlobalWeatherService.ReceivedWeather, object: nil)
    NSNotificationCenter.defaultCenter().removeObserver(self, name: GlobalWeatherService.ReceivedCities, object: nil)
    NSNotificationCenter.defaultCenter().removeObserver(self, name: ServiceWithDelegate.CommentsDownloaded, object: nil)
    NSNotificationCenter.defaultCenter().removeObserver(self, name: JsonService.PostsDownloaded, object: nil)
    NSNotificationCenter.defaultCenter().removeObserver(self, name: JsonService.PostsCreated, object: nil)
    NSNotificationCenter.defaultCenter().removeObserver(self, name: JsonService.PostsUpdated, object: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "postsDownloaded:", name: JsonService.PostsDownloaded, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "postsCreated:", name: JsonService.PostsCreated, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "postsUpdated:", name: JsonService.PostsUpdated, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "commentsDownloaded:", name: ServiceWithDelegate.CommentsDownloaded, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "receivedCities:", name: GlobalWeatherService.ReceivedCities, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "receivedWeather:", name: GlobalWeatherService.ReceivedWeather, object: nil)
  }
  
  override func viewWillAppear(animated: Bool) {
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
  }
  
  func postsDownloaded(notification: NSNotification) {
    print("POSTS DOWNLOADED")
  }
  
  func postsCreated(notification: NSNotification) {
    print("POST CREATED")
  }
  
  func postsUpdated(notification: NSNotification) {
    print("POST UPDATED")
  }
  
  func commentsDownloaded(notification: NSNotification) {
    print("COMMENTS DOWNLOADED")
  }
  
  func receivedCities(notification: NSNotification) {
    print("RECEIVED CITIES")
  }
  
  func receivedWeather(notification: NSNotification) {
    print("RECEIVED WEATHER")
  }
}