//
//  CustomTabBar.swift
//  xpenz
//
//  Created by Rafael Soh on 20/5/22.
//
//  The custom tab bar was replaced by the system Liquid Glass tab bar in HomeView.
//  This file keeps the shared BouncyButton style that other views still use.
//

import Foundation
import SwiftUI

struct BouncyButton: ButtonStyle {
    var duration: Double
    var scale: Double

    public func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.easeOut(duration: duration), value: configuration.isPressed)
    }
}
