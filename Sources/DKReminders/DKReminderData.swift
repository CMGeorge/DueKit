//
//  ReminderData.swift
//  DueKit
//
//  Created by Calugar George on 19/09/2026.
//

public struct ReminderData: Sendable, Hashable {
    public let title: String
    public let body: String
    public let customData: [[String: String]]
    
    public init(title: String, body: String, customData: [[String : String]] = []) {
        self.title = title
        self.body = body
        self.customData = customData
    }
    
}

