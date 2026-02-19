//
//  OrganizerAnalytics.swift
//  EventPassUG
//
//  Comprehensive analytics model for organizer dashboard
//

import SwiftUI

// MARK: - Main Analytics Model

struct OrganizerAnalytics: Identifiable, Codable {
    let id: UUID
    let eventId: UUID
    let eventTitle: String
    let lastUpdated: Date

    // MARK: - Overview
    var revenue: Double
    var ticketsSold: Int
    var totalCapacity: Int
    var attendanceRate: Double // 0.0 - 1.0
    var capacityUsed: Double // 0.0 - 1.0
    var salesTarget: Double
    var salesProgress: Double // 0.0 - 1.0

    // MARK: - Sales Performance
    var salesOverTime: [SalesDataPoint]
    var salesByTier: [TierSalesData]
    var ticketVelocity: Double // tickets per hour
    var sellOutForecast: SellOutForecast?
    var dailySalesAverage: Double
    var peakSalesDay: String?

    // MARK: - Audience Insights
    var totalAttendees: Int
    var repeatAttendees: Int
    var repeatRate: Double // 0.0 - 1.0
    var vipShare: Double // 0.0 - 1.0 (premium ticket holders)
    var demographics: DemographicsData?
    var newVsReturning: NewVsReturningData

    // MARK: - Marketing & Conversion
    var eventViews: Int
    var uniqueViews: Int
    var conversionRate: Double // 0.0 - 1.0
    var trafficSources: [TrafficSourceData]
    var promoPerformance: [PromoPerformanceData]
    var shareCount: Int
    var saveCount: Int

    // MARK: - Operations
    var checkinRate: Double // 0.0 - 1.0
    var peakArrivalTime: String?
    var averageArrivalTime: String?
    var queueEstimate: Int // minutes
    var checkinsByHour: [CheckinDataPoint]

    // MARK: - Financial
    var paymentMethodsSplit: [PaymentMethodData]
    var grossRevenue: Double
    var netRevenue: Double
    var platformFees: Double
    var processingFees: Double
    var refundsTotal: Double
    var refundsCount: Int

    // MARK: - Insights & Alerts
    var alerts: [AnalyticsAlert]
    var revenueForecast: Double?
    var healthScore: Int // 0-100

    // MARK: - Computed Properties

    var formattedRevenue: String {
        formatCurrency(revenue)
    }

    var formattedNetRevenue: String {
        formatCurrency(netRevenue)
    }

    var capacityPercentage: Int {
        Int(capacityUsed * 100)
    }

    var attendancePercentage: Int {
        Int(attendanceRate * 100)
    }

    var conversionPercentage: Double {
        conversionRate * 100
    }

    var remainingCapacity: Int {
        totalCapacity - ticketsSold
    }

    var averageTicketPrice: Double {
        guard ticketsSold > 0 else { return 0 }
        return revenue / Double(ticketsSold)
    }

    var totalFees: Double {
        platformFees + processingFees
    }

    private func formatCurrency(_ amount: Double) -> String {
        if amount >= 1_000_000 {
            return String(format: "UGX %.1fM", amount / 1_000_000)
        } else if amount >= 1_000 {
            return String(format: "UGX %.0fK", amount / 1_000)
        } else {
            return String(format: "UGX %.0f", amount)
        }
    }
}

// MARK: - Supporting Data Types

struct SalesDataPoint: Identifiable, Codable {
    let id: UUID
    let date: Date
    let sales: Int
    let revenue: Double

    init(id: UUID = UUID(), date: Date, sales: Int, revenue: Double) {
        self.id = id
        self.date = date
        self.sales = sales
        self.revenue = revenue
    }
}

struct TierSalesData: Identifiable, Codable {
    let id: UUID
    let tierName: String
    let sold: Int
    let capacity: Int
    let revenue: Double
    let price: Double
    let color: String // Hex color

    var percentage: Double {
        guard capacity > 0 else { return 0 }
        return Double(sold) / Double(capacity)
    }

    var remainingTickets: Int {
        capacity - sold
    }

    var isSoldOut: Bool {
        sold >= capacity
    }

    init(id: UUID = UUID(), tierName: String, sold: Int, capacity: Int, revenue: Double, price: Double, color: String = "FF7A00") {
        self.id = id
        self.tierName = tierName
        self.sold = sold
        self.capacity = capacity
        self.revenue = revenue
        self.price = price
        self.color = color
    }
}

struct SellOutForecast: Codable {
    let estimatedDate: Date?
    let confidence: Double // 0.0 - 1.0
    let daysRemaining: Int?
    let willSellOut: Bool

    var confidenceLevel: String {
        switch confidence {
        case 0.8...: return "High"
        case 0.5..<0.8: return "Medium"
        default: return "Low"
        }
    }
}

struct DemographicsData: Codable {
    let ageGroups: [AgeGroupData]
    let topCities: [CityData]
}

struct AgeGroupData: Identifiable, Codable {
    let id: UUID
    let ageRange: String
    let percentage: Double
    let count: Int

