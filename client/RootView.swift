// ... earlier code ...

// Find your initializer:
// init(quotaManager: OracleQuotaManager = .shared) {

// Change to:
@MainActor
init(quotaManager: OracleQuotaManager = .shared) {

// ... rest of the file ...
