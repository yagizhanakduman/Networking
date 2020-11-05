//
//  String+Networking.swift
//  Networking
//
//  Created by YAGIZHAN AKDUMAN on 23.10.2020.
//  Copyright © 2020 YAGIZHAN AKDUMAN. All rights reserved.
//

import Foundation

extension String {
    
    public func toArray<T: Codable>(type: [T].Type) -> [T]? {
        do {
            return try JSONSerializer.jsonToGenericObject(self, type: type)
        } catch {
            return nil
        }
    }
    
    public func toObject<T: Codable>(type: T.Type) -> T? {
        do {
            return try JSONSerializer.jsonToGenericObject(self, type: type)
        } catch {
            return nil
        }
    }
    
    public func toData() -> Any? {
        guard let data = self.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
    }
}

