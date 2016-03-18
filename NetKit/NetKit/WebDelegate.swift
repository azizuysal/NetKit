//
//  WebDelegate.swift
//  NetKit
//
//  Created by Aziz Uysal on 2/16/16.
//  Copyright © 2016 Aziz Uysal. All rights reserved.
//

import Foundation

public class WebDelegate: NSObject {
  
  var tasks = [Int:WebTask]()
}

extension WebDelegate: NSURLSessionTaskDelegate {
  public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
    let webTask = tasks[task.taskIdentifier]
    webTask?.authenticate(challenge.protectionSpace.authenticationMethod, completionHandler: completionHandler)
  }
}