//
//  SettingsView.swift
//  xpenz
//
//  Created by Rafael Soh on 20/5/22.
//

import Combine
import ConfettiSwiftUI
import Foundation
import SwiftUI
import UserNotifications
import WidgetKit

struct SettingsView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize

  @AppStorage("colourScheme", store: UserDefaults(suiteName: "group.xyz.draumaz.nickel"))
  var colourScheme: Int = 0
  var colourSchemeString: String {
    if colourScheme == 1 {
      return String(localized: "Light")
    } else if colourScheme == 2 {
      return String(localized: "Dark")
    } else {
      return String(localized: "System")
    }
  }

  @AppStorage("activeIcon", store: UserDefaults(suiteName: "group.xyz.draumaz.nickel"))
  var activeIcon: String = "AppIcon"
  var appIconString: String {
    if activeIcon == "AppIcon1" {
      return "v2.0"
    } else if activeIcon == "AppIcon2" {
      return "Unicorn"
    } else if activeIcon == "AppIcon3" {
      return "v1.5"
    } else {
      return "O.G."
    }
  }

  @AppStorage("firstWeekday", store: UserDefaults(suiteName: "group.xyz.draumaz.nickel"))
  var firstWeekday: Int = 1
  var firstWeekdayString: String {
    if firstWeekday == 1 {
      return String(localized: "Sunday")
    } else {
      return String(localized: "Monday")
    }
  }

  @AppStorage("showNotifications", store: UserDefaults(suiteName: "group.xyz.draumaz.nickel"))
  var showNotifications: Bool = false
  @AppStorage("notificationOption", store: UserDefaults(suiteName: "group.xyz.draumaz.nickel"))
  var option: Int = 1
  var notificationString: String {
    if showNotifications {
      if option == 1 {
        return String(localized: "Mornings")
      } else if option == 2 {
        return String(localized: "Evenings")
      } else {
        return String(localized: "Custom")
      }
    } else {
      return String(localized: "Off")
    }
  }

  @EnvironmentObject var appLockVM: AppLockViewModel
  @Namespace var animation

  @AppStorage("numberEntryType", store: UserDefaults(suiteName: "group.xyz.draumaz.nickel"))
  var numberEntryType: Int = 2

  var numberEntryString: String {
    if numberEntryType == 1 {
      return String(localized: "Type 1")
    } else {
      return String(localized: "Type 2")
    }
  }

  @AppStorage("showCents", store: UserDefaults(suiteName: "group.xyz.draumaz.nickel"))
  var showCents: Bool = true

  @AppStorage("animated", store: UserDefaults(suiteName: "group.xyz.draumaz.nickel")) var animated:
    Bool = true

  @AppStorage("currency", store: UserDefaults(suiteName: "group.xyz.draumaz.nickel")) var currency:
    String = "USD"

  @AppStorage("incomeTracking", store: UserDefaults(suiteName: "group.xyz.draumaz.nickel"))
  var incomeTracking: Bool = true

  @AppStorage("showExpenseOrIncomeSign", store: UserDefaults(suiteName: "group.xyz.draumaz.nickel"))
  var showExpenseOrIncomeSign: Bool = true

  @AppStorage(
    "showUpcomingTransactions", store: UserDefaults(suiteName: "group.xyz.draumaz.nickel"))
  var showUpcoming: Bool = true

  var upcomingString: String {
    if showUpcoming {
      return String(localized: "Shown")
    } else {
      return String(localized: "Hidden")
    }
  }

    @AppStorage("haptics", store: UserDefaults(suiteName: "group.xyz.draumaz.nickel"))
    var hapticType: Int = 1

    var hapticString: String {
      if hapticType == 0 {
        return String(localized: "None")
      } else if hapticType == 1 {
        return String(localized: "Subtle")
      } else {
        return String(localized: "Excessive")
      }
    }

  // popups

  @State var showImportGuide = false
  @State var showUpdate: Bool = false

  @EnvironmentObject var dataController: DataController

  var body: some View {
    NavigationStack {
      List {
        Section("General") {
          NavigationLink(destination: SettingsNotificationsView()) {
            SettingsRowView(
              systemImage: "bell.fill", title: "Notifications", colour: 102,
              optionalText: notificationString)
          }

          NavigationLink(destination: SettingsCurrencyView()) {
            SettingsRowView(
              systemImage: "coloncurrencysign.square.fill", title: "Currency", colour: 103,
              optionalText: currency)
          }

          NavigationLink(
            destination: SettingsNumberEntryView()
              .toolbarVisibility(.hidden, for: .tabBar)
          ) {
            SettingsRowView(
              systemImage: "keyboard.fill", title: "Number Entry", colour: 104,
              optionalText: numberEntryString)
          }

          ToggleRow(
            icon: "faceid", color: "105", text: "Authentication",
            bool: appLockVM.isAppLockEnabled,
            onTap: {
              appLockVM.appLockStateChange(appLockState: !appLockVM.isAppLockEnabled)
            })

          ToggleRow(
            icon: "banknote.fill", color: "106", text: "Income Tracking", bool: incomeTracking,
            onTap: {
              incomeTracking.toggle()

              if !incomeTracking {
                UserDefaults(suiteName: "group.xyz.draumaz.nickel")!.set(
                  false, forKey: "insightsViewIncomeFiltering")
                UserDefaults(suiteName: "group.xyz.draumaz.nickel")!.set(
                  3, forKey: "logInsightsType")
              }
            })

          NavigationLink(destination: SettingsWeekStartView()) {
            SettingsRowView(systemImage: "calendar", title: "Time Frames", colour: 109)
          }
        }
        .listRowBackground(Color.SettingsBackground)

        Section("Appearance") {
          NavigationLink(destination: SettingsAppearanceView()) {
            SettingsRowView(
              systemImage: "circle.righthalf.filled", title: "Theme", colour: 100,
              optionalText: colourSchemeString)
          }

          NavigationLink(destination: SettingsAppIconView()) {
            SettingsRowView(
              systemImage: "app.badge.fill", title: "App Icon", colour: 101,
              optionalText: appIconString)
          }

          ToggleRow(
            icon: "centsign.circle.fill", color: "107", text: "Display Cents", bool: showCents,
            onTap: {
              showCents.toggle()
            })

          NavigationLink(destination: SettingsUpcomingView()) {
            SettingsRowView(
              systemImage: "sun.min.fill", title: "Upcoming Logs", colour: 108,
              optionalText: upcomingString)
          }

          ToggleRow(
            icon: "plusminus", color: "123", text: "Display +/- Symbol", bool: showExpenseOrIncomeSign,
            onTap: {
              showExpenseOrIncomeSign.toggle()
            })

          ToggleRow(
            icon: "hare.fill", color: "121", text: "Animated Charts", bool: animated, smaller: true,
            onTap: {
              animated.toggle()
            })
        }
        .listRowBackground(Color.SettingsBackground)

        Section("Data") {
          NavigationLink(
            destination: SettingsCategoryView()
              .toolbarVisibility(.hidden, for: .tabBar)
          ) {
            SettingsRowView(
              systemImage: "rectangle.grid.2x2.fill", title: "Categories", colour: 110)
          }

          Button {
            showImportGuide = true
          } label: {
            SettingsRowView(
              systemImage: "square.and.arrow.down.fill", title: "Import Data", colour: 112)
          }

          Button {
            exportData()
          } label: {
            SettingsRowView(
              systemImage: "square.and.arrow.up.fill", title: "Export Data", colour: 113)
          }

          NavigationLink(destination: SettingsEraseView()) {
            SettingsRowView(systemImage: "xmark.bin.fill", title: "Erase Data", colour: 114)
          }
        }
        .listRowBackground(Color.SettingsBackground)

        Section("Others") {
          NavigationLink(destination: SettingsHapticsView()) {
            SettingsRowView(
              systemImage: "hand.tap.fill", title: "Haptics", colour: 100,
              optionalText: hapticString)
          }

          NavigationLink(destination: SettingsGoofyView()) {
            SettingsRowView(systemImage: "flame.fill", title: "Feature Lab", colour: 122)
          }

        }
        .listRowBackground(Color.SettingsBackground)

        Section {
          VStack(spacing: 5) {
            HStack(spacing: 3) {
              Text("Version \(UIApplication.appVersion ?? "") (\(UIApplication.buildNumber ?? ""))")
                .foregroundStyle(.secondary)

              Text("·")
                .foregroundStyle(.secondary)

              Button("What's New") {
                showUpdate = true
              }
              .buttonStyle(.plain)
              .foregroundStyle(.primary)
            }

            // Credits the original project, as its GPL-3 licence requires.
            Text("Nickel is based on Dime by Rafael Soh")
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
          }
          .font(.system(.footnote, design: .rounded).weight(.medium))
          .frame(maxWidth: .infinity)
          .listRowBackground(Color.clear)
        }
      }
      .listStyle(.insetGrouped)
      // Keep the app's themed background behind the system grouped list.
      .scrollContentBackground(.hidden)
      .background(Color.PrimaryBackground)
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.large)
      .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
      .onChange(of: currency) {
        WidgetCenter.shared.reloadAllTimelines()
      }
      .onChange(of: firstWeekday) {
        WidgetCenter.shared.reloadAllTimelines()
      }
      .onChange(of: showCents) {
        WidgetCenter.shared.reloadAllTimelines()
      }
      .fullScreenCover(isPresented: $showUpdate) {
        UpdateAlert()
      }
      .fullScreenCover(isPresented: $showImportGuide) {
        ImportDataView()
      }
    }
  }

  /// A settings row with a system toggle. `onTap` performs the change, so callers keep
  /// their existing side effects.
  func ToggleRow(icon: String, color: String, text: String, bool: Bool, smaller: Bool = false, onTap: @escaping () -> Void)
    -> some View {
    Toggle(isOn: Binding(get: { bool }, set: { _ in withAnimation { onTap() } })) {
      SettingsRowLabel(systemImage: icon, title: text, colour: color, smallerIcon: smaller)
    }
    .tint(.green)
  }

  func exportData() {
    let fetchRequest = dataController.fetchRequestForExport()
    let transactions = dataController.results(for: fetchRequest)

    let fileName = "export.csv"
    let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    var csvText = "Date,Note,Amount,Category,Type\n"

    for transaction in transactions {
      var string = transaction.wrappedNote
      let type: String

      if transaction.income {
        type = "Income"
      } else {
        type = "Expense"
      }

      string.removeAll(where: { $0 == "," })

      csvText +=
        "\(transaction.wrappedDate),\(string),\(String(format: "%.2f", transaction.wrappedAmount)),\(transaction.category?.wrappedName ?? ""),\(type)\n"
    }

    do {
      try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
    } catch {
      print("\(error)")
    }

    var filesToShare = [Any]()
    filesToShare.append(path!)

    let av = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)

    let allScenes = UIApplication.shared.connectedScenes
    let scene = allScenes.first { $0.activationState == .foregroundActive }

    if let windowScene = scene as? UIWindowScene {
      windowScene.keyWindow?.rootViewController?.present(av, animated: true, completion: nil)
    }
  }
}

