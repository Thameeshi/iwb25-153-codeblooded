import ballerina/http;
import ballerina/time;
import ballerina/math;
import ballerina/log;
import ballerina/lang.'float as floats;

// Data Types for Anomaly Detection System
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
    log:printInfo("Initializing Cloud Cost Anomaly Detector with mock data...");
    historicalCostData = generateMockData();
    log:printInfo("Mock data generated: " + historicalCostData.length().toString() + " records");
}

// Main HTTP service for Anomaly Detection
service /api/v1 on new http:Listener(8081) {
    
    // CORS headers for all requests
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

    // Serve the anomaly detection dashboard
    resource function get .() returns http:Response|error {
        string dashboardHtml = getDashboardHtml();
        http:Response resp = new();
        resp.setPayload(dashboardHtml);
        resp.setHeader("Content-Type", "text/html");
        return resp;
    }

    // Handle favicon requests
    resource function get favicon\.ico() returns http:Response {
        http:Response res = new;
        res.statusCode = 204;
        return res;
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

// Get embedded dashboard HTML
function getDashboardHtml() returns string {
    return string `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI-Powered Cloud Cost Anomaly Detection</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; color: #333; }
        .dashboard { max-width: 1400px; margin: 0 auto; display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .header { grid-column: 1 / -1; text-align: center; margin-bottom: 30px; }
        .header h1 { color: white; font-size: 2.5em; margin-bottom: 10px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
        .header p { color: rgba(255,255,255,0.9); font-size: 1.2em; }
        .card { background: rgba(255,255,255,0.95); border-radius: 15px; padding: 25px; box-shadow: 0 10px 30px rgba(0,0,0,0.2); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.2); transition: transform 0.3s ease, box-shadow 0.3s ease; }
        .card:hover { transform: translateY(-5px); box-shadow: 0 15px 40px rgba(0,0,0,0.3); }
        .health-score { grid-column: 1 / -1; text-align: center; }
        .score-circle { width: 120px; height: 120px; margin: 0 auto 20px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 2.5em; font-weight: bold; color: white; text-shadow: 1px 1px 2px rgba(0,0,0,0.5); animation: pulse 2s infinite; }
        .score-healthy { background: linear-gradient(45deg, #4CAF50, #45a049); }
        .score-fair { background: linear-gradient(45deg, #ff9800, #f57c00); }
        .score-warning { background: linear-gradient(45deg, #ff5722, #d84315); }
        .score-critical { background: linear-gradient(45deg, #f44336, #c62828); }
        @keyframes pulse { 0% { box-shadow: 0 0 0 0 rgba(255,255,255,0.4); } 70% { box-shadow: 0 0 0 20px rgba(255,255,255,0); } 100% { box-shadow: 0 0 0 0 rgba(255,255,255,0); } }
        .anomaly-item { background: white; border-left: 5px solid #ff5722; padding: 15px; margin: 10px 0; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); transition: all 0.3s ease; }
        .anomaly-item:hover { transform: translateX(10px); box-shadow: 0 4px 20px rgba(0,0,0,0.15); }
        .anomaly-critical { border-left-color: #f44336; background: linear-gradient(90deg, rgba(244,67,54,0.1), white); }
        .anomaly-warning { border-left-color: #ff9800; background: linear-gradient(90deg, rgba(255,152,0,0.1), white); }
        .anomaly-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
        .severity-badge { padding: 4px 12px; border-radius: 20px; font-size: 0.8em; font-weight: bold; text-transform: uppercase; }
        .badge-critical { background: #f44336; color: white; }
        .badge-warning { background: #ff9800; color: white; }
        .badge-normal { background: #4CAF50; color: white; }
        .cost-increase { font-size: 1.5em; font-weight: bold; color: #d32f2f; }
        .chart-container { position: relative; height: 300px; margin: 20px 0; }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; margin: 20px 0; }
        .stat-item { background: linear-gradient(135deg, #667eea, #764ba2); color: white; padding: 20px; border-radius: 10px; text-align: center; }
        .stat-value { font-size: 2em; font-weight: bold; margin-bottom: 5px; }
        .stat-label { font-size: 0.9em; opacity: 0.9; }
        .loading { text-align: center; padding: 50px; font-size: 1.2em; color: #666; }
        .loading::after { content: "..."; animation: dots 1.5s steps(5, end) infinite; }
        @keyframes dots { 0%, 20% { color: rgba(0,0,0,0); text-shadow: .25em 0 0 rgba(0,0,0,0), .5em 0 0 rgba(0,0,0,0); } 40% { color: black; text-shadow: .25em 0 0 rgba(0,0,0,0), .5em 0 0 rgba(0,0,0,0); } 60% { text-shadow: .25em 0 0 black, .5em 0 0 rgba(0,0,0,0); } 80%, 100% { text-shadow: .25em 0 0 black, .5em 0 0 black; } }
        .demo-controls { grid-column: 1 / -1; text-align: center; margin-top: 20px; }
        .demo-btn { background: linear-gradient(45deg, #ff6b6b, #ee5a24); color: white; border: none; padding: 15px 30px; border-radius: 25px; font-size: 1.1em; font-weight: bold; cursor: pointer; transition: all 0.3s ease; box-shadow: 0 4px 15px rgba(0,0,0,0.2); }
        .demo-btn:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(0,0,0,0.3); }
        .demo-btn:active { transform: translateY(0); }
        .connection-status { position: fixed; top: 20px; right: 20px; padding: 10px 20px; border-radius: 25px; font-size: 0.9em; font-weight: bold; }
        .status-connected { background: #4CAF50; color: white; }
        .status-disconnected { background: #f44336; color: white; }
        @media (max-width: 768px) { .dashboard { grid-template-columns: 1fr; } .stats-grid { grid-template-columns: repeat(2, 1fr); } }
    </style>
</head>
<body>
    <div class="connection-status" id="connectionStatus">🔴 Connecting...</div>
    
    <div class="dashboard">
        <div class="header">
            <h1>🚀 AI-Powered Cloud Cost Monitor</h1>
            <p>Real-time anomaly detection and cost optimization</p>
        </div>

        <div class="card health-score">
            <h2>Overall Cost Health</h2>
            <div id="healthScore" class="loading">Loading health data</div>
            <div id="healthDetails"></div>
            <div class="stats-grid" id="healthStats"></div>
        </div>

        <div class="card">
            <h2>🚨 Active Anomalies</h2>
            <div id="anomalyList" class="loading">Scanning for anomalies</div>
        </div>

        <div class="card">
            <h2>📈 Cost Trends (Last 7 Days)</h2>
            <div class="chart-container">
                <canvas id="trendsChart"></canvas>
            </div>
        </div>

        <div class="card">
            <h2>⚡ Real-time Monitoring</h2>
            <div id="realtimeStats" class="loading">Initializing monitors</div>
            <div class="chart-container">
                <canvas id="realtimeChart"></canvas>
            </div>
        </div>

        <div class="demo-controls">
            <button class="demo-btn" onclick="simulateCostSpike()">💥 Simulate Cost Spike (Demo)</button>
        </div>
    </div>

    <script>
        const API_BASE = 'http://localhost:8081/api/v1';
        let trendsChart, realtimeChart;

        document.addEventListener('DOMContentLoaded', function() {
            initDashboard();
            setInterval(refreshData, 30000);
        });

        async function initDashboard() {
            try {
                await Promise.all([loadHealthScore(), loadAnomalies(), loadTrends(), loadRealtimeData()]);
                updateConnectionStatus(true);
            } catch (error) {
                console.error('Failed to initialize dashboard:', error);
                updateConnectionStatus(false);
                showError('Failed to connect to backend service. Make sure Ballerina service is running on port 8081.');
            }
        }

        function updateConnectionStatus(connected) {
            const statusElement = document.getElementById('connectionStatus');
            if (connected) {
                statusElement.className = 'connection-status status-connected';
                statusElement.textContent = '🟢 Connected';
            } else {
                statusElement.className = 'connection-status status-disconnected';
                statusElement.textContent = '🔴 Disconnected';
            }
        }

        async function refreshData() {
            try {
                await Promise.all([loadHealthScore(), loadAnomalies(), loadTrends(), loadRealtimeData()]);
                updateConnectionStatus(true);
            } catch (error) {
                console.error('Failed to refresh data:', error);
                updateConnectionStatus(false);
            }
        }

        async function loadHealthScore() {
            try {
                const response = await fetch(API_BASE + '/health');
                const health = await response.json();
                displayHealthScore(health);
            } catch (error) {
                console.error('Error loading health score:', error);
                document.getElementById('healthScore').innerHTML = '<div style="color: red;">❌ Connection Error</div>';
            }
        }

        function displayHealthScore(health) {
            const scoreElement = document.getElementById('healthScore');
            const statsElement = document.getElementById('healthStats');

            let scoreClass = 'score-healthy';
            if (health.score < 30) scoreClass = 'score-critical';
            else if (health.score < 60) scoreClass = 'score-warning';
            else if (health.score < 85) scoreClass = 'score-fair';

            scoreElement.innerHTML = '<div class="score-circle ' + scoreClass + '">' + health.score + '</div><h3>Status: ' + health.status + '</h3><p>' + health.description + '</p>';

            statsElement.innerHTML = '<div class="stat-item"><div class="stat-value">$' + Math.round(health.totalMonthlyCost) + '</div><div class="stat-label">Monthly Cost</div></div><div class="stat-item"><div class="stat-value">$' + Math.round(health.projectedSavings) + '</div><div class="stat-label">Potential Savings</div></div><div class="stat-item"><div class="stat-value">' + health.activeAnomalies.length + '</div><div class="stat-label">Active Alerts</div></div><div class="stat-item"><div class="stat-value">' + health.score + '%</div><div class="stat-label">Health Score</div></div>';
        }

        async function loadAnomalies() {
            try {
                const response = await fetch(API_BASE + '/anomalies');
                const anomalies = await response.json();
                displayAnomalies(anomalies);
            } catch (error) {
                console.error('Error loading anomalies:', error);
                document.getElementById('anomalyList').innerHTML = '<div style="color: red;">❌ Failed to load anomalies</div>';
            }
        }

        function displayAnomalies(anomalies) {
            const listElement = document.getElementById('anomalyList');
            
            if (anomalies.length === 0) {
                listElement.innerHTML = '<div style="text-align: center; color: #4CAF50; font-size: 1.2em; padding: 30px;">✅ No anomalies detected - All systems healthy!</div>';
                return;
            }

            let html = '';
            anomalies.forEach(anomaly => {
                const severityClass = 'anomaly-' + anomaly.severity.toLowerCase();
                const badgeClass = 'badge-' + anomaly.severity.toLowerCase();
                
                html += '<div class="anomaly-item ' + severityClass + '"><div class="anomaly-header"><strong>' + anomaly.service + ' - ' + anomaly.region + '</strong><span class="severity-badge ' + badgeClass + '">' + anomaly.severity + '</span></div><div class="cost-increase">+' + Math.round(anomaly.percentageIncrease) + '%</div><p style="margin: 10px 0;">' + anomaly.description + '</p><div style="font-size: 0.9em; color: #666;"><strong>Current:</strong>  + Math.round(anomaly.currentCost) + ' | <strong>Expected:</strong>  + Math.round(anomaly.expectedCost) + '</div><div style="margin-top: 10px; padding: 10px; background: rgba(0,0,0,0.05); border-radius: 5px; font-size: 0.9em;">💡 <strong>Recommendation:</strong> ' + anomaly.recommendation + '</div></div>';
            });
            
            listElement.innerHTML = html;
        }

        async function loadTrends() {
            try {
                const response = await fetch(API_BASE + '/trends');
                const trends = await response.json();
                displayTrends(trends);
            } catch (error) {
                console.error('Error loading trends:', error);
            }
        }

        function displayTrends(trends) {
            const ctx = document.getElementById('trendsChart').getContext('2d');
            
            if (trendsChart) {
                trendsChart.destroy();
            }

            const datasets = trends.map((trend, index) => {
                const colors = ['#ff6b6b', '#4ecdc4', '#45b7d1', '#96ceb4', '#ffeaa7'];
                return {
                    label: trend.service,
                    data: trend.last7Days,
                    borderColor: colors[index % colors.length],
                    backgroundColor: colors[index % colors.length] + '20',
                    tension: 0.4,
                    fill: true
                };
            });

            trendsChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: ['6 days ago', '5 days ago', '4 days ago', '3 days ago', '2 days ago', 'Yesterday', 'Today'],
                    datasets: datasets
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'top',
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Cost ($)'
                            }
                        }
                    }
                }
            });
        }

        async function loadRealtimeData() {
            try {
                const response = await fetch(API_BASE + '/costs');
                const costs = await response.json();
                displayRealtimeData(costs);
            } catch (error) {
                console.error('Error loading realtime data:', error);
                document.getElementById('realtimeStats').innerHTML = '<div style="color: red;">❌ Failed to load realtime data</div>';
            }
        }

        function displayRealtimeData(costs) {
            const statsElement = document.getElementById('realtimeStats');
            
            const totalCost = costs.reduce((sum, cost) => sum + cost.cost, 0);
            const avgCost = totalCost / costs.length;
            const maxCost = Math.max(...costs.map(c => c.cost));
            const services = [...new Set(costs.map(c => c.service))].length;

            statsElement.innerHTML = '<div class="stats-grid"><div class="stat-item"><div class="stat-value">' + costs.length + '</div><div class="stat-label">Data Points</div></div><div class="stat-item"><div class="stat-value"> + Math.round(avgCost) + '</div><div class="stat-label">Avg Daily Cost</div></div><div class="stat-item"><div class="stat-value"> + Math.round(maxCost) + '</div><div class="stat-label">Peak Cost</div></div><div class="stat-item"><div class="stat-value">' + services + '</div><div class="stat-label">Services</div></div></div>';

            const ctx = document.getElementById('realtimeChart').getContext('2d');
            
            if (realtimeChart) {
                realtimeChart.destroy();
            }

            const recentCosts = costs.slice(-20).map(cost => cost.cost);
            const labels = costs.slice(-20).map((cost, index) => 'Point ' + (index + 1));

            realtimeChart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: labels,
                    datasets: [{
                        label: 'Cost',
                        data: recentCosts,
                        backgroundColor: 'rgba(54, 162, 235, 0.8)',
                        borderColor: 'rgba(54, 162, 235, 1)',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Cost ($)'
                            }
                        }
                    }
                }
            });
        }

        async function simulateCostSpike() {
            try {
                const response = await fetch(API_BASE + '/simulate/spike', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    }
                });
                
                const result = await response.json();
                
                if (result.status === 'success') {
                    alert('Cost spike simulated! Watch the anomaly alerts update...');
                    setTimeout(() => {
                        refreshData();
                    }, 2000);
                }
            } catch (error) {
                console.error('Error simulating cost spike:', error);
                alert('Failed to simulate cost spike. Make sure the backend service is running.');
            }
        }

        function showError(message) {
            const dashboard = document.querySelector('.dashboard');
            dashboard.innerHTML = '<div class="card" style="grid-column: 1 / -1; text-align: center; color: red;"><h2>Connection Error</h2><p>' + message + '</p><p style="margin-top: 20px;">Please ensure:</p><ul style="text-align: left; margin: 20px auto; max-width: 400px;"><li>Ballerina service is running on port 8081</li><li>CORS is properly configured</li><li>No firewall blocking the connection</li></ul><button class="demo-btn" onclick="location.reload()">Retry Connection</button></div>';
        }
    </script>
</body>
</html>`;
}