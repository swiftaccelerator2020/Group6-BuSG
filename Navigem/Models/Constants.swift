//
//  Constants.swift
//  Navigem
//
//  Created by Ryan The on 16/11/20.
//

import UIKit

/// DataMall does not support HTTPS
let apiUrlBase = "http://datamall2.mytransport.sg/ltaodataservice"

enum K {
    enum margin {
        static let small: CGFloat = 8
        static let large: CGFloat = 16
    }
    
    static let bottomSheetOpacity: CGFloat = 0.7
    static let cornerRadius: CGFloat = 8
    
    static let dataMallEnvVar = "data_mall_api_key"
    static let dataMallMimeType = "application/json"
    
    enum apiUrl {
        static let busArrival = "\(apiUrlBase)/BusArrivalv2"
        static let busServices = "\(apiUrlBase)/BusServices"
        static let busRoutes = "\(apiUrlBase)/BusRoutes"
        static let busStops = "\(apiUrlBase)/BusStops"
    }
}
