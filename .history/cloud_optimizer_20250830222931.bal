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

// Cloud resources for AI suggestions
type CloudResource record {
    string id;
    string type; // EC2, S3, etc.
    float cpuUsage; 
    float storageUsage; 
    float costPerMonth;
};

type AISuggestion record {
    string resourceId;
    string recommendation;
    string confidence;
};

// Sample resources
final CloudResource[] resources = [
    {id: "i-12345", type: "EC2", cpuUsage: 8.5, storageUsage: 30.0, costPerMonth: 120.0},
    {id: "i-67890", type: "EC2", cpuUsage: 55.0, storageUsage: 50.0, costPerMonth: 200.0},
    {id: "bucket-1", type: "S3", cpuUsage: 0.0, storageUsage: 80.0, costPerMonth: 40.0}
];

// AI scoring logic
function getAIScore(CloudResource resource) returns int {
    if resource.type == "EC2" {
        if resource.cpuUsage < 10.0 { return 5; }
        else if resource.cpuUsage < 50.0 { return 3; }
        else { return 1; }
    } else if resource.type == "S3" {
        if resource.storageUsage > 70.0 { return 5; }
        else if resource.storageUsage > 40.0 { return 3; }
        else { return 1; }
    }
    return 2;
}

function generateRecommendation(CloudResource resource, int score) returns AISuggestion {
    string rec;
    string confidence;
    if score >= 5 {
        rec = "Your " + resource.type + " `" + resource.id + "` is mostly idle. Consider downsizing or stopping it to save ~$" + 
              string(resource.costPerMonth) + "/month.";
        confidence = "High";
    } else if score >= 3 {
        rec = "Monitor " + resource.type + " `" + resource.id + "`; usage may need optimization soon.";
        confidence = "Medium";
    } else {
        rec = resource.type + " `" + resource.id + "` is performing optimally.";
        confidence = "Low";
    }
    return {resourceId: resource.id, recommendation: rec, confidence: confidence};
}

// Main service
service / on new http:Listener(8080) {

    resource function get .() returns http:Response {
        string html = "<html><body><h1>CloudOptimizer Pro</h1><p>Use /ai-suggestions for AI cost recommendations.</p></body></html>";
        http:Response res = new;
        res.setPayload(html);
        res.setHeader("Content-Type", "text/html");
        return res;
    }

    // Report generation
    resource function get report(http:Request req) returns http:Response {
        map<string[]> params = req.getQueryParams();
        string provider = "AWS";
        float vm = 0.0;
        float storage = 0.0;
        float network = 0.0;
        
        string[]? providerParam = params["provider"];
        if providerParam is string[] && providerParam.length() > 0 { provider = providerParam[0]; }
        string[]? vmParam = params["vm"];
        if vmParam is string[] && vmParam.length() > 0 {
            float|error vmResult = float:fromString(vmParam[0]);
            if vmResult is float vmVal { vm = vmVal; }
        }
        string[]? storageParam = params["storage"];
        if storageParam is string[] && storageParam.length() > 0 {
            float|error storageResult = float:fromString(storageParam[0]);
            if storageResult is float stVal { storage = stVal; }
        }
        string[]? networkParam = params["network"];
        if networkParam is string[] && networkParam.length() > 0 {
            float|error networkResult = float:fromString(networkParam[0]);
            if networkResult is float nwVal { network = nwVal; }
        }

        map<float> rates = getPricing(provider);
        float vmCost = vm * (rates["vm"] ?: 0.05);
        float storageCost = storage * (rates["storage"] ?: 0.01);
        float networkCost = network * (rates["network"] ?: 0.02);
        float total = vmCost + storageCost + networkCost;

        string report = string `Cloud Cost Report
Provider: ${provider}
VM: ${vm} hours = $${vmCost.toString()}
Storage: ${storage} GB = $${storageCost.toString()}
Network: ${network} GB = $${networkCost.toString()}
Total: $${total.toString()}
Generated: ${time:utcToString(time:utcNow())}`;

        http:Response res = new;
        res.setPayload(report);
        res.setHeader("Content-Type", "text/plain");
        res.setHeader("Content-Disposition", "attachment; filename=report.txt");
        return res;
    }

    // AI Suggestions endpoint
    resource function get ai-suggestions() returns json {
        AISuggestion[] suggestions = [];
        foreach var resource in resources {
            int score = getAIScore(resource);
            AISuggestion rec = generateRecommendation(resource, score);
            suggestions.push(rec);
        }
        return {
            status: "success",
            timestamp: time:currentTime().toString(),
            suggestions: suggestions
        };
    }

    resource function get favicon\.ico() returns http:Response {
        http:Response res = new;
        res.statusCode = 204;
        return res;
    }
}
