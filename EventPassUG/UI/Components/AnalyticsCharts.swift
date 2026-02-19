//
//  AnalyticsCharts.swift
//  EventPassUG
//
//  Custom chart components for analytics dashboard
//  SwiftUI-native implementations without external dependencies
//

import SwiftUI

// MARK: - Donut Chart

struct DonutChartView: View {
    let segments: [DonutSegment]
    var size: CGFloat = 120
    var lineWidth: CGFloat = 20
    var showLabels: Bool = true
    var centerText: String?
    var centerSubtext: String?

    @State private var animationProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: lineWidth)
                    .frame(width: size, height: size)

                // Segments
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    DonutSegmentShape(
                        startAngle: startAngle(for: index),
                        endAngle: endAngle(for: index),
                        progress: animationProgress
                    )
                    .stroke(Color(hex: segment.color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: size, height: size)
                }

                // Center content
                if let centerText = centerText {
                    VStack(spacing: 2) {
                        Text(centerText)
                            .font(AppTypography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        if let subtext = centerSubtext {
                            Text(subtext)
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Legend
            if showLabels {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppSpacing.sm) {
                    ForEach(segments) { segment in
                        HStack(spacing: AppSpacing.xs) {
                            Circle()
                                .fill(Color(hex: segment.color))
                                .frame(width: 10, height: 10)
                            Text(segment.label)
                                .font(AppTypography.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(segment.percentage * 100))%")
                                .font(AppTypography.captionEmphasized)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
    }

    private func startAngle(for index: Int) -> Angle {
        let precedingPercentages = segments.prefix(index).reduce(0) { $0 + $1.percentage }
        return .degrees(precedingPercentages * 360 - 90)
    }

    private func endAngle(for index: Int) -> Angle {
        let includingCurrent = segments.prefix(index + 1).reduce(0) { $0 + $1.percentage }
        return .degrees(includingCurrent * 360 - 90)
    }
}

struct DonutSegment: Identifiable {
    let id: UUID
    let label: String
    let value: Double
    let percentage: Double
    let color: String

    init(id: UUID = UUID(), label: String, value: Double, percentage: Double, color: String) {
        self.id = id
        self.label = label
        self.value = value
        self.percentage = percentage
        self.color = color
    }
}

struct DonutSegmentShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        let animatedEndAngle = Angle(
            degrees: startAngle.degrees + (endAngle.degrees - startAngle.degrees) * Double(progress)
        )

        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: animatedEndAngle,
            clockwise: false
        )
        return path
    }
}

// MARK: - Line Chart

struct LineChartView: View {
    let dataPoints: [LineChartDataPoint]
    var lineColor: Color = AppColors.primary
    var fillGradient: Bool = true
    var showPoints: Bool = true
    var showGrid: Bool = true
    var height: CGFloat = 150
    var showXLabels: Bool = true
    var showYLabels: Bool = true

    @State private var animationProgress: CGFloat = 0
    @State private var selectedPoint: LineChartDataPoint?

    private var maxValue: Double {
        dataPoints.map(\.value).max() ?? 1
    }

    private var minValue: Double {
        0 // Start from 0 for better visualization
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let chartHeight = geometry.size.height - (showXLabels ? 24 : 0)

                ZStack(alignment: .bottom) {
                    // Grid lines
                    if showGrid {
                        GridLinesView(lineCount: 4, height: chartHeight)
                    }

                    // Y-axis labels
                    if showYLabels {
                        YAxisLabelsView(maxValue: maxValue, height: chartHeight)
                    }

                    // Gradient fill
                    if fillGradient {
                        LinearGradient(
                            colors: [lineColor.opacity(0.3), lineColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(
                            LineChartFillShape(
                                dataPoints: dataPoints,
                                maxValue: maxValue,
                                progress: animationProgress
                            )
                        )
                        .frame(height: chartHeight)
                    }

                    // Line
                    LineChartLineShape(
                        dataPoints: dataPoints,
                        maxValue: maxValue,
                        progress: animationProgress
                    )
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .frame(height: chartHeight)

                    // Data points
                    if showPoints {
                        ForEach(Array(dataPoints.enumerated()), id: \.element.id) { index, point in
                            let x = CGFloat(index) / CGFloat(max(dataPoints.count - 1, 1)) * width
                            let y = chartHeight - (CGFloat((point.value - minValue) / (maxValue - minValue)) * chartHeight * animationProgress)

                            Circle()
                                .fill(lineColor)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .position(x: x, y: y)
                                .opacity(animationProgress)
                        }
                    }

                    // X-axis labels
                    if showXLabels {
                        HStack {
                            ForEach(Array(stride(from: 0, to: dataPoints.count, by: max(1, dataPoints.count / 5))), id: \.self) { index in
                                if index < dataPoints.count {
                                    Text(dataPoints[index].label)
                                        .font(AppTypography.caption)
                                        .foregroundColor(.secondary)
                                }
                                if index < dataPoints.count - 1 {
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .offset(y: chartHeight + 8)
                    }
                }
            }
            .frame(height: height)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animationProgress = 1.0
            }
        }
    }
}

struct LineChartDataPoint: Identifiable {
    let id: UUID
    let label: String
    let value: Double

    init(id: UUID = UUID(), label: String, value: Double) {
        self.id = id
        self.label = label
        self.value = value
    }
}

struct LineChartLineShape: Shape {
    let dataPoints: [LineChartDataPoint]
    let maxValue: Double
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard dataPoints.count > 1 else { return Path() }

        var path = Path()
        let stepX = rect.width / CGFloat(dataPoints.count - 1)

        for (index, point) in dataPoints.enumerated() {
            let x = CGFloat(index) * stepX
            let normalizedY = CGFloat(point.value / maxValue)
            let y = rect.height - (normalizedY * rect.height * progress)

            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct LineChartFillShape: Shape {
    let dataPoints: [LineChartDataPoint]
    let maxValue: Double
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard dataPoints.count > 1 else { return Path() }

        var path = Path()
        let stepX = rect.width / CGFloat(dataPoints.count - 1)

        // Start at bottom left
        path.move(to: CGPoint(x: 0, y: rect.height))

        // Draw line to each point
        for (index, point) in dataPoints.enumerated() {
            let x = CGFloat(index) * stepX
            let normalizedY = CGFloat(point.value / maxValue)
            let y = rect.height - (normalizedY * rect.height * progress)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        // Close path
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()

        return path
    }
}

struct GridLinesView: View {
    let lineCount: Int
    let height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<lineCount, id: \.self) { _ in
                Spacer()
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 1)
            }
            Spacer()
        }
        .frame(height: height)
    }
}

struct YAxisLabelsView: View {
    let maxValue: Double
    let height: CGFloat

    var body: some View {
        VStack {
            Text(formatValue(maxValue))
            Spacer()
            Text(formatValue(maxValue * 0.5))
            Spacer()
            Text("0")
        }
        .font(AppTypography.caption)
        .foregroundColor(.secondary)
        .frame(height: height)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

// MARK: - Bar Chart

struct BarChartView: View {
    let bars: [BarChartData]
    var barColor: Color = AppColors.primary
    var height: CGFloat = 150
    var showValues: Bool = true
    var horizontal: Bool = false
    var barSpacing: CGFloat = 8

    @State private var animationProgress: CGFloat = 0

    private var maxValue: Double {
        bars.map(\.value).max() ?? 1
    }

    var body: some View {
        Group {
            if horizontal {
                horizontalBars
            } else {
                verticalBars
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animationProgress = 1.0
            }
        }
    }

    private var verticalBars: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let barWidth = (availableWidth - (CGFloat(bars.count - 1) * barSpacing)) / CGFloat(bars.count)

            HStack(alignment: .bottom, spacing: barSpacing) {
                ForEach(bars) { bar in
                    VStack(spacing: AppSpacing.xs) {
                        if showValues {
                            Text(bar.formattedValue)
                                .font(AppTypography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .opacity(animationProgress)
                        }

                        RoundedRectangle(cornerRadius: AppCornerRadius.xs)
                            .fill(bar.color ?? barColor)
                            .frame(
                                width: barWidth,
                                height: max(4, CGFloat(bar.value / maxValue) * (height - 40) * animationProgress)
                            )

                        Text(bar.label)
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
        }
        .frame(height: height)
    }

    private var horizontalBars: some View {
        VStack(spacing: barSpacing) {
            ForEach(bars) { bar in
                HStack(spacing: AppSpacing.sm) {
                    Text(bar.label)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)
                        .lineLimit(1)

                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: AppCornerRadius.xs)
                            .fill(bar.color ?? barColor)
                            .frame(
                                width: max(4, CGFloat(bar.value / maxValue) * geometry.size.width * animationProgress)
                            )
                    }
                    .frame(height: 20)

                    if showValues {
                        Text(bar.formattedValue)
                            .font(AppTypography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
    }
}

struct BarChartData: Identifiable {
    let id: UUID
    let label: String
    let value: Double
    var color: Color?

    var formattedValue: String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }

    init(id: UUID = UUID(), label: String, value: Double, color: Color? = nil) {
        self.id = id
        self.label = label
        self.value = value
        self.color = color
    }
}

// MARK: - Mini Sparkline

struct SparklineView: View {
    let values: [Double]
    var color: Color = AppColors.primary
    var height: CGFloat = 30

    @State private var animationProgress: CGFloat = 0

    private var maxValue: Double {
        values.max() ?? 1
    }

    private var minValue: Double {
        values.min() ?? 0
    }

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard values.count > 1 else { return }

                let stepX = geometry.size.width / CGFloat(values.count - 1)
                let range = maxValue - minValue
                let effectiveRange = range > 0 ? range : 1

                for (index, value) in values.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedY = CGFloat((value - minValue) / effectiveRange)
                    let y = geometry.size.height - (normalizedY * geometry.size.height * animationProgress)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animationProgress = 1.0
            }
        }
    }
}

// MARK: - Progress Ring

struct ProgressRingView: View {
    let progress: Double // 0.0 - 1.0
    var size: CGFloat = 60
    var lineWidth: CGFloat = 8
    var color: Color = AppColors.primary
    var backgroundColor: Color = Color.gray.opacity(0.2)
    var showPercentage: Bool = true

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(animatedProgress))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Percentage text
            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(size > 50 ? AppTypography.calloutEmphasized : AppTypography.captionEmphasized)
                    .foregroundColor(.primary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = min(1.0, max(0.0, progress))
            }
        }
    }
}

// MARK: - Previews

#Preview("Donut Chart") {
    DonutChartView(
        segments: [
            DonutSegment(label: "MTN MoMo", value: 7470000, percentage: 0.60, color: "FFCC00"),
            DonutSegment(label: "Airtel", value: 3735000, percentage: 0.30, color: "ED1C24"),
            DonutSegment(label: "Card", value: 1245000, percentage: 0.10, color: "007AFF")
        ],
        centerText: "UGX 12.4M",
        centerSubtext: "Total Revenue"
    )
    .padding()
}

#Preview("Line Chart") {
    LineChartView(
        dataPoints: [
            LineChartDataPoint(label: "Mon", value: 12),
            LineChartDataPoint(label: "Tue", value: 18),
            LineChartDataPoint(label: "Wed", value: 15),
            LineChartDataPoint(label: "Thu", value: 25),
            LineChartDataPoint(label: "Fri", value: 32),
            LineChartDataPoint(label: "Sat", value: 45),
            LineChartDataPoint(label: "Sun", value: 38)
        ]
    )
    .padding()
}

#Preview("Bar Chart") {
    BarChartView(
        bars: [
            BarChartData(label: "Early", value: 100, color: .green),
            BarChartData(label: "Regular", value: 180, color: .orange),
            BarChartData(label: "VIP", value: 52, color: .yellow),
            BarChartData(label: "VVIP", value: 10, color: .purple)
        ]
    )
    .padding()
}

#Preview("Progress Ring") {
    HStack(spacing: 24) {
        ProgressRingView(progress: 0.68, color: .green)
        ProgressRingView(progress: 0.45, color: .orange)
        ProgressRingView(progress: 0.92, color: .blue)
    }
    .padding()
}
