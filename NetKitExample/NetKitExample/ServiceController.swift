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
  static let success = "success"
  static let error = "error"
}

class ServiceController {
  
  private static let jsonService = JsonService()
  private static let serviceWithDelegate = ServiceWithDelegate()
  private static let weatherService = GlobalWeatherService()
  private static let downloadService = DownloadService()
  
  private static let networkQueueSerial = DispatchQueue(label: "networkQueueSerial", attributes: [])
  private static let networkQueueParallel = DispatchQueue(label: "networkQueueParallel", attributes: DispatchQueue.Attributes.concurrent)
  private static let downloadQueue = DispatchQueue(label: "downloadQueue", attributes: [])
  
  // MARK: ExampleService
  
  class func getPostsSync() -> Any {
    var result: Any = []
    
    jsonService.getPosts()
//      .respondOnCurrentQueue(true)
      .responseJSON { json in
        result = json
        notifyUser(.postsDownloaded)
        return .success
      }
      .responseError { error in
        print(error)
        notifyUser(.postsDownloaded, error: error)
      }
      .resumeAndWait(1)
    
    return result
  }
  
  class func getPosts() {
    _ = networkQueueSerial.sync {
      jsonService.getPosts()
        .setURLParameters(["dummy":"domain\\+dummy"])
        .responseJSON { json in
          print(json)
          notifyUser(.postsDownloaded)
          return .success
        }
        .responseError { error in
          print(error)
          notifyUser(.postsDownloaded, error: error)
        }
        .resumeAndWait()
    }
  }
  
  class func addPost(_ post: Post) {
    networkQueueParallel.async {
      jsonService.addPost()
        .setJSON(post.toJson())
        .responseJSON { json in
          print(json)
          notifyUser(.postsCreated)
          return .success
        }
        .responseError { error in
          print(error)
          notifyUser(.postsCreated, error: error)
        }
        .resume()
    }
  }
  
  class func updatePost(_ post: Post) {
    networkQueueParallel.async {
      jsonService.updatePost()
        .setPath(String(post.id))
        .setJSON(post.toJson())
        .responseJSON { json in
          print(json)
          notifyUser(.postsUpdated)
          return .success
        }
        .responseError { error in
          print(error)
          notifyUser(.postsUpdated, error: error)
        }
        .resume()
    }
  }
  
  // MARK: ServiceWithDelegate
  
  class func getComments() {
    _ = networkQueueSerial.sync {
      serviceWithDelegate.getComments()
        .responseJSON { json in
          print(json)
          notifyUser(.commentsDownloaded)
          return .success
        }
        .responseError { error in
          print(error)
          notifyUser(.commentsDownloaded, error: error)
        }
        .resume()
    }
  }
  
  // MARK: GlobalWeatherService
  
  class func getCities(_ country: String)  {
    _ = networkQueueSerial.sync {
      weatherService.getCitiesByCountry()
        .setURLParameters(["op":"GetCitiesByCountry"])
        .setSOAP("<GetCitiesByCountry xmlns=\"http://www.webserviceX.NET\"><CountryName>\(country)</CountryName></GetCitiesByCountry>")
        .response { data, url, response in
//          print(String(data: data!, encoding: NSUTF8StringEncoding))
          notifyUser(.receivedCities)
          return .success
        }
        .responseError { error in
          print(error)
          notifyUser(.receivedCities, error: error)
        }
        .resume()
    }
  }
  
  class func downloadFile(_ filename: String) {
    
    downloadQueue.async {
      downloadService.getFile()
        .setCachePolicy(.reloadIgnoringLocalAndRemoteCacheData)
        .setPath(filename)
        .responseFile { (url, response) in
          let path = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Documents")
          do {
            try FileManager.default.createDirectory(at: path!, withIntermediateDirectories: true, attributes: nil)
          } catch let error as NSError {
            print(error.localizedDescription)
            return .failure(error)
          }
          if let url = url, let response = response, let filename = response.suggestedFilename, let path = path?.appendingPathComponent(filename) {
            do {
              if FileManager.default.fileExists(atPath: path.path) {
                try FileManager.default.removeItem(at: path)
              }
              try FileManager.default.copyItem(at: url, to: path)
            } catch let error as NSError {
              print(error.localizedDescription)
              return .failure(error)
            }
          } else {
            return .failure(WebServiceError.badData("File parameter is nil"))
          }
          notifyUser(.fileDownloaded, filename: response?.suggestedFilename)
          return .success
        }
        .responseError { error in
          print(error)
          notifyUser(.fileDownloaded, error: error)
        }
        .resumeAndWait()
    }
  }
  
  // MARK: Private methods
  
  private class func notifyUser(_ event: Notification.Name, error: Error? = nil, filename: String? = nil) {
    var userInfo = [String:AnyObject]()
    userInfo = [ServiceResult.success:true as AnyObject]
    if let error = error {
      userInfo[ServiceResult.success] = false as AnyObject?
      userInfo[ServiceResult.error] = error as NSError
    }
    if let filename = filename {
      userInfo[DownloadService.fileName] = filename as AnyObject?
    }
    NotificationCenter.default.post(name: event, object: nil, userInfo: userInfo)
  }
}

// MARK: Errors

enum WebServiceError: Error, CustomStringConvertible {
  case badResponse(String)
  case badData(String)
  
  var description: String {
    switch self {
    case let .badResponse(info):
      return info
    case let .badData(info):
      return info
    }
  }
}
