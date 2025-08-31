import ballerina/http;
import ballerina/time;

// Pricing data
isolated function getPricing(string provider) returns map<float> {
    match provider {
        "AWS" => { return {"vm": 0.05, "storage": 0.01, "network": 0.02}; }
        "Azure" => { return {"vm": 0.045, "storage": 0.012, "network": 0.018}; }
        "Google" => { return {"vm": 0.048, "storage": 0.011, "network": 0.019}; }
        _ => { return {"vm": 0.05, "storage": 0.01, "network": 0.02}; }
    }
}

// Cloud resource type
type CloudResource record {
    string id;
    string resourceType;
    float cpuUsage;
    float storageUsage;
    float costPerMonth;
};

// AI suggestion type
type AISuggestion record {
    string resourceId;
    string recommendation;
    string confidence;
};

// Sample resources
final CloudResource[] resources = [
    {id: "i-12345", resourceType: "EC2", cpuUsage: 8.5, storageUsage: 30.0, costPerMonth: 120.0},
    {id: "i-67890", resourceType: "EC2", cpuUsage: 55.0, storageUsage: 50.0, costPerMonth: 200.0},
    {id: "bucket-1", resourceType: "S3", cpuUsage: 0.0, storageUsage: 80.0, costPerMonth: 40.0}
];

// AI scoring
function getAIScore(CloudResource res) returns int {
    if res.resourceType == "EC2" {
        if res.cpuUsage < 10.0 { return 5; }
        else if res.cpuUsage < 50.0 { return 3; }
        else { return 1; }
    } else if res.resourceType == "S3" {
        if res.storageUsage > 70.0 { return 5; }
        else if res.storageUsage > 40.0 { return 3; }
        else { return 1; }
    }
    return 2;
}

// Generate AI recommendation
function generateRecommendation(CloudResource res, int score) returns AISuggestion {
    string rec;
    string confidence;
    if score >= 5 {
        rec = "Your " + res.resourceType + " " + res.id + " is mostly idle. Consider downsizing or stopping it to save ~$" + res.costPerMonth.toString() + "/month.";
        confidence = "High";
    } else if score >= 3 {
        rec = "Monitor " + res.resourceType + " " + res.id + "; usage may need optimization soon.";
        confidence = "Medium";
    } else {
        rec = res.resourceType + " " + res.id + " is performing optimally.";
        confidence = "Low";
    }
    return {resourceId: res.id, recommendation: rec, confidence: confidence};
}

// Main service
service / on new http:Listener(8080) {

    // Homepage
    resource function get .() returns http:Response {
        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>CloudOptimizer Pro</title>
</head>
<body>
<h1>Welcome to CloudOptimizer Pro</h1>
<p>Use /report, /ai-suggestions, /resources endpoints for demo.</p>
</body>
</html>`;
        http:Response res = new;
        res.setPayload(html);
        res.setHeader("Content-Type", "text/html");
        return res;
    }

    // Report endpoint
    resource function get report(http:Request req) returns http:Response {
        map<string[]> params = req.getQueryParams();
        string provider = "AWS";
        float vm=0.0; float storage=0.0; float network=0.0;

        string[]? providerParam = params["provider"];
        if providerParam is string[] && providerParam.length() > 0 { provider = providerParam[0]; }
        string[]? vmParam = params["vm"];
        if vmParam is string[] && vmParam.length() > 0 { float|error vmResult = float:fromString(vmParam[0]); if vmResult is float { vm = vmResult; } }
        string[]? storageParam = params["storage"];
        if storageParam is string[] && storageParam.length() > 0 { float|error storageResult = float:fromString(storageParam[0]); if storageResult is float { storage = storageResult; } }
        string[]? networkParam = params["network"];
        if networkParam is string[] && networkParam.length() > 0 { float|error networkResult = float:fromString(networkParam[0]); if networkResult is float { network = networkResult; } }

        map<float> rates = getPricing(provider);
        float vmCost = vm * (rates["vm"] ?: 0.05);
        float storageCost = storage * (rates["storage"] ?: 0.01);
        float networkCost = network * (rates["network"] ?: 0.02);
        float total = vmCost + storageCost + networkCost;

        string report = "Cloud Cost Report\nProvider: " + provider +
            "\nVM: " + vm.toString() + " hours = $" + vmCost.toString() +
            "\nStorage: " + storage.toString() + " GB = $" + storageCost.toString() +
            "\nNetwork: " + network.toString() + " GB = $" + networkCost.toString() +
            "\nTotal: $" + total.toString() +
            "\nGenerated: " + time:utcToString(time:utcNow());

        http:Response res = new;
        res.setPayload(report);
        res.setHeader("Content-Type", "text/plain");
        res.setHeader("Content-Disposition", "attachment; filename=report.txt");
        return res;
    }

    // AI Suggestions endpoint
    resource function get ai-suggestions() returns json {
        json[] suggestions = [];
        foreach CloudResource r in resources {
            int score = getAIScore(r);
            AISuggestion rec = generateRecommendation(r, score);
            suggestions.push(<json>rec);
        }
        return <json>{ status: "success", timestamp: time:utcToString(time:utcNow()), suggestions: suggestions };
    }

    // All resources endpoint
    resource function get resources() returns json {
        return <json>{ status: "success", timestamp: time:utcToString(time:utcNow()), resources: resources };
    }

    // Favicon
    resource function get favicon\.ico() returns http:Response {
        http:Response res = new;
        res.statusCode = 204;
        return res;
    }
}
