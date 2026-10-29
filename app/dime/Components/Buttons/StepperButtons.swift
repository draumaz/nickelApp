//
//  StepperButtons.swift
//  dime
//
//  Created by Rafael Soh on 5/11/23.
//

import Foundation
import SwiftUI

/// A previous/next chevron on circular Liquid Glass. Disabled buttons use the system's
/// disabled appearance rather than a custom opacity.
struct StepperButtonView: View {
    let left: Bool
    let disabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: left ? "chevron.left" : "chevron.right")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .disabled(disabled)
    }
}
