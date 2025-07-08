//
//  Event.swift
//  Pods
//
//  Created by Aleksander on 04/07/2025.
//

import Foundation

enum WireguardEvent: String {
    case tunnelUp = "tunnel_up"
    case tunnelDown = "tunnel_down"
    case tunnelWaiting = "tunnel_waiting"
}
