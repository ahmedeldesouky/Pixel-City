//
//  Constants.swift
//  pixel-city
//
//  Created by Ahmed Mohamed El-Desouky on 12/6/18.
//  Copyright © 2018 Ahmed Mohamed El-Desouky. All rights reserved.
//

import Foundation

let apiKey = "a3f652d70cb2c63f1868d71376c61904"

func flickrUrl(forApiKey key: String, withAnnotation annotation:DroppablePin, andNumberOfPhotos number: Int) -> String {
    let url = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=km&per_page=\(number)&format=json&nojsoncallback=1"
return url
}
