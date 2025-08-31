import ballerina/http;
import ballerina/time;
import ballerina/math;
import ballerina/log;

// ==== Data Models ====
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

// ==== State ====
CostData[] historicalCostData = [];
AnomalyAlert[] activeAnomalies = [];

// ==== Init ====
function init() {
    historicalCostData = generateMockData();
    log:printInfo("Initialized with " + historicalCostData.length().toString() + " records");
}

// ==== Service ====
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
        json response = { "status": "success", "message": "Cost spike simulated", "spikeAmount": 2500.0 };
        res.setJsonPayload(response);
        check caller->respond(res);
    }

    // Dashboard page
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

// ==== Anomaly Detection ====
function detectCostAnomalies(CostData[] data) returns AnomalyAlert[] {
    AnomalyAlert[] anomalies = [];
    if (data.length() < 7) return anomalies;

    map<CostData[]> serviceGroups = {};
    foreach CostData item in data {
        string key = item.serviceType + "_" + item.region;
        if serviceGroups.hasKey(key) {
            CostData[] existing = serviceGroups[key];
            existing.push(item);
            serviceGroups[key] = existing;
        } else {
            serviceGroups[key] = [item];
        }
    }

    foreach string serviceKey in serviceGroups.keys() {
        CostData[] serviceData = serviceGroups[serviceKey];
        if (serviceData.length() >= 7) {
            AnomalyAlert? anomaly = detectServiceAnomaly(serviceData);
            if anomaly is AnomalyAlert {
                anomalies.push(anomaly);
            }
        }
    }
    return anomalies;
}

function detectServiceAnomaly(CostData[] serviceData) returns AnomalyAlert? {
    if (serviceData.length() < 7) return ();

    CostData currentData = serviceData[serviceData.length() - 1];
    float currentCost = currentData.cost;

    float sum = 0.0;
    int count = 0;
    foreach int i in 0 ..< (serviceData.length() - 1) {
        sum += serviceData[i].cost;
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

    if !isAnomaly return ();

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

// ==== Health Score ====
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

// ==== Cost Trends ====
function calculateCostTrends() returns CostTrend[] {
    CostTrend[] trends = [];
    map<float[]> serviceCosts = {};

    int dataLength = historicalCostData.length();
    int startIndex = dataLength > 7 ? dataLength - 7 : 0;

    foreach int i in startIndex ..< dataLength {
        CostData item = historicalCostData[i];
        if serviceCosts.hasKey(item.serviceType) {
            float[] existing = serviceCosts[item.serviceType];
            existing.push(item.cost);
            serviceCosts[item.serviceType] = existing;
        } else {
            serviceCosts[item.serviceType] = [item.cost];
        }
    }

    foreach string serviceType in serviceCosts.keys() {
        float[] costs = serviceCosts[serviceType];
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

// ==== Mock Data Generator ====
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

                time:Utc timestamp = time:utcAddSeconds(time:utcNow(), -(30 - day) * 86400);

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

// ==== Dashboard HTML ====
function getDashboardHtml() returns string {
    return string `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cloud Cost Anomaly Detection</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script>
    <style>
        /* styles omitted for brevity, same as you pasted */
    </style>
</head>
<body>
   <!-- body content same as you pasted -->
</body>
</html>`;
}
