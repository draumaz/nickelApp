import SwiftUI

/// A circular Liquid Glass icon button for the corners of custom top bars.
struct ToolbarButton: View {
    var systemName: String
    var onTapGesture: (() -> Void)?

    var body: some View {
        Button {
            onTapGesture?()
        } label: {
            Image(systemName: systemName)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .foregroundStyle(.primary)
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }
}
