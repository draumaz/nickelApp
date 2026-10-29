//
//  SettingsBackButton.swift
//  dime
//
//  Created by Rafael Soh on 5/11/23.
//

import Foundation
import SwiftUI

/// The label for back buttons in Settings subviews, rendered on circular Liquid Glass.
/// Callers wrap it in a `Button`, so the glass is interactive to match system glass buttons.
struct SettingsBackButton: View {
  var body: some View {
    Image(systemName: "chevron.left")
      .font(.system(.body, design: .rounded).weight(.semibold))
      .foregroundStyle(.primary)
      .frame(width: 44, height: 44)
      .glassEffect(.regular.interactive(), in: .circle)
      .contentShape(Circle())
      .accessibilityLabel("Back")
  }
}
