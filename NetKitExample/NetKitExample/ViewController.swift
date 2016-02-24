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
    NSNotificationCenter.defaultCenter().removeObserver(self, name: JsonService.PostsDownloaded, object: nil)
    NSNotificationCenter.defaultCenter().removeObserver(self, name: JsonService.PostsCreated, object: nil)
    NSNotificationCenter.defaultCenter().removeObserver(self, name: JsonService.PostsUpdated, object: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "postsDownloaded:", name: JsonService.PostsDownloaded, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "postsCreated:", name: JsonService.PostsCreated, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "postsUpdated:", name: JsonService.PostsUpdated, object: nil)
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
//    ServiceController.getPosts()
//    
//    let post1 = Post()
//    post1.id = 2
//    post1.title = "TEST CREATE"
//    post1.author = "netkit"
//    ServiceController.addPost(post1)
//    
//    let post2 = Post()
//    post2.id = 1
//    post2.title = "TEST UPDATE"
//    post2.author = "netkit"
//    ServiceController.updatePost(post2)
//    
//    ServiceController.getPosts()
    
    ServiceController.getComments()
    
//    ServiceController.getCities("Turkey")
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
}