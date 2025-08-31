import ballerina/http;
import ballerina/time;
import ballerina/math;
import ballerina/log;
import ballerina/lang.'float as floats;

// Data Types
public type CostData record {
    string timestamp;
    string service;
    string region;
    float cost;
    int resourceCount;
    string instanceType?;
};

public type AnomalyAlert record {
    string id;
    string timestamp;
    string severity; // CRITICAL, WARNING, NORMAL
    string service;
    string region;
    float currentCost;
    float expectedCost;
    float percentageIncrease;
    string description;
    string recommendation;
    boolean isActive;
};

public type HealthScore record {
    int score; // 0-100
    string status;
    string description;
    AnomalyAlert[] activeAnomalies;
    float totalMonthlyCost;
    float projectedSavings;
};

public type CostTrend record {
    string service;
    float[] last7Days;
    float average;
    float trend; // positive/negative percentage
};

// Global variables for demo data
CostData[] historicalCostData = [];
AnomalyAlert[] activeAnomalies = [];

// Initialize service with mock data
function init() {
    log:printInfo("Initializing Cloud Cost Optimizer with mock data...");
    historicalCostData = generateMockData();
    log:printInfo("Mock data generated: " + historicalCostData.length().toString() + " records");
}

// Main HTTP service
service /api/v1 on new http:Listener(8080) {
    
    // CORS headers
    resource function options .*() returns http:Ok {
        http:Response res = new;
        res.setHeader("Access-Control-Allow-Origin", "*");
        res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        res.setHeader("Access-Control-Allow-Headers", "Content-Type");
        return http:OK;
    }

    // Get current anomalies
    resource function get anomalies() returns AnomalyAlert[]|error {
        http:Response res = new;
        res.setHeader("Access-Control-Allow-Origin", "*");
        
        AnomalyAlert[] anomalies = detectCostAnomalies(historicalCostData);
        activeAnomalies = anomalies;
        return anomalies;
    }

    // Get cost health score
    resource function get health() returns HealthScore|error {
        http:Response res = new;
        res.setHeader("Access-Control-Allow-Origin", "*");
        
        return calculateCostHealthScore();
    }

    // Get cost trends
    resource function get trends() returns CostTrend[]|error {
        http:Response res = new;
        res.setHeader("Access-Control-Allow-Origin", "*");
        
        return calculateCostTrends();
    }

    // Get all historical data (for dashboard)
    resource function get costs() returns CostData[]|error {
        http:Response res = new;
        res.setHeader("Access-Control-Allow-Origin", "*");
        
        return historicalCostData;
    }

    // Simulate cost spike for demo
    resource function post simulate/spike(http:Request req) returns json|error {
        http:Response res = new;
        res.setHeader("Access-Control-Allow-Origin", "*");
        
        // Add a cost spike to current data
        CostData spikeData = {
            timestamp: time:utcToString(time:utcNow()),
            service: "EC2",
            region: "us-east-1", 
            cost: 2500.0, // Large spike
            resourceCount: 25,
            instanceType: "t3.large"
        };
        
        historicalCostData.push(spikeData);
        
        return {
            "status": "success",
            "message": "Cost spike simulated successfully",
            "spikeAmount": 2500.0
        };
    }
}

// Core anomaly detection function
function detectCostAnomalies(CostData[] data) returns AnomalyAlert[] {
    AnomalyAlert[] anomalies = [];
    
    if (data.length() < 7) {
        return anomalies; // Need at least 7 days of data
    }
    
    // Group data by service and region
    map<CostData[]> serviceGroups = {};
    
    foreach CostData item in data {
        string key = item.service + "_" + item.region;
        if (serviceGroups.hasKey(key)) {
            CostData[] existing = serviceGroups.get(key);
            existing.push(item);
            serviceGroups[key] = existing;
        } else {
            serviceGroups[key] = [item];
        }
    }
    
    // Analyze each service group
    foreach string serviceKey in serviceGroups.keys() {
        CostData[] serviceData = serviceGroups.get(serviceKey);
        
        if (serviceData.length() >= 7) {
            AnomalyAlert? anomaly = detectServiceAnomaly(serviceData);
            if (anomaly is AnomalyAlert) {
                anomalies.push(anomaly);
            }
        }
    }
    
    return anomalies;
}

