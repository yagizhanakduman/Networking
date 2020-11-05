//
//  ResultModel.swift
//  Networking
//
//  Created by YAGIZHAN AKDUMAN on 23.10.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation

// MARK: Result Model for API's Response
open class ResultModel<T: Codable> {
    
    private var model: Any?
    private var json: String = ""
    private var requestUrl: String?
    
    public func setModel<T: Codable>(model: T?, type: T.Type) {
        self.model = model
    }
    
    public func setArrayModel<T>(model: [T]?, type: [T].Type) {
        self.model = model
    }

    public func setJson(json: String?) {
        self.json = json ?? ""
    }

    public func setRequestUrl(url: String?) {
        self.requestUrl = url
    }
    
    public func getModel<T: Codable>(type: T.Type) -> T? {
        return self.model as? T
    }
    
    public func getJson() -> String {
        return self.json
    }
    
}
