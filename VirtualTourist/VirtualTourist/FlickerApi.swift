//
//  FlickerApi.swift
//  VirtualTourist
//
//  Created by salma apple on 1/24/19.
//  Copyright © 2019 Salma alenazi. All rights reserved.
//

import UIKit
import Foundation
class FlickerApi{  // MARK: - Flickr

    var session = URLSession.shared
    private var tasks: [String: URLSessionDataTask] = [:]
    class func shared() -> FlickerApi {
        struct Singleton {
            static var shared = FlickerApi()
        }
        return Singleton.shared
    }
    private func bboxString(lat: Double, long: Double) -> String {
        let minimumLon = max(long - Flickr.BBoxHalfWidth, Flickr.LonRange.0)
        let minimumLat = max(lat - Flickr.BBoxHalfHeight, Flickr.LatRange.0)
        let maximumLon = min(long + Flickr.BBoxHalfWidth, Flickr.LonRange.1)
        let maximumLat = min(lat  + Flickr.BBoxHalfHeight, Flickr.LatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    func searchBy(lat: Double, long: Double, allPages: Int?, completion: @escaping (_ result: FlickerParser?, _ error: Error?) -> Void) {
        
        // choosing a random page.
        var page: Int {
            if let allPages = allPages {
                let page = min(allPages, 4000/FlickrParameterValues.PhotosPerPage)
                return Int(arc4random_uniform(UInt32(page)) + 1)
            }
            return 1
        }
        let bbox = bboxString(lat: lat, long: long)
        
        let parameters = [
              FlickrParameterKeys.Method           : FlickrParameterValues.SearchMethod
            , FlickrParameterKeys.APIKey         : FlickrParameterValues.APIKey
            , FlickrParameterKeys.Format         : FlickrParameterValues.ResponseFormat
            , FlickrParameterKeys.Extras         : FlickrParameterValues.MediumURL
            , FlickrParameterKeys.NoJSONCallback : FlickrParameterValues.DisableJSONCallback
            , FlickrParameterKeys.SafeSearch     : FlickrParameterValues.UseSafeSearch
            , FlickrParameterKeys.BoundingBox    : bbox
            , FlickrParameterKeys.PhotosPerPage  : "\(FlickrParameterValues.PhotosPerPage)"
            , FlickrParameterKeys.Page           : "\(page)"
        ]
        
        _ = taskForGETMethod(parameters: parameters) { (data, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let data = data else {
                let userInfo = [NSLocalizedDescriptionKey : "Can not retrieve data."]
                completion(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
                return
            }
            
            do {
                let parser = try JSONDecoder().decode(FlickerParser.self, from: data)
                completion(parser, nil)
            } catch {
                print("\(#function) error: \(error)")
                completion(nil, error)
            }
        }
    }
    
    func downloadimages(imageurl: String, result: @escaping (_ result: Data?, _ error: NSError?) -> Void) {
        guard let url = URL(string: imageurl) else {
            return
        }
        let task = taskForGETMethod(nil, url, parameters: [:]) { (data, error) in
            result(data, error)
            self.tasks.removeValue(forKey: imageurl)
        }
        
        if tasks[imageurl] == nil {
            tasks[imageurl] = task
        }
    }
    
    func canceldownloadimages(_ imageurl: String) {
        tasks[imageurl]?.cancel()
        if tasks.removeValue(forKey: imageurl) != nil {
            print("\(#function) the task is canceled: \(imageurl)")
        }
    }
    private func creatURLFromParameters(_ parameters: [String: String],  PathExtension: String? = nil) -> URL {
        
        var component = URLComponents()
        component.scheme = Flickr.APIScheme
        component.host = Flickr.APIHost
        component.path = Flickr.APIPath + (PathExtension ?? "")
        component.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: value)
            component.queryItems!.append(queryItem)
        }
        
        return component.url!
    }
 
    func taskForGETMethod(
        _ method               : String? = nil,
        _ customUrl            : URL? = nil,
        parameters             : [String: String],
        completionHandlerForGET: @escaping (_ result: Data?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        let request: NSMutableURLRequest!
        if let customUrl = customUrl {
            request = NSMutableURLRequest(url: customUrl)
        } else {
            request = NSMutableURLRequest(url: creatURLFromParameters(parameters,  PathExtension: method))
        }
    
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
                if let error = error {
                if (error as NSError).code == URLError.cancelled.rawValue {
                    completionHandlerForGET(nil, nil)
                } else {
                    sendError("error in your request: \(error.localizedDescription)")
                }
                return
            }
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
                        guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            completionHandlerForGET(data, nil)
            
        }
        
        task.resume()
        
        return task
    }

    

}
