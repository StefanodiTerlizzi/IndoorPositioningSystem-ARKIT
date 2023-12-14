//
//  extensionNotificationName.swift
//  autoMapping
//
//  Created by stefano on 2023/09/15.
//

import Foundation

extension Notification.Name {
    static var genericMessage: Notification.Name {
        return .init(rawValue: "genericMessage.message")
    }
    static var genericMessage2: Notification.Name {
        return .init(rawValue: "genericMessage.message2")
    }
    static var genericMessage3: Notification.Name {
        return .init(rawValue: "genericMessage.message3")
    }
    static var trackingState: Notification.Name {
        return .init(rawValue: "trackingState.message")
    }
    static var timeLoading: Notification.Name {
        return .init(rawValue: "timeLoading.message")
    }
    static var worldMapMessage: Notification.Name {
        return .init(rawValue: "WorldMapMessage.message")
    }
    static var worldMapCounter: Notification.Name {
        return .init(rawValue: "WorldMapMessage.counter")
    }
    
    static var trackingPosition: Notification.Name {
        return .init(rawValue: "trackingPosition.message")
    }
    
    static var worlMapNewFeatures: Notification.Name {
        return .init(rawValue: "worlMapNewFeatures.message")
    }
    
    static var trackingPositionFromMotionManager: Notification.Name {
        return .init(rawValue: "trackingPositionFromMotionManager.message")
    }
    
}

