//
//  Utils.swift
//  Pods
//
//  Created by Aleksander on 07/07/2025.
//

import Foundation

public func toDictionary<T: Encodable>(_ encodable: T) -> [String: Any]? {
    do {
        let data = try JSONEncoder().encode(encodable)
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        return jsonObject as? [String: Any]
    } catch {
        print("Error converting to dictionary:", error)
        return nil
    }
}

public func fromDictionary<T: Decodable>(_ dictionary: [String: Any], to type: T.Type) -> T? {
    do {
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        let decodedObject = try JSONDecoder().decode(type, from: data)
        return decodedObject
    } catch {
        print("Error converting from dictionary:", error)
        return nil
    }
}
