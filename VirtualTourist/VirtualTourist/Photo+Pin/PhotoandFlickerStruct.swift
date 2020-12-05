//
//  ViewController.swift
//  VirtualTourist
//
//  Created by salma apple on 1/5/19.
//  Copyright © 2019 Salma alenazi. All rights reserved.
//


import Foundation

struct FlickerParser: Codable {
    let photos: Photos
}

struct Photos: Codable {
    let pages: Int
    let photo: [PhotoParser]
}

struct PhotoParser: Codable {
    
    let url: String?
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case url = "url_n"
        case title
    }
}
struct ImageName {
    static let placeHolder = "placeHolder"
}
//Flickr api
struct Flickr {
    static let APIScheme = "https"
    static let APIHost = "api.flickr.com"
    static let APIPath = "/services/rest"
    static let BBoxHalfWidth = 0.2
    static let BBoxHalfHeight = 0.2
    static let LatRange = (-90.0, 90.0)
    static let LonRange = (-180.0, 180.0)
}

// Parameter Keys

struct FlickrParameterKeys {
    static let Method = "method"
    static let APIKey = "api_key"
    static let Extras = "extras"
    static let Format = "format"
    static let NoJSONCallback = "nojsoncallback"
    static let SafeSearch = "safe_search"
    static let BoundingBox = "bbox"
    static let PhotosPerPage = "per_page"
    static let Page = "page"
}

// Flickr Parameter Values
struct FlickrParameterValues {
    static let SearchMethod = "flickr.photos.search"
    static let APIKey = "29bd206b5d4cc48dd19a7bc49339665c"
    static let ResponseFormat = "json"
    static let DisableJSONCallback = "yes"
    static let MediumURL = "url_n"
    static let UseSafeSearch = "yes"
    static let PhotosPerPage = 12
}