/// The icon and title shared by settings rows, in the style of the system Settings app.
struct SettingsRowLabel: View {
  var systemImage: String
  var title: String
  var colour: String
  var smallerIcon = false

  @Environment(\.dynamicTypeSize) var dynamicTypeSize

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: systemImage)
        .font(.system(smallerIcon ? .subheadline : .body, design: .rounded))
        .foregroundStyle(.white)
        .frame(
          width: dynamicTypeSize > .xLarge ? 40 : 30, height: dynamicTypeSize > .xLarge ? 40 : 30,
          alignment: .center
        )
        .background(Color(colour), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

      Text(LocalizedStringKey(title))
        .font(.system(.body, design: .rounded).weight(.medium))
        .lineLimit(1)
        .foregroundStyle(Color.PrimaryText)
    }
  }
}

/// A settings row for navigation and actions. Navigation rows get their chevron from
/// `NavigationLink`; action rows have none, matching system behaviour.
struct SettingsRowView: View {
  var systemImage: String
  var title: String
  var colour: Int
  var optionalText: String?

  var body: some View {
    HStack(spacing: 12) {
      SettingsRowLabel(systemImage: systemImage, title: title, colour: "\(colour)")

      Spacer()

      if let optionalText {
        Text(optionalText)
          .font(.system(.body, design: .rounded))
          .foregroundStyle(.secondary)
          .layoutPriority(1)
      }
    }
    .frame(maxWidth: .infinity)
    .contentShape(Rectangle())
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
  }
}

struct SettingsCategoryView: View {
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

  var body: some View {
    CategoryView(mode: .settings, income: false)
      .navigationBarBackButtonHidden(true)
      .navigationBarTitle("")
      .navigationBarHidden(true)
      .background(Color.PrimaryBackground)
  }
}