// Detect anomaly for a specific service
function detectServiceAnomaly(CostData[] serviceData) returns AnomalyAlert? {
    if (serviceData.length() < 7) {
        return ();
    }
    
    // Sort by timestamp (assume chronological order)
    CostData[] sortedData = serviceData.clone();
    
    // Get current (latest) cost
    CostData currentData = sortedData[sortedData.length() - 1];
    float currentCost = currentData.cost;
    
    // Calculate 7-day moving average (excluding current day)
    float sum = 0.0;
    int count = 0;
    int maxHistory = sortedData.length() - 1; // Exclude current day
    int startIndex = maxHistory > 7 ? maxHistory - 7 : 0;
    
    foreach int i in startIndex ..< maxHistory {
        sum += sortedData[i].cost;
        count += 1;
    }
    
    if (count == 0) {
        return ();
    }
    
    float averageCost = sum / <float>count;
    float percentageChange = ((currentCost - averageCost) / averageCost) * 100.0;
    
    // Determine if this is an anomaly
    string severity = "NORMAL";
    boolean isAnomaly = false;
    
    if (percentageChange > 200.0) {
        severity = "CRITICAL";
        isAnomaly = true;
    } else if (percentageChange > 50.0) {
        severity = "WARNING";
        isAnomaly = true;
    }
    
    if (!isAnomaly) {
        return ();
    }
    
    // Generate anomaly alert
    string description = generateAnomalyDescription(currentData, percentageChange, severity);
    string recommendation = generateRecommendation(currentData, percentageChange);
    
    AnomalyAlert anomaly = {
        id: currentData.service + "_" + currentData.region + "_" + currentData.timestamp,
        timestamp: currentData.timestamp,
        severity: severity,
        service: currentData.service,
        region: currentData.region,
        currentCost: currentCost,
        expectedCost: averageCost,
        percentageIncrease: percentageChange,
        description: description,
        recommendation: recommendation,
        isActive: true
    };
    
    return anomaly;
}

// Generate human-readable anomaly description
function generateAnomalyDescription(CostData data, float percentageChange, string severity) returns string {
    string intensifier = severity == "CRITICAL" ? "critically high" : "elevated";
    string resourceInfo = data.resourceCount.toString() + " resources";
    
    if (data.instanceType is string) {
        resourceInfo += " (" + <string>data.instanceType + ")";
    }
    
    return string`${data.service} costs in ${data.region} are ${intensifier} - ${floats:round(percentageChange)}% above normal baseline. Currently running ${resourceInfo}.`;
}

// Generate actionable recommendations
function generateRecommendation(CostData data, float percentageChange) returns string {
    if (percentageChange > 200.0) {
        return string`URGENT: Review ${data.service} instances in ${data.region}. Consider immediate scaling down or spot instance migration. Potential monthly impact: $${floats:round(data.cost * 30.0)}.`;
    } else if (percentageChange > 100.0) {
        return string`Review resource utilization for ${data.service} in ${data.region}. Consider right-sizing instances or implementing auto-scaling policies.`;
    } else {
        return string`Monitor ${data.service} usage in ${data.region}. Consider scheduled scaling or reserved instance optimization.`;
    }
}

// Calculate overall cost health score
function calculateCostHealthScore() returns HealthScore {
    AnomalyAlert[] currentAnomalies = detectCostAnomalies(historicalCostData);
    
    int baseScore = 100;
    
    // Deduct points for anomalies
    foreach AnomalyAlert anomaly in currentAnomalies {
        if (anomaly.severity == "CRITICAL") {
            baseScore -= 30;
        } else if (anomaly.severity == "WARNING") {
            baseScore -= 15;
        }
    }
    
    // Ensure score doesn't go below 0
    int finalScore = baseScore < 0 ? 0 : baseScore;
    
    string status = "HEALTHY";
    string description = "All systems operating within normal cost parameters";
    
    if (finalScore < 30) {
        status = "CRITICAL";
        description = "Multiple critical cost anomalies detected - immediate action required";
    } else if (finalScore < 60) {
        status = "WARNING"; 
        description = "Cost anomalies detected - review and optimization recommended";
    } else if (finalScore < 85) {
        status = "FAIR";
        description = "Minor cost increases detected - monitoring recommended";
    }
    
    // Calculate totals
    float totalMonthlyCost = calculateTotalMonthlyCost();
    float projectedSavings = calculateProjectedSavings(currentAnomalies);
    
    HealthScore health = {
        score: finalScore,
        status: status,
        description: description,
        activeAnomalies: currentAnomalies,
        totalMonthlyCost: totalMonthlyCost,
        projectedSavings: projectedSavings
    };
    
    return health;
}

