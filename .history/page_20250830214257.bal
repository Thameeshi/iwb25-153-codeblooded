import ballerina/http;
import ballerina/time;
import ballerina/math;
import ballerina/log;

public type CostData record {
    string timestamp;
    string serviceType;
    string region;
    float cost;
    int resourceCount;
    string instanceType?;
};

public type AnomalyAlert record {
    string id;
    string timestamp;
    string severity;
    string serviceType;
    string region;
    float currentCost;
    float expectedCost;
    float percentageIncrease;
    string description;
    string recommendation;
    boolean isActive;
};

public type HealthScore record {
    int score;
    string status;
    string description;
    AnomalyAlert[] activeAnomalies;
    float totalMonthlyCost;
    float projectedSavings;
};

public type CostTrend record {
    string serviceType;
    float[] last7Days;
    float average;
    float trend;
};

CostData[] historicalCostData = [];
AnomalyAlert[] activeAnomalies = [];

function init() {
    historicalCostData = generateMockData();
    log:printInfo("Initialized with " + historicalCostData.length().toString() + " records");
}

service /api/v1 on new http:Listener(8081) {
    resource function options .*() returns http:Ok {
        http:Response res = new;
        res.setHeader("Access-Control-Allow-Origin", "*");
        res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        res.setHeader("Access-Control-Allow-Headers", "Content-Type");
        return http:OK;
    }

    resource function get anomalies(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setHeader("Access-Control-Allow-Origin", "*");
        AnomalyAlert[] anomalies = detectCostAnomalies(historicalCostData);
        res.setJsonPayload(anomalies);
        check caller->respond(res);
    }

    resource function get health(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setHeader("Access-Control-Allow-Origin", "*");
        HealthScore healthScore = calculateCostHealthScore();
        res.setJsonPayload(healthScore);
        check caller->respond(res);
    }

    resource function get trends(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setHeader("Access-Control-Allow-Origin", "*");
        CostTrend[] trends = calculateCostTrends();
        res.setJsonPayload(trends);
        check caller->respond(res);
    }

    resource function get costs(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setHeader("Access-Control-Allow-Origin", "*");
        res.setJsonPayload(historicalCostData);
        check caller->respond(res);
    }

    resource function post simulate/spike(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setHeader("Access-Control-Allow-Origin", "*");
        CostData spikeData = {
            timestamp: time:utcToString(time:utcNow()),
            serviceType: "EC2",
            region: "us-east-1", 
            cost: 2500.0,
            resourceCount: 25,
            instanceType: "t3.large"
        };
        historicalCostData.push(spikeData);
        json response = {"status": "success", "message": "Cost spike simulated", "spikeAmount": 2500.0};
        res.setJsonPayload(response);
        check caller->respond(res);
    }

    resource function get .(http:Caller caller, http:Request req) returns error? {
        string dashboardHtml = getDashboardHtml();
        http:Response resp = new();
        resp.setPayload(dashboardHtml);
        resp.setHeader("Content-Type", "text/html");
        check caller->respond(resp);
    }

    resource function get favicon\.ico(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.statusCode = 204;
        check caller->respond(res);
    }
}