    init(id: UUID = UUID(), ageRange: String, percentage: Double, count: Int) {
        self.id = id
        self.ageRange = ageRange
        self.percentage = percentage
        self.count = count
    }
}

struct CityData: Identifiable, Codable {
    let id: UUID
    let city: String
    let count: Int
    let percentage: Double

    init(id: UUID = UUID(), city: String, count: Int, percentage: Double) {
        self.id = id
        self.city = city
        self.count = count
        self.percentage = percentage
    }
}

struct NewVsReturningData: Codable {
    let newAttendees: Int
    let returningAttendees: Int

    var newPercentage: Double {
        let total = newAttendees + returningAttendees
        guard total > 0 else { return 0 }
        return Double(newAttendees) / Double(total)
    }

    var returningPercentage: Double {
        let total = newAttendees + returningAttendees
        guard total > 0 else { return 0 }
        return Double(returningAttendees) / Double(total)
    }
}

struct TrafficSourceData: Identifiable, Codable {
    let id: UUID
    let source: String
    let visits: Int
    let conversions: Int
    let percentage: Double
    let icon: String

    var conversionRate: Double {
        guard visits > 0 else { return 0 }
        return Double(conversions) / Double(visits)
    }

    init(id: UUID = UUID(), source: String, visits: Int, conversions: Int, percentage: Double, icon: String = "globe") {
        self.id = id
        self.source = source
        self.visits = visits
        self.conversions = conversions
        self.percentage = percentage
        self.icon = icon
    }
}

struct PromoPerformanceData: Identifiable, Codable {
    let id: UUID
    let promoCode: String
    let usageCount: Int
    let revenue: Double
    let discountGiven: Double
    let isActive: Bool

    init(id: UUID = UUID(), promoCode: String, usageCount: Int, revenue: Double, discountGiven: Double, isActive: Bool = true) {
        self.id = id
        self.promoCode = promoCode
        self.usageCount = usageCount
        self.revenue = revenue
        self.discountGiven = discountGiven
        self.isActive = isActive
    }
}

struct CheckinDataPoint: Identifiable, Codable {
    let id: UUID
    let hour: Int // 0-23
    let checkins: Int

    var formattedHour: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    init(id: UUID = UUID(), hour: Int, checkins: Int) {
        self.id = id
        self.hour = hour
        self.checkins = checkins
    }
}

struct PaymentMethodData: Identifiable, Codable {
    let id: UUID
    let method: String
    let amount: Double
    let count: Int
    let percentage: Double
    let color: String // Hex color
    let icon: String

    init(id: UUID = UUID(), method: String, amount: Double, count: Int, percentage: Double, color: String, icon: String) {
        self.id = id
        self.method = method
        self.amount = amount
        self.count = count
        self.percentage = percentage
        self.color = color
        self.icon = icon
    }
}

// MARK: - Alerts

struct AnalyticsAlert: Identifiable, Codable {
    let id: UUID
    let type: AlertType
    let title: String
    let message: String
    let severity: AlertSeverity
    let actionTitle: String?
    let timestamp: Date

    init(id: UUID = UUID(), type: AlertType, title: String, message: String, severity: AlertSeverity, actionTitle: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.severity = severity
        self.actionTitle = actionTitle
        self.timestamp = timestamp
    }

    enum AlertType: String, Codable {
        case lowSales
        case highDemand
        case nearSellOut
        case revenueForecast
        case slowSales
        case pricingOpportunity
        case refundSpike
        case capacityWarning
    }

    enum AlertSeverity: String, Codable {
        case info
        case warning
        case success
        case critical

        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .success: return .green
            case .critical: return .red
            }
        }

        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            case .critical: return "xmark.octagon.fill"
            }
        }
    }
}

// MARK: - Mock Data

extension OrganizerAnalytics {
    static var mock: OrganizerAnalytics {
        let calendar = Calendar.current
        let now = Date()

        // Generate sales over time data (last 14 days)
        var salesOverTime: [SalesDataPoint] = []
        for i in (0..<14).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            let baseSales = Int.random(in: 5...25)
            let sales = i < 3 ? baseSales + Int.random(in: 10...20) : baseSales // Recent spike
            salesOverTime.append(SalesDataPoint(
                date: date,
                sales: sales,
                revenue: Double(sales) * Double.random(in: 25000...75000)
            ))
        }

        // Generate checkins by hour
        var checkinsByHour: [CheckinDataPoint] = []
        let peakHours = [17, 18, 19, 20] // 5PM - 8PM peak
        for hour in 14...23 {
            let base = peakHours.contains(hour) ? Int.random(in: 40...80) : Int.random(in: 5...25)
            checkinsByHour.append(CheckinDataPoint(hour: hour, checkins: base))
        }

