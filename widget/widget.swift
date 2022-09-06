//
//  widget.swift
//  widget
//
//  Created by Alexey Ankip on 12.08.22.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> BudgetStatEntry {
        BudgetStatEntry(date: Date(), stat: BudgetStat())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (BudgetStatEntry) -> ()) {
        let date = Date()
        let entry: BudgetStatEntry

        entry = BudgetStatEntry(date: date, stat: BudgetStat())
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        
        // Create a timeline entry for "now."
        let date = Date()
        
        // Create a date that's 15 minutes in the future.
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: date)!
        
        BudgetWebService.fetchBudgetStat{ (result) in
            if let stat = try? result.get() {
                let entry = BudgetStatEntry(date: date, stat: stat)
                let timeline = Timeline(
                    entries:[entry],
                    policy: .after(nextUpdateDate)
                )
                completion(timeline)
            } else {
                let entry = BudgetStatEntry(date: date, stat: BudgetStat())
                let timeline = Timeline(
                    entries:[entry],
                    policy: .after(nextUpdateDate)
                )
                completion(timeline)
            }
        }
    }
}

struct BudgetStatEntry: TimelineEntry {
    let date: Date
    let stat: BudgetStat
}

struct widgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        let s = entry.stat

        let spentVal = Double((s.budgetAmount - s.totalBalance)/s.budgetAmount)
        
        let deviationVal = Double( (s.balanceDeviation > 0 ? s.balanceDeviation : -1 * s.balanceDeviation) / s.budgetAmount)
        let deviationStart = s.balanceDeviation > 0 ? spentVal : spentVal - deviationVal
        
        let deviationColar = s.balanceDeviation > 0 ? Color(red: 0, green: 0.6667, blue: 0.1765) : Color(.red)
        
        let totalBalanceFmt = s.totalBalance.formatted(.number.precision(.fractionLength(0)))
        
        let deviationFmt = (s.balanceDeviation > 0 ? "+" : "") + s.balanceDeviation.formatted(.number.precision(.fractionLength(0)))
        
        let daysLeftFmt = s.budgetDaysToExpiration.formatted(.number.precision(.fractionLength(1)))
        
        VStack{
            Spacer().frame(width: 0, height: 10)
            ZStack {
                // budget (back)
                CircleView(start: 0, val: 1, color: .cyan)
                VStack {
                    Text(totalBalanceFmt)
                        .font(.system(size: 30))
                        .foregroundColor(.cyan)
                        .bold()
                    Text(deviationFmt)
                        .font(.system(size: 25))
                        .bold()
                        .foregroundColor(deviationColar)
                }
                
                // spent
                CircleView(start: 0, val: spentVal, color: .gray)
                // deviation
                CircleView(start: deviationStart, val: deviationVal, color: deviationColar)
            }.frame(width: 115, height: 115)
            Spacer().frame(width: 0, height: 10)
            Text("\(daysLeftFmt) days left")
                .font(.system(size: 10))
        }
    }
}

@main
struct widget: Widget {
    let kind: String = "widget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            widgetEntryView(entry: entry)
        }
        .configurationDisplayName("OnTrack")
        .description("OnTrack description")
    }
}

struct widget_Previews: PreviewProvider {
    static var previews: some View {
        widgetEntryView(entry: BudgetStatEntry(
            date: Date(),

            stat: BudgetStat(budgetAmount: 1000, budgetStartedAt: 0, budgetExpiresAt: 0, budgetDaysToExpiration: 10.3, accountBalance: 700, cashBalance: 100, totalBalance: 800, estimatedBalance: 700, balanceDeviation: 20)))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

struct BudgetStat: Decodable {
    var budgetAmount : Float = 0
    var budgetStartedAt: Int = 0
    var budgetExpiresAt: Int = 0
    var budgetDaysToExpiration: Float = 0
    var accountBalance: Float = 0
    var cashBalance: Float = 0
    var totalBalance: Float = 0
    var estimatedBalance: Float = 0
    var balanceDeviation: Float = 0
    
    /*
     "budget_amount": 1855.75,
     "budget_started_at": 1659684978,
     "budget_expires_at": 1660635378,
     "budget_days_to_expiration": 3.7271803861270834,
     "account_balance": 329.54,
     "cash_balance": 340,
     "total_balance": 669.54,
     "estimated_balance": 628.7934730113636,
     "balance_deviation": 40.74652698863633
     */
}


class BudgetWebService {
    static func fetchBudgetStat(callback: @escaping (Result<BudgetStat, Error>)->Void) {
        
            guard let url = URL(string: "https://alfa-booker.herokuapp.com/budget_stat") else { return }
        
            var request = URLRequest(url: url)
            request.setValue("d6154016-cd46-4235-ab40-7971a6a5ced7", forHTTPHeaderField: "Auth-Token")

            URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data else {
                    if let error = error {
                        callback(.failure(error))
                    }
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let result = try decoder.decode(BudgetStat.self, from: data)
                    
                    callback(.success(result))
                } catch {
                    callback(.failure(error))
                }
            }.resume()
        }
}


struct CircleView: View {
    let start: Double
    let val: Double
    let color: Color
    
    var body: some View {
            Circle()
                .trim(from: 0, to: val)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: 15
                    )
                )
                .rotationEffect(.degrees(360*start-90))
    }
}