function detectCostAnomalies(CostData[] data) returns AnomalyAlert[] {
    AnomalyAlert[] anomalies = [];
    if (data.length() < 7) return anomalies;
    
    map<CostData[]> serviceGroups = {};
    foreach CostData item in data {
        string key = item.serviceType + "_" + item.region;
        if (serviceGroups.hasKey(key)) {
            CostData[] existing = serviceGroups.get(key);
            existing.push(item);
            serviceGroups[key] = existing;
        } else {
            serviceGroups[key] = [item];
        }
    }
    
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

function detectServiceAnomaly(CostData[] serviceData) returns AnomalyAlert? {
    if (serviceData.length() < 7) return ();
    
    CostData[] sortedData = serviceData.clone();
    CostData currentData = sortedData[sortedData.length() - 1];
    float currentCost = currentData.cost;
    
    float sum = 0.0;
    int count = 0;
    int maxHistory = sortedData.length() - 1;
    int startIndex = maxHistory > 7 ? maxHistory - 7 : 0;
    
    foreach int i in startIndex ..< maxHistory {
        sum += sortedData[i].cost;
        count += 1;
    }
    
    if (count == 0) return ();
    
    float averageCost = sum / <float>count;
    float percentageChange = ((currentCost - averageCost) / averageCost) * 100.0;
    
    string severity = "NORMAL";
    boolean isAnomaly = false;
    
    if (percentageChange > 200.0) {
        severity = "CRITICAL";
        isAnomaly = true;
    } else if (percentageChange > 50.0) {
        severity = "WARNING";
        isAnomaly = true;
    }
    
    if (!isAnomaly) return ();
    
    string description = currentData.serviceType + " costs in " + currentData.region + " are " + 
                        (severity == "CRITICAL" ? "critically high" : "elevated") + " - " + 
                        math:round(percentageChange).toString() + "% above normal baseline.";
    
    string recommendation = percentageChange > 200.0 ? 
        "URGENT: Review instances immediately. Potential monthly impact: $" + math:round(currentCost * 30.0).toString() :
        "Review resource utilization and consider right-sizing instances.";
    
    return {
        id: currentData.serviceType + "_" + currentData.region + "_" + currentData.timestamp,
        timestamp: currentData.timestamp,
        severity: severity,
        serviceType: currentData.serviceType,
        region: currentData.region,
        currentCost: currentCost,
        expectedCost: averageCost,
        percentageIncrease: percentageChange,
        description: description,
        recommendation: recommendation,
        isActive: true
    };
}

function calculateCostHealthScore() returns HealthScore {
    AnomalyAlert[] currentAnomalies = detectCostAnomalies(historicalCostData);
    int baseScore = 100;
    
    foreach AnomalyAlert anomaly in currentAnomalies {
        baseScore -= anomaly.severity == "CRITICAL" ? 30 : 15;
    }
    
    int finalScore = baseScore < 0 ? 0 : baseScore;
    string status = finalScore < 30 ? "CRITICAL" : 
                   finalScore < 60 ? "WARNING" : 
                   finalScore < 85 ? "FAIR" : "HEALTHY";
    
    string description = finalScore < 30 ? "Multiple critical anomalies detected" :
                        finalScore < 60 ? "Cost anomalies detected" :
                        finalScore < 85 ? "Minor cost increases detected" :
                        "All systems operating normally";
    
    float totalMonthlyCost = historicalCostData.length() > 0 ? 
                            historicalCostData[historicalCostData.length() - 1].cost * 30.0 : 0.0;
    
    float projectedSavings = 0.0;
    foreach AnomalyAlert anomaly in currentAnomalies {
        projectedSavings += (anomaly.currentCost - anomaly.expectedCost) * 30.0;
    }
    
    return {
        score: finalScore,
        status: status,
        description: description,
        activeAnomalies: currentAnomalies,
        totalMonthlyCost: totalMonthlyCost,
        projectedSavings: projectedSavings
    };
}

function calculateCostTrends() returns CostTrend[] {
    CostTrend[] trends = [];
    map<float[]> serviceCosts = {};
    
    int dataLength = historicalCostData.length();
    int startIndex = dataLength > 7 ? dataLength - 7 : 0;
    
    foreach int i in startIndex ..< dataLength {
        CostData item = historicalCostData[i];
        if (serviceCosts.hasKey(item.serviceType)) {
            float[] existing = serviceCosts.get(item.serviceType);
            existing.push(item.cost);
            serviceCosts[item.serviceType] = existing;
        } else {
            serviceCosts[item.serviceType] = [item.cost];
        }
    }
    
    foreach string serviceType in serviceCosts.keys() {
        float[] costs = serviceCosts.get(serviceType);
        float sum = 0.0;
        foreach float val in costs { sum += val; }
        float average = costs.length() > 0 ? sum / <float>costs.length() : 0.0;
        
        float trend = 0.0;
        if (costs.length() >= 2) {
            float firstValue = costs[0];
            float lastValue = costs[costs.length() - 1];
            if (firstValue > 0.0) {
                trend = ((lastValue - firstValue) / firstValue) * 100.0;
            }
        }
        
        trends.push({
            serviceType: serviceType,
            last7Days: costs,
            average: average,
            trend: trend
        });
    }
    
    return trends;
}

function generateMockData() returns CostData[] {
    CostData[] data = [];
    string[] services = ["EC2", "S3", "RDS", "Lambda", "CloudFront"];
    string[] regions = ["us-east-1", "us-west-2", "eu-west-1"];
    
    foreach int day in 0 ..< 30 {
        foreach string serviceType in services {
            foreach string region in regions {
                float baseCost = serviceType == "EC2" ? 150.0 :
                               serviceType == "RDS" ? 80.0 :
                               serviceType == "S3" ? 25.0 :
                               serviceType == "Lambda" ? 15.0 : 30.0;
                
                float variation = (math:random() - 0.5) * 0.4;
                float dailyCost = baseCost * (1.0 + variation);
                
                if ((day % 7) == 0 || (day % 7) == 6) {
                    dailyCost *= 0.7;
                }
                
                time:Utc timestamp = time:utcAddSeconds(time:utcNow(), -(30-day) * 86400);
                
                data.push({
                    timestamp: time:utcToString(timestamp),
                    serviceType: serviceType,
                    region: region,
                    cost: dailyCost,
                    resourceCount: <int>(dailyCost / 10.0) + 1,
                    instanceType: serviceType == "EC2" ? "t3.medium" : ()
                });
            }
        }
    }
    
    // Add demo anomalies
    time:Utc recentTime = time:utcAddSeconds(time:utcNow(), -3600);
    data.push({
        timestamp: time:utcToString(recentTime),
        serviceType: "EC2",
        region: "us-east-1",
        cost: 450.0,
        resourceCount: 45,
        instanceType: "t3.large"
    });
    
    data.push({
        timestamp: time:utcToString(recentTime),
        serviceType: "RDS", 
        region: "us-west-2",
        cost: 140.0,
        resourceCount: 14
    });
    
    return data;
}

function getDashboardHtml() returns string {
    return string `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cloud Cost Anomaly Detection</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
        .dashboard { max-width: 1400px; margin: 0 auto; display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        .header { grid-column: 1 / -1; text-align: center; margin-bottom: 20px; }
        .header h1 { color: white; font-size: 2.2em; margin-bottom: 10px; }
        .header p { color: rgba(255,255,255,0.9); font-size: 1.1em; }
        .card { background: rgba(255,255,255,0.95); border-radius: 15px; padding: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.2); }
        .health-score { grid-column: 1 / -1; text-align: center; }
        .score-circle { width: 100px; height: 100px; margin: 0 auto 15px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 2em; font-weight: bold; color: white; }
        .score-healthy { background: linear-gradient(45deg, #4CAF50, #45a049); }
        .score-fair { background: linear-gradient(45deg, #ff9800, #f57c00); }
        .score-warning { background: linear-gradient(45deg, #ff5722, #d84315); }
        .score-critical { background: linear-gradient(45deg, #f44336, #c62828); }
        .anomaly-item { background: white; border-left: 4px solid #ff5722; padding: 12px; margin: 8px 0; border-radius: 6px; }
        .anomaly-critical { border-left-color: #f44336; }
        .anomaly-warning { border-left-color: #ff9800; }
        .severity-badge { padding: 3px 8px; border-radius: 12px; font-size: 0.75em; font-weight: bold; text-transform: uppercase; }
        .badge-critical { background: #f44336; color: white; }
        .badge-warning { background: #ff9800; color: white; }
        .chart-container { position: relative; height: 250px; margin: 15px 0; }
        .stats-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin: 15px 0; }
        .stat-item { background: linear-gradient(135deg, #667eea, #764ba2); color: white; padding: 15px; border-radius: 8px; text-align: center; }
        .stat-value { font-size: 1.5em; font-weight: bold; margin-bottom: 3px; }
        .stat-label { font-size: 0.8em; opacity: 0.9; }
        .demo-btn { background: linear-gradient(45deg, #ff6b6b, #ee5a24); color: white; border: none; padding: 12px 24px; border-radius: 20px; font-size: 1em; font-weight: bold; cursor: pointer; margin-top: 15px; }
        .connection-status { position: fixed; top: 15px; right: 15px; padding: 8px 15px; border-radius: 20px; font-size: 0.85em; font-weight: bold; }
        .status-connected { background: #4CAF50; color: white; }
        .status-disconnected { background: #f44336; color: white; }
        @media (max-width: 768px) { .dashboard { grid-template-columns: 1fr; } }
    </style>
</head>
<body>
    <div class="connection-status" id="connectionStatus">Connecting...</div>
    
    <div class="dashboard">
        <div class="header">
            <h1>Cloud Cost Anomaly Detector</h1>
            <p>Real-time monitoring and optimization</p>
        </div>

        <div class="card health-score">
            <h2>Cost Health Score</h2>
            <div id="healthScore">Loading...</div>
            <div class="stats-grid" id="healthStats"></div>
        </div>

        <div class="card">
            <h2>Active Anomalies</h2>
            <div id="anomalyList">Scanning...</div>
        </div>

        <div class="card">
            <h2>Cost Trends</h2>
            <div class="chart-container">
                <canvas id="trendsChart"></canvas>
            </div>
        </div>

        <div class="card">
            <h2>Real-time Monitoring</h2>
            <div id="realtimeStats">Initializing...</div>
            <div class="chart-container">
                <canvas id="realtimeChart"></canvas>
            </div>
        </div>

        <div style="grid-column: 1 / -1; text-align: center;">
            <button class="demo-btn" onclick="simulateSpike()">Simulate Cost Spike</button>
        </div>
    </div>

    <script>
        const API = 'http://localhost:8081/api/v1';
        let trendsChart, realtimeChart;

        document.addEventListener('DOMContentLoaded', function() {
            initDashboard();
            setInterval(refreshData, 30000);
        });

        async function initDashboard() {
            try {
                await Promise.all([loadHealth(), loadAnomalies(), loadTrends(), loadRealtime()]);
                updateStatus(true);
            } catch (error) {
                updateStatus(false);
            }
        }

        async function refreshData() {
            try {
                await Promise.all([loadHealth(), loadAnomalies(), loadTrends(), loadRealtime()]);
                updateStatus(true);
            } catch (error) {
                updateStatus(false);
            }
        }

        function updateStatus(connected) {
            const el = document.getElementById('connectionStatus');
            el.className = 'connection-status ' + (connected ? 'status-connected' : 'status-disconnected');
            el.textContent = connected ? 'Connected' : 'Disconnected';
        }

        async function loadHealth() {
            const response = await fetch(API + '/health');
            const health = await response.json();
            
            let scoreClass = health.score < 30 ? 'score-critical' :
                           health.score < 60 ? 'score-warning' :
                           health.score < 85 ? 'score-fair' : 'score-healthy';
            
            document.getElementById('healthScore').innerHTML = 
                '<div class="score-circle ' + scoreClass + '">' + health.score + '</div>' +
                '<h3>' + health.status + '</h3><p>' + health.description + '</p>';
            
            document.getElementById('healthStats').innerHTML = 
                '<div class="stat-item"><div class="stat-value">$' + Math.round(health.totalMonthlyCost) + '</div><div class="stat-label">Monthly Cost</div></div>' +
                '<div class="stat-item"><div class="stat-value">$' + Math.round(health.projectedSavings) + '</div><div class="stat-label">Potential Savings</div></div>' +
                '<div class="stat-item"><div class="stat-value">' + health.activeAnomalies.length + '</div><div class="stat-label">Active Alerts</div></div>';
        }

        async function loadAnomalies() {
            const response = await fetch(API + '/anomalies');
            const anomalies = await response.json();
            
            if (anomalies.length === 0) {
                document.getElementById('anomalyList').innerHTML = '<div style="text-align: center; color: #4CAF50; padding: 20px;">No anomalies detected</div>';
                return;
            }

            let html = '';
            anomalies.forEach(anomaly => {
                html += '<div class="anomaly-item anomaly-' + anomaly.severity.toLowerCase() + '">';
                html += '<div style="display: flex; justify-content: space-between; margin-bottom: 8px;">';
                html += '<strong>' + anomaly.serviceType + ' - ' + anomaly.region + '</strong>';
                html += '<span class="severity-badge badge-' + anomaly.severity.toLowerCase() + '">' + anomaly.severity + '</span>';
                html += '</div>';
                html += '<p>' + anomaly.description + '</p>';
                html += '<p><strong>Recommendation:</strong> ' + anomaly.recommendation + '</p>';
                html += '</div>';
            });

            document.getElementById('anomalyList').innerHTML = html;
        }

        async function loadTrends() {
            const response = await fetch(API + '/trends');
            const trends = await response.json();
            
            const ctx = document.getElementById('trendsChart').getContext('2d');
            if (trendsChart) trendsChart.destroy();

            trendsChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: ['7d ago', '6d ago', '5d ago', '4d ago', '3d ago', '2d ago', 'Yesterday'],
                    datasets: trends.map((trend, i) => ({
                        label: trend.serviceType,
                        data: trend.last7Days,
                        borderColor: ['#4CAF50', '#2196F3', '#FF9800', '#9C27B0', '#F44336'][i % 5],
                        tension: 0.4
                    }))
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: { y: { beginAtZero: true } }
                }
            });
        }

        async function loadRealtime() {
            const response = await fetch(API + '/costs');
            const costs = await response.json();
            
            const latest = costs.slice(-5);
            const total = latest.reduce((sum, item) => sum + item.cost, 0);
            const avg = total / latest.length;
            
            document.getElementById('realtimeStats').innerHTML = 
                '<div class="stats-grid">' +
                '<div class="stat-item"><div class="stat-value">' + latest.length + '</div><div class="stat-label">Services</div></div>' +
                '<div class="stat-item"><div class="stat-value">$' + Math.round(avg) + '</div><div class="stat-label">Avg Cost</div></div>' +
                '<div class="stat-item"><div class="stat-value">$' + Math.round(total) + '</div><div class="stat-label">Total</div></div>' +
                '</div>';

            const ctx = document.getElementById('realtimeChart').getContext('2d');
            if (realtimeChart) realtimeChart.destroy();

            const chartData = costs.slice(-10);
            realtimeChart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: chartData.map(item => new Date(item.timestamp).toLocaleTimeString()),
                    datasets: [{
                        label: 'Cost',
                        data: chartData.map(item => item.cost),
                        backgroundColor: chartData.map(item => item.cost > 200 ? '#f44336' : item.cost > 100 ? '#ff9800' : '#4CAF50')
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: { y: { beginAtZero: true } }
                }
            });
        }

        async function simulateSpike() {
            try {
                document.querySelector('.demo-btn').textContent = 'Simulating...';
                await fetch(API + '/simulate/spike', { method: 'POST' });
                alert('Cost spike simulated! Refreshing...');
                await refreshData();
            } catch (error) {
                alert('Failed to simulate spike');
            } finally {
                document.querySelector('.demo-btn').textContent = 'Simulate Cost Spike';
            }
        }
    </script>
</body>
</html>`;
}