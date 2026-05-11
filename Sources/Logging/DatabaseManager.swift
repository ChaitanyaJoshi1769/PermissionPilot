import Foundation
import SQLite3

/// Manages SQLite database for audit logging
actor DatabaseManager {
    // MARK: - Paths

    private let dbPath: String = {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = paths[0].appendingPathComponent("PermissionPilot")
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent("audit.db").path
    }()

    private var database: OpaquePointer?

    // MARK: - Initialization

    init() {
        Task {
            await openDatabase()
            await createSchema()
        }
    }

    deinit {
        sqlite3_close(database)
    }

    // MARK: - Public API

    func logEvent(_ event: AuditEvent) async {
        let sql = """
        INSERT INTO automation_events (
            id, timestamp, app_bundle_id, app_name, dialog_title, dialog_text,
            button_label, action_taken, trust_score, confidence, execution_time_ms,
            policy_rule_id, detection_method
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """

        await executeUpdate(sql, parameters: [
            event.id.uuidString,
            Int64(event.timestamp.timeIntervalSince1970),
            event.appBundleID,
            event.appName,
            event.dialogTitle,
            event.dialogText,
            event.buttonLabel,
            event.actionTaken,
            event.trustScore,
            event.confidence,
            event.executionTimeMs,
            event.policyRuleID?.uuidString ?? "",
            event.detectionMethod,
        ])
    }

    func getRecentEvents(limit: Int = 50) async -> [AuditEvent] {
        let sql = """
        SELECT * FROM automation_events
        ORDER BY timestamp DESC
        LIMIT ?
        """

        return await executeQuery(sql, parameters: [limit])
    }

    func getEventsForApp(_ bundleID: String) async -> [AuditEvent] {
        let sql = """
        SELECT * FROM automation_events
        WHERE app_bundle_id = ?
        ORDER BY timestamp DESC
        """

        return await executeQuery(sql, parameters: [bundleID])
    }

    func deleteOldEvents(olderThan days: Int) async {
        let timestamp = Int64(Date().addingTimeInterval(-TimeInterval(days * 24 * 3600)).timeIntervalSince1970)
        let sql = "DELETE FROM automation_events WHERE timestamp < ?"
        await executeUpdate(sql, parameters: [timestamp])
    }

    func getStatistics() async -> AutomationStatistics {
        let totalSql = "SELECT COUNT(*) as count FROM automation_events"
        let automatedSql = "SELECT COUNT(*) as count FROM automation_events WHERE action_taken = 'CLICKED'"
        let promptedSql = "SELECT COUNT(*) as count FROM automation_events WHERE action_taken = 'ASKED'"
        let blockedSql = "SELECT COUNT(*) as count FROM automation_events WHERE action_taken = 'BLOCKED'"
        let confidenceSql = "SELECT AVG(confidence) as avg FROM automation_events"
        let trustSql = "SELECT AVG(trust_score) as avg FROM automation_events"
        let timeSql = "SELECT AVG(execution_time_ms) as avg FROM automation_events"

        let total = await querySingleInt(totalSql)
        let automated = await querySingleInt(automatedSql)
        let prompted = await querySingleInt(promptedSql)
        let blocked = await querySingleInt(blockedSql)
        let avgConfidence = await querySingleDouble(confidenceSql)
        let avgTrust = await querySingleDouble(trustSql)
        let avgTime = await querySingleInt(timeSql)

        let successRate = total > 0 ? Double(automated) / Double(total) * 100 : 0

        return AutomationStatistics(
            totalDialogsDetected: total,
            totalDialogsAutomated: automated,
            totalUserPrompts: prompted,
            totalBlocked: blocked,
            averageConfidence: avgConfidence,
            averageTrustScore: avgTrust,
            avgExecutionTimeMs: avgTime,
            lastActivityDate: Date(),
            mostCommonApp: await getMostCommonApp(),
            successRate: successRate
        )
    }

    // MARK: - Private Implementation

    private func openDatabase() async {
        let result = sqlite3_open(dbPath, &database)
        if result != SQLITE_OK {
            Logger.error("Failed to open database at \(dbPath)")
        }
    }

    private func createSchema() async {
        let schema = """
        CREATE TABLE IF NOT EXISTS automation_events (
            id TEXT PRIMARY KEY,
            timestamp INTEGER NOT NULL,
            app_bundle_id TEXT NOT NULL,
            app_name TEXT NOT NULL,
            dialog_title TEXT,
            dialog_text TEXT,
            button_label TEXT,
            action_taken TEXT,
            trust_score REAL,
            confidence REAL,
            execution_time_ms INTEGER,
            policy_rule_id TEXT,
            detection_method TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS trust_decisions (
            id TEXT PRIMARY KEY,
            app_bundle_id TEXT UNIQUE NOT NULL,
            app_name TEXT,
            first_seen INTEGER,
            last_seen INTEGER,
            approval_count INTEGER DEFAULT 0,
            rejection_count INTEGER DEFAULT 0,
            user_override TEXT
        );

        CREATE TABLE IF NOT EXISTS policies (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            pattern TEXT,
            action TEXT,
            enabled BOOLEAN DEFAULT 1,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX IF NOT EXISTS idx_timestamp ON automation_events(timestamp);
        CREATE INDEX IF NOT EXISTS idx_app_bundle_id ON automation_events(app_bundle_id);
        """

        for statement in schema.split(separator: ";") {
            var errorMessage: UnsafeMutablePointer<CChar>?
            let result = sqlite3_exec(database, String(statement), nil, nil, &errorMessage)
            if result != SQLITE_OK {
                Logger.error("Schema creation error: \(errorMessage.map(String.init) ?? "unknown")")
            }
        }
    }

    private func executeUpdate(_ sql: String, parameters: [Any]) async {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK {
            for (index, param) in parameters.enumerated() {
                bindParameter(statement, index: Int32(index + 1), value: param)
            }
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    private func executeQuery(_ sql: String, parameters: [Any]) async -> [AuditEvent] {
        var statement: OpaquePointer?
        var events: [AuditEvent] = []

        if sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK {
            for (index, param) in parameters.enumerated() {
                bindParameter(statement, index: Int32(index + 1), value: param)
            }

            while sqlite3_step(statement) == SQLITE_ROW {
                if let event = parseAuditEvent(statement) {
                    events.append(event)
                }
            }
        }
        sqlite3_finalize(statement)
        return events
    }

    private func querySingleInt(_ sql: String) async -> Int {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let value = sqlite3_column_int(statement, 0)
                sqlite3_finalize(statement)
                return Int(value)
            }
        }
        sqlite3_finalize(statement)
        return 0
    }

    private func querySingleDouble(_ sql: String) async -> Double {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let value = sqlite3_column_double(statement, 0)
                sqlite3_finalize(statement)
                return value
            }
        }
        sqlite3_finalize(statement)
        return 0
    }

    private func getMostCommonApp() async -> String? {
        let sql = """
        SELECT app_name FROM automation_events
        GROUP BY app_bundle_id
        ORDER BY COUNT(*) DESC
        LIMIT 1
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let name = String(cString: sqlite3_column_text(statement, 0))
                sqlite3_finalize(statement)
                return name
            }
        }
        sqlite3_finalize(statement)
        return nil
    }

    private func bindParameter(_ statement: OpaquePointer?, index: Int32, value: Any) {
        if let str = value as? String {
            sqlite3_bind_text(statement, index, str, -1, SQLITE_TRANSIENT)
        } else if let int = value as? Int {
            sqlite3_bind_int64(statement, index, Int64(int))
        } else if let int64 = value as? Int64 {
            sqlite3_bind_int64(statement, index, int64)
        } else if let double = value as? Double {
            sqlite3_bind_double(statement, index, double)
        }
    }

    private func parseAuditEvent(_ statement: OpaquePointer?) -> AuditEvent? {
        guard statement != nil else { return nil }

        let id = UUID(uuidString: String(cString: sqlite3_column_text(statement, 0))) ?? UUID()
        let timestamp = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 1)))
        let appBundleID = String(cString: sqlite3_column_text(statement, 2))
        let appName = String(cString: sqlite3_column_text(statement, 3))
        let dialogTitle = String(cString: sqlite3_column_text(statement, 4))
        let dialogText = String(cString: sqlite3_column_text(statement, 5))
        let buttonLabel = String(cString: sqlite3_column_text(statement, 6))
        let actionTaken = String(cString: sqlite3_column_text(statement, 7))
        let trustScore = Double(sqlite3_column_double(statement, 8))
        let confidence = Double(sqlite3_column_double(statement, 9))
        let executionTimeMs = Int(sqlite3_column_int(statement, 10))
        let detectionMethod = String(cString: sqlite3_column_text(statement, 12))

        return AuditEvent(
            id: id,
            timestamp: timestamp,
            appBundleID: appBundleID,
            appName: appName,
            dialogTitle: dialogTitle,
            dialogText: dialogText,
            buttonLabel: buttonLabel,
            actionTaken: actionTaken,
            trustScore: trustScore,
            confidence: confidence,
            executionTimeMs: executionTimeMs,
            policyRuleID: nil,
            detectionMethod: detectionMethod
        )
    }
}