        return OrganizerAnalytics(
            id: UUID(),
            eventId: UUID(),
            eventTitle: "Kampala Music Festival 2026",
            lastUpdated: Date(),

            // Overview
            revenue: 12_450_000,
            ticketsSold: 342,
            totalCapacity: 500,
            attendanceRate: 0.78,
            capacityUsed: 0.684,
            salesTarget: 18_000_000,
            salesProgress: 0.69,

            // Sales Performance
            salesOverTime: salesOverTime,
            salesByTier: [
                TierSalesData(tierName: "Early Bird", sold: 100, capacity: 100, revenue: 2_500_000, price: 25_000, color: "34C759"),
                TierSalesData(tierName: "Regular", sold: 180, capacity: 250, revenue: 6_300_000, price: 35_000, color: "FF7A00"),
                TierSalesData(tierName: "VIP", sold: 52, capacity: 100, revenue: 3_120_000, price: 60_000, color: "FFD700"),
                TierSalesData(tierName: "VVIP", sold: 10, capacity: 50, revenue: 1_000_000, price: 100_000, color: "AF52DE")
            ],
            ticketVelocity: 4.2,
            sellOutForecast: SellOutForecast(
                estimatedDate: calendar.date(byAdding: .day, value: 12, to: now),
                confidence: 0.72,
                daysRemaining: 12,
                willSellOut: true
            ),
            dailySalesAverage: 24.4,
            peakSalesDay: "Saturday",

            // Audience Insights
            totalAttendees: 267,
            repeatAttendees: 89,
            repeatRate: 0.33,
            vipShare: 0.18,
            demographics: DemographicsData(
                ageGroups: [
                    AgeGroupData(ageRange: "18-24", percentage: 0.35, count: 120),
                    AgeGroupData(ageRange: "25-34", percentage: 0.42, count: 144),
                    AgeGroupData(ageRange: "35-44", percentage: 0.15, count: 51),
                    AgeGroupData(ageRange: "45+", percentage: 0.08, count: 27)
                ],
                topCities: [
                    CityData(city: "Kampala", count: 245, percentage: 0.72),
                    CityData(city: "Entebbe", count: 48, percentage: 0.14),
                    CityData(city: "Jinja", count: 27, percentage: 0.08),
                    CityData(city: "Other", count: 22, percentage: 0.06)
                ]
            ),
            newVsReturning: NewVsReturningData(newAttendees: 178, returningAttendees: 89),

            // Marketing & Conversion
            eventViews: 4_850,
            uniqueViews: 3_240,
            conversionRate: 0.071,
            trafficSources: [
                TrafficSourceData(source: "Direct", visits: 1_420, conversions: 118, percentage: 0.44, icon: "link"),
                TrafficSourceData(source: "Instagram", visits: 980, conversions: 76, percentage: 0.30, icon: "camera"),
                TrafficSourceData(source: "WhatsApp", visits: 520, conversions: 48, percentage: 0.16, icon: "message"),
                TrafficSourceData(source: "Twitter/X", visits: 320, conversions: 22, percentage: 0.10, icon: "at")
            ],
            promoPerformance: [
                PromoPerformanceData(promoCode: "EARLY20", usageCount: 45, revenue: 900_000, discountGiven: 225_000),
                PromoPerformanceData(promoCode: "VIP10", usageCount: 12, revenue: 648_000, discountGiven: 72_000)
            ],
            shareCount: 234,
            saveCount: 156,

            // Operations
            checkinRate: 0.78,
            peakArrivalTime: "7:30 PM",
            averageArrivalTime: "6:45 PM",
            queueEstimate: 8,
            checkinsByHour: checkinsByHour,

            // Financial
            paymentMethodsSplit: [
                PaymentMethodData(method: "MTN MoMo", amount: 7_470_000, count: 205, percentage: 0.60, color: "FFCC00", icon: "phone.fill"),
                PaymentMethodData(method: "Airtel Money", amount: 3_735_000, count: 103, percentage: 0.30, color: "ED1C24", icon: "phone.fill"),
                PaymentMethodData(method: "Card", amount: 1_245_000, count: 34, percentage: 0.10, color: "007AFF", icon: "creditcard.fill")
            ],
            grossRevenue: 12_450_000,
            netRevenue: 11_456_000,
            platformFees: 622_500,
            processingFees: 373_500,
            refundsTotal: 175_000,
            refundsCount: 5,

            // Insights & Alerts
            alerts: [
                AnalyticsAlert(
                    type: .nearSellOut,
                    title: "Near Sell-out",
                    message: "Early Bird tickets are sold out! Consider adding more or increasing Regular prices.",
                    severity: .success,
                    actionTitle: "Manage Tickets"
                ),
                AnalyticsAlert(
                    type: .highDemand,
                    title: "High Demand Detected",
                    message: "Sales velocity increased 40% in the last 24 hours.",
                    severity: .info
                ),
                AnalyticsAlert(
                    type: .pricingOpportunity,
                    title: "Pricing Opportunity",
                    message: "VIP tickets are selling faster than Regular. Consider a price adjustment.",
                    severity: .warning,
                    actionTitle: "Review Pricing"
                )
            ],
            revenueForecast: 16_800_000,
            healthScore: 82
        )
    }

    static var smallEventMock: OrganizerAnalytics {
        var mock = Self.mock
        mock.ticketsSold = 45
        mock.totalCapacity = 100
        mock.revenue = 1_575_000
        mock.capacityUsed = 0.45
        mock.eventViews = 320
        mock.conversionRate = 0.14
        return mock
    }
}
