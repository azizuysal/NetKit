//
//  WebRequest.swift
//  NetKit
//
//  Created by Aziz Uysal on 2/12/16.
//  Copyright © 2016 Aziz Uysal. All rights reserved.
//

import Foundation

public struct WebRequest {
  
  public struct Headers {
    public static let userAgent = "User-Agent"
    public static let contentType = "Content-Type"
    public static let contentLength = "Content-Length"
    public static let accept = "Accept"
    public static let cacheControl = "Cache-Control"
    
    public struct ContentType {
      public static let json = "application/json"
      public static let xml = "text/xml"
      public static let formEncoded = "application/x-www-form-urlencoded"
    }
  }
  
  public enum Method: String {
    case HEAD = "HEAD"
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
  }
  
  public enum ParameterEncoding {
    case percent, json
    
    public func encodeURL(_ url: URL, parameters: [String:Any]) -> URL? {
      if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
        components.appendPercentEncodedQuery(parameters.percentEncodedQueryString)
        return components.url
      }
      return nil
    }
    
    public func encodeBody(_ parameters: [String:Any]) -> Data? {
      switch self {
      case .percent:
        return parameters.percentEncodedQueryString.data(using: String.Encoding.utf8, allowLossyConversion: false)
      case .json:
        do {
          return try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
          return nil
        }
      }
    }
  }
  
  let method: Method
  private(set) var url: URL
  var body: Data?
  
  var cachePolicy = URLRequest.CachePolicy.useProtocolCachePolicy
  
  var urlParameters = [String:Any]()
  var bodyParameters = [String:Any]()
  var parameterEncoding = ParameterEncoding.percent {
    didSet {
      if parameterEncoding == .json {
        contentType = Headers.ContentType.json
      }
    }
  }
  
  var restPath = "" {
    didSet {
      url = url.appendingPathComponent(restPath)
    }
  }
  
  var headers = [String:String]()
  var contentType: String? {
    set { headers[Headers.contentType] = newValue }
    get { return headers[Headers.contentType] }
  }
  
  var urlRequest: URLRequest {
    let request = NSMutableURLRequest(url: url)
    request.httpMethod = method.rawValue
    request.cachePolicy = cachePolicy
    
    for (name, value) in headers {
      request.addValue(value, forHTTPHeaderField: name)
    }
    
    if urlParameters.count > 0 {
      if let url = request.url, let encodedURL = parameterEncoding.encodeURL(url, parameters: urlParameters) {
        request.url = encodedURL
      }
    }
    
    if bodyParameters.count > 0 {
      if let data = parameterEncoding.encodeBody(bodyParameters) {
        request.httpBody = data
        if request.value(forHTTPHeaderField: Headers.contentType) == nil {
          request.setValue(Headers.ContentType.formEncoded, forHTTPHeaderField: Headers.contentType)
        }
      }
    }
    
    if let body = body {
      request.httpBody = body
    }
    
    return request.copy() as! URLRequest
  }
  
  public init(method: Method, url: URL) {
    self.method = method
    self.url = url
  }
}

extension URLComponents {
  mutating func appendPercentEncodedQuery(_ query: String) {
    percentEncodedQuery = percentEncodedQuery == nil ? query : "\(percentEncodedQuery ?? "")&\(query)"
  }
}

extension Dictionary {
  var percentEncodedQueryString: String {
    var components = [String]()
    for (name, value) in self {
      if let percentEncodedPair = percentEncode((name, value)) {
        components.append(percentEncodedPair)
      }
    }
    return components.joined(separator: "&")
  }
  
  func percentEncode(_ element: Element) -> String? {
    let (name, value) = element
    if let encodedName = "\(name)".percentEncodeURLQueryCharacters, let encodedValue = "\(value)".percentEncodeURLQueryCharacters {
      return "\(encodedName)=\(encodedValue)"
    }
    return nil
  }
}

extension String {
  var percentEncodeURLQueryCharacters: String? {
    let allowedCharacterSet = CharacterSet(charactersIn: "\\!*'();:@&=+$,/?%#[] ").inverted
    return self.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet /*.urlQueryAllowed*/)
  }
}
