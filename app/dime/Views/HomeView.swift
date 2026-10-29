//
//  HomeView.swift
//  xpenz
//
//  Created by Rafael Soh on 20/5/22.
//

import ConfettiSwiftUI
import CoreData
import Foundation
import SwiftUI

class OverallToastPresenter: ObservableObject {
    @Published var showToast: Bool = false
}

enum DeletionType {
    case instant
    case prompt
}

class OverallTransactionManager: ObservableObject {
    @Published var toEdit: Transaction?
    @Published var toDelete: Transaction?
    @Published var showToast: Bool = false
    @Published var showPopup: Bool = false
    @Published var future: Bool = false
}

struct HomeView: View {
    @EnvironmentObject var appLockVM: AppLockViewModel

    @StateObject var toastPresenter = OverallToastPresenter()
    @StateObject var transactionManager = OverallTransactionManager()
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var dataController: DataController

    @State var currentTab = "Log"

    var topEdge: CGFloat
    var bottomEdge: CGFloat

    @State var fromURL1: Bool = false
    @State var fromURL2: Bool = false
    @State var fromURL3: Bool = false
    @State var fromURL4: Bool = false

    @State var launchAdd: Bool = false
    @State var launchSearch: Bool = false

    @State var counter = 0

    @State var showPopup = false

    // New-transaction sheet, launched from the prominent Add tab
    @State var addTransaction = false
    @State var transactionCountBeforeAdd = 0

    @FetchRequest(sortDescriptors: []) private var transactions: FetchedResults<Transaction>

    @AppStorage("confetti", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var confetti: Bool = false
    @AppStorage("firstTransactionViewLaunch", store: UserDefaults(suiteName: "group.com.rafaelsoh.dime")) var firstLaunch: Bool = true

    init(topEdge: CGFloat, bottomEdge: CGFloat) {
        self.topEdge = topEdge
        self.bottomEdge = bottomEdge
    }

    /// Selection value for the Add tab. Selecting it presents the new-transaction sheet
    /// rather than switching tabs.
    private static let addTabValue = "Add"

    /// Intercepts selection of the Add tab so the tab bar keeps the current tab selected
    /// while the new-transaction sheet is presented.
    private var tabSelection: Binding<String> {
        Binding {
            currentTab
        } set: { newValue in
            if newValue == Self.addTabValue {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                addTransaction = true
            } else {
                currentTab = newValue
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: tabSelection) {
                Tab("Log", systemImage: "list.bullet.rectangle", value: "Log") {
                    LogView(topEdge: topEdge, bottomEdge: bottomEdge, launchSearch: launchSearch)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Tab("Insights", systemImage: "chart.pie", value: "Insights") {
                    InsightsView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Tab("Budget", systemImage: "chart.bar", value: "Budget") {
                    BudgetView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Tab("Settings", systemImage: "gearshape", value: "Settings") {
                    SettingsView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // The prominent tab is the system's treatment for a high-frequency action
                // such as composing; it never becomes the selected tab (see `tabSelection`).
                Tab("Add Transaction", systemImage: "plus", value: Self.addTabValue, role: .prominent) {
                    Color.clear
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .allowsHitTesting(showPopup ? false : true)
            .environmentObject(toastPresenter)
            .environmentObject(transactionManager)

            if showPopup {
                Rectangle()
                    .fill(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        transactionManager.showPopup = false
                    }
            }

            DeleteTransactionAlert()
                .offset(y: showPopup ? 0 : 300)
                .environmentObject(transactionManager)

            if appLockVM.isAppLockEnabled && !appLockVM.isAppUnLocked {
                AppLockView()
                    .ignoresSafeArea(.all)
                    .onOpenURL { url in

                        if url.host == "newExpense" {
                            fromURL1 = true
                        } else if url.host == "search" {
                            fromURL2 = true
                        } else if url.host == "insights" {
                            fromURL3 = true
                        } else if url.host == "budget" {
                            fromURL4 = true
                        }
                    }
            }
        }
        .toast(isPresenting: $toastPresenter.showToast, duration: 4, tapToDismiss: true, offsetY: 12, alert: {
            AlertToast(displayMode: .hud, type: .systemImage("checkmark.circle.fill", Color.IncomeGreen), title: "Image Saved", subTitle: "Check it out in Photos")
        })
        .toast(isPresenting: $transactionManager.showToast, duration: 4, tapToDismiss: true, offsetY: 12, alert: {
            AlertToast(displayMode: .hud, type: .systemImage("arrow.uturn.backward.circle.fill", Color.AlertRed), title: "Log Deleted", subTitle: "Tap to Undo")
        }, onTap: {
            withAnimation(.easeInOut(duration: 0.5)) {
                moc.rollback()
            }
            transactionManager.toDelete = nil
        }, completion: {
            dataController.save()
            transactionManager.toDelete = nil
        })
        .onChange(of: transactionManager.showPopup) { newValue in
            withAnimation {
                showPopup = newValue
            }
        }
        .fullScreenCover(item: $transactionManager.toEdit, onDismiss: {
            transactionManager.toEdit = nil
        }) { transaction in
            TransactionView(toEdit: transaction)
        }
        .fullScreenCover(isPresented: $addTransaction, onDismiss: {
            if confetti && transactionCountBeforeAdd != transactions.count {
                counter += 1
            }

            if firstLaunch {
                firstLaunch = false
            }
        }, content: {
            TransactionView(toEdit: nil)
        })
        .onChange(of: addTransaction) { _, isPresented in
            if isPresented {
                transactionCountBeforeAdd = transactions.count
            }
        }
        .onChange(of: launchAdd) {
            addTransaction = true
        }
        .confettiCannon(counter: $counter, num: 50, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 200)
        .onAppear {
            if appLockVM.isAppLockEnabled && fromURL1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    launchAdd.toggle()
                }

                fromURL1 = false
            }

            if appLockVM.isAppLockEnabled && fromURL2 {
                currentTab = "Log"

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    launchSearch.toggle()
                }

                fromURL2 = false
            }

            if appLockVM.isAppLockEnabled && fromURL3 {
                currentTab = "Insights"
            }

            if appLockVM.isAppLockEnabled && fromURL4 {
                currentTab = "Budget"
            }
        }
        .onOpenURL { url in
            if url.host == "newExpense" {
                addTransaction = true
            } else if url.host == "search" {
                currentTab = "Log"
            } else if url.host == "insights" {
                currentTab = "Insights"
            } else if url.host == "budget" {
                currentTab = "Budget"
            }
        }
    }
}

struct AppLockView: View {
    @EnvironmentObject var appLockVM: AppLockViewModel

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "lock.fill")
                .font(.system(size: 65))
                .foregroundColor(Color.DarkIcon.opacity(0.7))

            Text("App Locked")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .padding(.bottom, 30)

            Button {
                appLockVM.appLockValidation()
            } label: {
                HStack {
                    Image(systemName: "faceid")

                    Text("Unlock App")
                }
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .padding(.horizontal, 40)
                .padding(.vertical, 15)
                .overlay {
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(Color.Outline)
                }
            }

            if appLockVM.enrollmentError {
                Text("Please re-enable Face ID access in the Settings app to unlock application.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(Color.SubtitleText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.PrimaryBackground)
    }
}
