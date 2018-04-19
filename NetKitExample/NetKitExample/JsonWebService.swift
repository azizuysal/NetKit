//
//  JsonWebService.swift
//  NetKitExample
//
//  Created by Aziz Uysal on 2/19/16.
//  Copyright © 2016 Aziz Uysal. All rights reserved.
//

import Foundation
import NetKit

protocol JsonServiceAPI {
  
  var webService: WebService { get }
  
  func getPosts() -> WebTask
  func addPost() -> WebTask
  func updatePost() -> WebTask
  func deletePost() -> WebTask
}

extension JsonServiceAPI {
  
  func getPosts() -> WebTask {
    return webService.GET("posts")
  }
  
  func addPost() -> WebTask {
    return webService.POST("posts")
  }
  
  func updatePost() -> WebTask {
    return webService.PUT("posts")
  }
  
  func deletePost() -> WebTask {
    return webService.DELETE("posts")
  }
}

class JsonService: JsonServiceAPI {
  
  fileprivate static let baseURL = "http://localhost:3000"
  let webService = WebService(urlString: baseURL)!
}

class Post {
  
  var id: Int = 0
  var title: String = ""
  var author: String = ""
  
  func toJson() -> [String:AnyObject] {
    var json = [String:AnyObject]()
    json["id"] = id as AnyObject?
    json["title"] = title as AnyObject?
    json["author"] = author as AnyObject?
    return json
  }
}

extension Notification.Name {
  static let postsDownloaded = Notification.Name("JsonService.PostsDownloaded")
  static let postsCreated = Notification.Name("JsonService.PostsCreated")
  static let postsUpdated = Notification.Name("JsonService.PostsUpdated")
  static let postsDeleted = Notification.Name("JsonService.PostsDeleted")
}
