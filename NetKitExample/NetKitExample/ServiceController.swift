//
//  ServiceController.swift
//  NetKitExample
//
//  Created by Aziz Uysal on 2/17/16.
//  Copyright © 2016 Aziz Uysal. All rights reserved.
//

import Foundation
import NetKit

struct ServiceResult {
  static let Success = "Success"
  static let Error = "Error"
}

class ServiceController {
  
  private static let jsonService = JsonService()
  private static let serviceWithDelegate = ServiceWithDelegate()
  private static let weatherService = GlobalWeatherService()
  private static let downloadService = DownloadService()
  
  private static let networkQueueSerial = dispatch_queue_create("networkQueueSerial", DISPATCH_QUEUE_SERIAL)
  private static let networkQueueParallel = dispatch_queue_create("networkQueueParallel", DISPATCH_QUEUE_CONCURRENT)
  private static let downloadQueue = dispatch_queue_create("downloadQueue", DISPATCH_QUEUE_SERIAL)
  
  // MARK: ExampleService
  
  class func getPostsSync() -> AnyObject {
    var result: AnyObject = []
    
    jsonService.getPosts()
//      .respondOnCurrentQueue(true)
      .responseJSON { json in
        result = json
        notifyUser(JsonService.PostsDownloaded)
        return .Success
      }
      .responseError { error in
        print(error)
        notifyUser(JsonService.PostsDownloaded, error: error)
      }
      .resumeAndWait(1)
    
    return result
  }
  
  class func getPosts() {
    dispatch_sync(networkQueueSerial) {
      jsonService.getPosts()
        .responseJSON { json in
          print(json)
          notifyUser(JsonService.PostsDownloaded)
          return .Success
        }
        .responseError { error in
          print(error)
          notifyUser(JsonService.PostsDownloaded, error: error)
        }
        .resumeAndWait()
    }
  }
  
  class func addPost(post: Post) {
    dispatch_async(networkQueueParallel) {
      jsonService.addPost()
        .setJSON(post.toJson())
        .responseJSON { json in
          print(json)
          notifyUser(JsonService.PostsCreated)
          return .Success
        }
        .responseError { error in
          print(error)
          notifyUser(JsonService.PostsCreated, error: error)
        }
        .resume()
    }
  }
  
  class func updatePost(post: Post) {
    dispatch_async(networkQueueParallel) {
      jsonService.updatePost()
        .setPath(String(post.id))
        .setJSON(post.toJson())
        .responseJSON { json in
          print(json)
          notifyUser(JsonService.PostsUpdated)
          return .Success
        }
        .responseError { error in
          print(error)
          notifyUser(JsonService.PostsUpdated, error: error)
        }
        .resume()
    }
  }
  
  // MARK: ServiceWithDelegate
  
  class func getComments() {
    dispatch_sync(networkQueueSerial) {
      serviceWithDelegate.getComments()
        .responseJSON { json in
          print(json)
          notifyUser(ServiceWithDelegate.CommentsDownloaded)
          return .Success
        }
        .responseError { error in
          print(error)
          notifyUser(ServiceWithDelegate.CommentsDownloaded, error: error)
        }
        .resume()
    }
  }
  
  // MARK: GlobalWeatherService
  
  class func getCities(country: String)  {
    dispatch_sync(networkQueueSerial) {
      weatherService.getCitiesByCountry()
        .setURLParameters(["op":"GetCitiesByCountry"])
        .setSOAP("<GetCitiesByCountry xmlns=\"http://www.webserviceX.NET\"><CountryName>\(country)</CountryName></GetCitiesByCountry>")
        .response { data, url, response in
//          print(String(data: data!, encoding: NSUTF8StringEncoding))
          notifyUser(GlobalWeatherService.ReceivedCities)
          return .Success
        }
        .responseError { error in
          print(error)
          notifyUser(GlobalWeatherService.ReceivedCities, error: error)
        }
        .resume()
    }
  }
  
  class func downloadFile(filename: String) {
    
    dispatch_async(downloadQueue) {
      downloadService.getFile()
        .setCachePolicy(.ReloadIgnoringLocalAndRemoteCacheData)
        .setPath(filename)
        .responseFile { (url, response) in
          let path = NSFileManager.defaultManager().URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask).first?.URLByAppendingPathComponent("Documents")
          do {
            try NSFileManager.defaultManager().createDirectoryAtURL(path!, withIntermediateDirectories: true, attributes: nil)
          } catch let error as NSError {
            print(error.localizedDescription)
            return .Failure(error)
          }
          if let url = url, response = response, filename = response.suggestedFilename, path = path?.URLByAppendingPathComponent(filename) {
            do {
              if NSFileManager.defaultManager().fileExistsAtPath(path.path!) {
                try NSFileManager.defaultManager().removeItemAtURL(path)
              }
              try NSFileManager.defaultManager().copyItemAtURL(url, toURL: path)
            } catch let error as NSError {
              print(error.localizedDescription)
              return .Failure(error)
            }
          } else {
            return .Failure(WebServiceError.BadData("File parameter is nil"))
          }
          notifyUser(DownloadService.FileDownloaded, filename: response?.suggestedFilename)
          return .Success
        }
        .responseError { error in
          print(error)
          notifyUser(DownloadService.FileDownloaded, error: error)
        }
        .resumeAndWait()
    }
  }
  
  // MARK: Private methods
  
  private class func notifyUser(event: String, error: ErrorType? = nil, filename: String? = nil) {
    var userInfo = [String:AnyObject]()
    userInfo = [ServiceResult.Success:true]
    if let error = error {
      userInfo[ServiceResult.Success] = false
      userInfo[ServiceResult.Error] = error as NSError
    }
    if let filename = filename {
      userInfo[DownloadService.FileName] = filename
    }
    NSNotificationCenter.defaultCenter().postNotificationName(event, object: nil, userInfo: userInfo)
  }
}

// MARK: Errors

enum WebServiceError: ErrorType, CustomStringConvertible {
  case BadResponse(String)
  case BadData(String)
  
  var description: String {
    switch self {
    case let .BadResponse(info):
      return info
    case let .BadData(info):
      return info
    }
  }
}