// Calculate cost trends for different services
function calculateCostTrends() returns CostTrend[] {
    CostTrend[] trends = [];
    
    // Group by service
    map<float[]> serviceCosts = {};
    
    // Get last 7 days of data
    int dataLength = historicalCostData.length();
    int startIndex = dataLength > 7 ? dataLength - 7 : 0;
    
    foreach int i in startIndex ..< dataLength {
        CostData item = historicalCostData[i];
        if (serviceCosts.hasKey(item.service)) {
            float[] existing = serviceCosts.get(item.service);
            existing.push(item.cost);
            serviceCosts[item.service] = existing;
        } else {
            serviceCosts[item.service] = [item.cost];
        }
    }
    
    // Calculate trends
    foreach string service in serviceCosts.keys() {
        float[] costs = serviceCosts.get(service);
        float average = calculateAverage(costs);
        float trend = calculateTrendPercentage(costs);
        
        CostTrend serviceTrend = {
            service: service,
            last7Days: costs,
            average: average,
            trend: trend
        };
        
        trends.push(serviceTrend);
    }
    
    return trends;
}

// Helper function to calculate average
function calculateAverage(float[] values) returns float {
    if (values.length() == 0) {
        return 0.0;
    }
    
    float sum = 0.0;
    foreach float val in values {
        sum += val;
    }
    
    return sum / <float>values.length();
}

// Helper function to calculate trend percentage
function calculateTrendPercentage(float[] values) returns float {
    if (values.length() < 2) {
        return 0.0;
    }
    
    float firstValue = values[0];
    float lastValue = values[values.length() - 1];
    
    if (firstValue == 0.0) {
        return 0.0;
    }
    
    return ((lastValue - firstValue) / firstValue) * 100.0;
}

// Calculate total monthly cost projection
function calculateTotalMonthlyCost() returns float {
    if (historicalCostData.length() == 0) {
        return 0.0;
    }
    
    // Use last day's cost and project monthly
    CostData lastDay = historicalCostData[historicalCostData.length() - 1];
    return lastDay.cost * 30.0;
}

// Calculate projected savings from fixing anomalies
function calculateProjectedSavings(AnomalyAlert[] anomalies) returns float {
    float totalSavings = 0.0;
    
    foreach AnomalyAlert anomaly in anomalies {
        float excessCost = anomaly.currentCost - anomaly.expectedCost;
        totalSavings += excessCost * 30.0; // Monthly projection
    }
    
    return totalSavings;
}

// Generate realistic mock data for demo
function generateMockData() returns CostData[] {
    CostData[] data = [];
    string[] services = ["EC2", "S3", "RDS", "Lambda", "CloudFront"];
    string[] regions = ["us-east-1", "us-west-2", "eu-west-1"];
    
    // Generate 30 days of historical data
    foreach int day in 0 ..< 30 {
        foreach string service in services {
            foreach string region in regions {
                // Base cost varies by service
                float baseCost = getServiceBaseCost(service);
                
                // Add some random variation (±20%)
                float variation = (math:random() - 0.5) * 0.4;
                float dailyCost = baseCost * (1.0 + variation);
                
                // Add weekend effect (lower costs on weekends)
                if ((day % 7) == 0 || (day % 7) == 6) {
                    dailyCost *= 0.7;
                }
                
                // Create timestamp (days ago)
                time:Utc timestamp = time:utcAddSeconds(time:utcNow(), -(30-day) * 86400);
                
                CostData item = {
                    timestamp: time:utcToString(timestamp),
                    service: service,
                    region: region,
                    cost: dailyCost,
                    resourceCount: <int>(dailyCost / 10.0) + 1,
                    instanceType: service == "EC2" ? "t3.medium" : ()
                };
                
                data.push(item);
            }
        }
    }
    
    // Add some recent anomalies for demo
    addDemoAnomalies(data);
    
    return data;
}

// Get base cost for different services
function getServiceBaseCost(string service) returns float {
    if (service == "EC2") {
        return 150.0;
    } else if (service == "RDS") {
        return 80.0;
    } else if (service == "S3") {
        return 25.0;
    } else if (service == "Lambda") {
        return 15.0;
    } else if (service == "CloudFront") {
        return 30.0;
    }
    return 50.0;
}

// Add some demo anomalies to make the demo interesting
function addDemoAnomalies(CostData[] data) {
    // Add a recent EC2 spike
    time:Utc recentTime = time:utcAddSeconds(time:utcNow(), -3600); // 1 hour ago
    
    CostData anomaly1 = {
        timestamp: time:utcToString(recentTime),
        service: "EC2",
        region: "us-east-1",
        cost: 450.0, // 3x normal
        resourceCount: 45,
        instanceType: "t3.large"
    };
    
    // Add a moderate RDS increase
    CostData anomaly2 = {
        timestamp: time:utcToString(recentTime),
        service: "RDS", 
        region: "us-west-2",
        cost: 140.0, // 1.75x normal
        resourceCount: 14
    };
    
    data.push(anomaly1);
    data.push(anomaly2);
}