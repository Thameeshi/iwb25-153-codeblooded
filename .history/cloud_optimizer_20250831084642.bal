import ballerina/http;
import ballerina/time;

// -------------------------
// Module-level Types
// -------------------------
type CloudResource record {
    string id;
    string resourceType;
    float cpuUsage;
    float storageUsage;
    float costPerMonth;
};

type AISuggestion record {
    string resourceId;
    string recommendation;
    string confidence;
};

// -------------------------
// Pricing Data
// -------------------------
function getPricing(string provider) returns map<float> {
    if provider == "AWS" {
        return {"vm": 0.05, "storage": 0.01, "network": 0.02};
    } else if provider == "Azure" {
        return {"vm": 0.045, "storage": 0.012, "network": 0.018};
    } else if provider == "Google" {
        return {"vm": 0.048, "storage": 0.011, "network": 0.019};
    } else {
        return {"vm": 0.05, "storage": 0.01, "network": 0.02};
    }
}

// -------------------------
// Sample Resources
// -------------------------
final CloudResource[] resources = [
    {id: "i-12345", resourceType: "EC2", cpuUsage: 8.5, storageUsage: 30.0, costPerMonth: 120.0},
    {id: "i-67890", resourceType: "EC2", cpuUsage: 55.0, storageUsage: 50.0, costPerMonth: 200.0},
    {id: "bucket-1", resourceType: "S3", cpuUsage: 0.0, storageUsage: 80.0, costPerMonth: 40.0}
];

// -------------------------
// AI Scoring & Recommendation
// -------------------------
function getAIScore(CloudResource res) returns int {
    if res.resourceType == "EC2" {
        if res.cpuUsage < 10.0 {
            return 5;
        } else if res.cpuUsage < 50.0 {
            return 3;
        } else {
            return 1;
        }
    } else if res.resourceType == "S3" {
        if res.storageUsage > 70.0 {
            return 5;
        } else if res.storageUsage > 40.0 {
            return 3;
        } else {
            return 1;
        }
    }
    return 2;
}

