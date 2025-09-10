import Foundation
import os.log

/// Performance monitoring service to track response times and app performance
@MainActor
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: "com.astronova.app", category: "Performance")
    
    @Published private(set) var metrics: [String: PerformanceMetric] = [:]
    private var activeTimers: [String: Date] = [:]
    
    private init() {}
    
    /// Start timing an operation
    func startTimer(for operation: String) {
        activeTimers[operation] = Date()
        logger.debug("Started timer for: \(operation)")
    }
    
    /// End timing and record the metric
    func endTimer(for operation: String, threshold: TimeInterval = 0.4) {
        guard let startTime = activeTimers[operation] else {
            logger.warning("No timer found for operation: \(operation)")
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        activeTimers.removeValue(forKey: operation)
        
        let metric = PerformanceMetric(
            operation: operation,
            duration: duration,
            timestamp: Date(),
            exceededThreshold: duration > threshold
        )
        
        metrics[operation] = metric
        
        // Log performance
        if metric.exceededThreshold {
            logger.warning("⚠️ Performance threshold exceeded for \(operation): \(String(format: "%.3f", duration))s (threshold: \(threshold)s)")
        } else {
            logger.info("✓ \(operation) completed in \(String(format: "%.3f", duration))s")
        }
        
        // Haptic feedback for slow operations
        if metric.exceededThreshold && duration > 1.0 {
            HapticFeedbackService.shared.warning()
        }
    }
    
    /// Measure an async operation
    func measure<T>(
        _ operation: String,
        threshold: TimeInterval = 0.4,
        block: () async throws -> T
    ) async throws -> T {
        startTimer(for: operation)
        defer { endTimer(for: operation, threshold: threshold) }
        
        return try await block()
    }
    
    /// Get average duration for an operation type
    func averageDuration(for operation: String) -> TimeInterval? {
        guard let metric = metrics[operation] else { return nil }
        return metric.duration
    }
    
    /// Get all metrics exceeding threshold
    var slowOperations: [PerformanceMetric] {
        metrics.values.filter { $0.exceededThreshold }.sorted { $0.duration > $1.duration }
    }
    
    /// Clear all metrics
    func clearMetrics() {
        metrics.removeAll()
        activeTimers.removeAll()
    }
    
    /// Export metrics for analysis
    func exportMetrics() -> String {
        let sortedMetrics = metrics.values.sorted { $0.timestamp > $1.timestamp }
        
        var report = "Performance Report - \(Date())\n"
        report += "=====================================\n\n"
        
        report += "Summary:\n"
        report += "Total operations tracked: \(metrics.count)\n"
        report += "Slow operations (>400ms): \(slowOperations.count)\n\n"
        
        report += "Detailed Metrics:\n"
        for metric in sortedMetrics {
            let status = metric.exceededThreshold ? "⚠️ SLOW" : "✓ OK"
            report += "\(status) \(metric.operation): \(String(format: "%.3f", metric.duration))s\n"
        }
        
        return report
    }
}

// MARK: - Performance Metric Model

struct PerformanceMetric: Identifiable {
    let id = UUID()
    let operation: String
    let duration: TimeInterval
    let timestamp: Date
    let exceededThreshold: Bool
}

// MARK: - View Extension for Performance Tracking

extension View {
    /// Track performance of view appearance
    func trackPerformance(_ operation: String) -> some View {
        onAppear {
            PerformanceMonitor.shared.startTimer(for: "\(operation).appear")
        }
        .onDisappear {
            PerformanceMonitor.shared.endTimer(for: "\(operation).appear")
        }
    }
}

// MARK: - URLSession Extension for Network Performance

extension URLSession {
    /// Data task with automatic performance tracking
    func performanceTrackedDataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        let operation = request.url?.path ?? "network_request"
        
        PerformanceMonitor.shared.startTimer(for: operation)
        
        return dataTask(with: request) { data, response, error in
            PerformanceMonitor.shared.endTimer(for: operation)
            completionHandler(data, response, error)
        }
    }
}

// MARK: - Debug View for Performance Metrics

#if DEBUG
struct PerformanceDebugView: View {
    @ObservedObject private var monitor = PerformanceMonitor.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Summary") {
                    HStack {
                        Text("Total Operations")
                        Spacer()
                        Text("\(monitor.metrics.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Slow Operations")
                        Spacer()
                        Text("\(monitor.slowOperations.count)")
                            .foregroundColor(monitor.slowOperations.isEmpty ? .green : .orange)
                    }
                }
                
                Section("Recent Operations") {
                    ForEach(Array(monitor.metrics.values.sorted { $0.timestamp > $1.timestamp }.prefix(10))) { metric in
                        HStack {
                            Image(systemName: metric.exceededThreshold ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .foregroundColor(metric.exceededThreshold ? .orange : .green)
                            
                            VStack(alignment: .leading) {
                                Text(metric.operation)
                                    .font(.footnote)
                                Text(metric.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(String(format: "%.3fs", metric.duration))
                                .font(.caption.monospacedDigit())
                                .foregroundColor(metric.exceededThreshold ? .orange : .primary)
                        }
                    }
                }
            }
            .navigationTitle("Performance Monitor")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        monitor.clearMetrics()
                    }
                }
            }
        }
    }
}
#endif