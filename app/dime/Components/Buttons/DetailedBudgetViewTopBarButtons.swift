//
//  DetailedBudgetViewTopBarButtons.swift
//  dime
//
//  Created by Rafael Soh on 4/11/23.
//

import Foundation
import SwiftUI

/// A circular Liquid Glass action button for the detailed budget top bar.
/// Place adjacent buttons in a `GlassEffectContainer` so their glass renders together.
struct DetailedBudgetViewTopBarButton: View {
    var imageName: String
    var color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: imageName)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }
}