function generateRecommendation(CloudResource res, int score) returns AISuggestion {
    string rec;
    string confidence;
    if score >= 5 {
        rec = "Your " + res.resourceType + " " + res.id +
              " is mostly idle. Consider downsizing or stopping it to save ~$" +
              res.costPerMonth.toString() + "/month.";
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

// -------------------------
// Cloud Optimizer Service
// -------------------------
service / on new http:Listener(8080) {

    // Homepage
    resource function get .() returns http:Response {
        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>CloudOptimizer Pro</title>
<style>
body { font-family: Arial, sans-serif; background-color: #f4f4f9; color: #333; padding: 20px; }
h1 { color: #2c3e50; }
a { text-decoration: none; color: #3498db; margin-right: 15px; }
a:hover { text-decoration: underline; }
</style>
</head>
<body>
<h1>Welcome to CloudOptimizer Pro</h1>
<p>Use the links below:</p>
<a href="/report">Cost Report</a>
<a href="/ai-suggestions">AI Suggestions</a>
<a href="/resources">All Resources</a>
</body>
</html>`;

        http:Response res = new;
        res.setPayload(html);
        res.setHeader("Content-Type", "text/html");
        return res;
    }

    // Report Endpoint
    resource function get report(http:Request req) returns http:Response {
        map<string[]> queryParams = req.getQueryParams();

        string provider = "AWS";
        if queryParams.hasKey("provider") {
            string[]? pArr = queryParams["provider"];
            if pArr is string[] && pArr.length() > 0 {
                provider = pArr[0];
            }
        }

        float vm = 0.0;
        float storage = 0.0;
        float network = 0.0;

        if queryParams.hasKey("vm") {
            string[]? vArr = queryParams["vm"];
            if vArr is string[] && vArr.length() > 0 {
                vm = check float:fromString(vArr[0]);
            }
        }
        if queryParams.hasKey("storage") {
            string[]? sArr = queryParams["storage"];
            if sArr is string[] && sArr.length() > 0 {
                storage = check float:fromString(sArr[0]);
            }
        }
        if queryParams.hasKey("network") {
            string[]? nArr = queryParams["network"];
            if nArr is string[] && nArr.length() > 0 {
                network = check float:fromString(nArr[0]);
            }
        }

        map<float> rates = getPricing(provider);
        float vmCost = vm * (rates["vm"] ?: 0.05);
        float storageCost = storage * (rates["storage"] ?: 0.01);
        float networkCost = network * (rates["network"] ?: 0.02);
        float total = vmCost + storageCost + networkCost;

        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Cloud Cost Report</title>
<style>
body { font-family: Arial, sans-serif; background-color: #f9f9f9; padding: 20px; }
h2 { color: #2c3e50; }
table { width: 50%; border-collapse: collapse; margin-top: 20px; }
th, td { border: 1px solid #ccc; padding: 10px; text-align: left; }
th { background-color: #3498db; color: #fff; }
tr:nth-child(even) { background-color: #ecf0f1; }
</style>
</head>
<body>
<h2>Cloud Cost Report - \${provider}</h2>
<table>
<tr><th>Resource</th><th>Usage</th><th>Cost ($)</th></tr>
<tr><td>VM</td><td>\${vm} hours</td><td>\${vmCost}</td></tr>
<tr><td>Storage</td><td>\${storage} GB</td><td>\${storageCost}</td></tr>
<tr><td>Network</td><td>\${network} GB</td><td>\${networkCost}</td></tr>
<tr><th>Total</th><td></td><th>\${total}</th></tr>
</table>
<p>Generated: \${time:utcToString(time:utcNow())}</p>
<a href="/">Back to Home</a>
</body>
</html>`;

        http:Response res = new;
        res.setPayload(html);
        res.setHeader("Content-Type", "text/html");
        return res;
    }

    // AI Suggestions Endpoint
    resource function get ai-suggestions() returns http:Response {
        AISuggestion[] aiSuggestions = [];

        foreach var r in resources {
            int score = getAIScore(r);
            aiSuggestions.push(generateRecommendation(r, score));
        }

        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>AI Suggestions</title>
<style>
body { font-family: Arial, sans-serif; background-color: #f9f9f9; padding: 20px; }
h2 { color: #2c3e50; }
table { width: 80%; border-collapse: collapse; margin-top: 20px; }
th, td { border: 1px solid #ccc; padding: 10px; text-align: left; }
th { background-color: #e67e22; color: #fff; }
tr:nth-child(even) { background-color: #ecf0f1; }
.conf-High { color: green; font-weight: bold; }
.conf-Medium { color: orange; font-weight: bold; }
.conf-Low { color: red; font-weight: bold; }
</style>
</head>
<body>
<h2>AI Suggestions</h2>
<table>
<tr><th>Resource ID</th><th>Recommendation</th><th>Confidence</th></tr>`;

        foreach var rec in aiSuggestions {
            html += string `<tr>
<td>\${rec.resourceId}</td>
<td>\${rec.recommendation}</td>
<td class="conf-\${rec.confidence}">\${rec.confidence}</td>
</tr>`;
        }

        html += string `</table>
<p>Generated: \${time:utcToString(time:utcNow())}</p>
<a href="/">Back to Home</a>
</body>
</html>`;

        http:Response res = new;
        res.setPayload(html);
        res.setHeader("Content-Type", "text/html");
        return res;
    }

    // All Resources Endpoint (JSON)
    resource function get resources() returns json {
        json resJson = checkpanic resources.cloneWithType(json);
        return {
            status: "success",
            timestamp: time:utcToString(time:utcNow()),
            resources: resJson
        };
    }

    // Favicon
    resource function get favicon\.ico() returns http:Response {
        http:Response res = new;
        res.statusCode = 204;
        return res;
    }
}
