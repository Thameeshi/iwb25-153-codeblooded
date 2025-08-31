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

// Cloud resources
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

// AI scoring logic
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

function generateRecommendation(CloudResource res, int score) returns AISuggestion {
    string rec;
    string confidence;
    if score >= 5 {
        rec = "Your " + res.resourceType + " " + res.id + " is mostly idle. Consider downsizing or stopping it to save ~$" + res.costPerMonth + "/month.";
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
service / on new http:Listener(8081) {

    // Homepage
    resource function get .() returns http:Response {
        string html = "<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><title>CloudOptimizer Pro</title>";
        html += "<style>"
                + "body { font-family: Arial, sans-serif; background: #f4f7f9; color: #333; padding: 20px; }"
                + "h1 { color: #2a7ae2; } h2 { color: #555; }"
                + "ul { list-style: none; padding: 0; }"
                + "li { background: #fff; margin: 10px 0; padding: 15px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }"
                + ".resource-type { font-weight: bold; color: #2a7ae2; }"
                + ".recommendation { margin-top: 5px; font-style: italic; }"
                + ".high { color: green; } .medium { color: orange; } .low { color: gray; }"
                + "p.note { margin-top: 20px; }"
                + "label { margin-right: 10px; } select, input { margin-right: 20px; padding: 5px; }"
                + "</style></head><body>";
        html += "<h1>CloudOptimizer Pro</h1>";

        // Filters
        html += "<div>"
                + "<label for='typeFilter'>Filter by Type:</label>"
                + "<select id='typeFilter'>"
                + "<option value='all'>All</option>"
                + "<option value='EC2'>EC2</option>"
                + "<option value='S3'>S3</option>"
                + "</select>"
                + "<label for='cpuFilter'>Max CPU Usage (%):</label>"
                + "<input type='number' id='cpuFilter' placeholder='100'>"
                + "<label for='storageFilter'>Max Storage (GB):</label>"
                + "<input type='number' id='storageFilter' placeholder='1000'>"
                + "<button onclick='applyFilter()'>Filter</button>"
                + "<button onclick='resetFilter()'>Reset</button>"
                + "</div>";

        html += "<h2>Resources and AI Recommendations</h2><ul id='resourceList'></ul>";

        // Scripts
        html += "<script>"
                + "const resources = " + <string><json>resources + ";"
                + "function renderResources(list) {"
                + "const ul = document.getElementById('resourceList'); ul.innerHTML='';"
                + "list.forEach(function(res){"
                + "let score = 0;"
                + "if(res.resourceType==='EC2'){ score = res.cpuUsage<10?5: res.cpuUsage<50?3:1; }"
                + "else if(res.resourceType==='S3'){ score = res.storageUsage>70?5: res.storageUsage>40?3:1; }"
                + "let conf = score>=5?'High':score>=3?'Medium':'Low';"
                + "let rec = score>=5?'Your '+res.resourceType+' '+res.id+' is mostly idle. Consider downsizing or stopping it to save ~$'+res.costPerMonth+'/month.'"
                + ": score>=3?'Monitor '+res.resourceType+' '+res.id+'; usage may need optimization soon.'"
                + ": res.resourceType+' '+res.id+' is performing optimally.';"
                + "let li = document.createElement('li');"
                + "li.innerHTML = '<span class=\"resource-type\">'+res.resourceType+' '+res.id+'</span><br>CPU: '+res.cpuUsage+'% | Storage: '+res.storageUsage+' GB | Cost: $'+res.costPerMonth+'<div class=\"recommendation '+conf.toLowerCase()+'\">Recommendation: '+rec+' (Confidence: '+conf+')</div>';"
                + "ul.appendChild(li);"
                + "});}"
                + "function applyFilter() {"
                + "const type = document.getElementById('typeFilter').value;"
                + "const cpuMax = parseFloat(document.getElementById('cpuFilter').value)||100;"
                + "const storageMax = parseFloat(document.getElementById('storageFilter').value)||1000;"
                + "const filtered = resources.filter(r=>(type==='all'||r.resourceType===type)&&r.cpuUsage<=cpuMax&&r.storageUsage<=storageMax);"
                + "renderResources(filtered);}"
                + "function resetFilter() { document.getElementById('typeFilter').value='all'; document.getElementById('cpuFilter').value=''; document.getElementById('storageFilter').value=''; renderResources(resources); }"
                + "renderResources(resources);"
                + "</script>";

        html += "<p class='note'>Use /ai-suggestions for JSON AI recommendations, /report for cost reports, /resources for all resources in JSON.</p>";
        html += "</body></html>";

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
        if providerParam is string[] && providerParam.length()>0 { provider=providerParam[0]; }
        string[]? vmParam = params["vm"];
        if vmParam is string[] && vmParam.length()>0 { float|error vmResult=float:fromString(vmParam[0]); if vmResult is float { vm=vmResult; } }
        string[]? storageParam = params["storage"];
        if storageParam is string[] && storageParam.length()>0 { float|error storageResult=float:fromString(storageParam[0]); if storageResult is float { storage=storageResult; } }
        string[]? networkParam = params["network"];
        if networkParam is string[] && networkParam.length()>0 { float|error networkResult=float:fromString(networkParam[0]); if networkResult is float { network=networkResult; } }

        map<float> rates = getPricing(provider);
        float vmCost=vm*(rates["vm"]?:0.05);
        float storageCost=storage*(rates["storage"]?:0.01);
        float networkCost=network*(rates["network"]?:0.02);
        float total=vmCost+storageCost+networkCost;

        string report = "Cloud Cost Report\nProvider: "+provider+"\nVM: "+vm+" hours = $"+vmCost+"\nStorage: "+storage+" GB = $"+storageCost+"\nNetwork: "+network+" GB = $"+networkCost+"\nTotal: $"+total+"\nGenerated: "+time:utcToString(time:utcNow());

        http:Response res = new;
        res.setPayload(report);
        res.setHeader("Content-Type","text/plain");
        res.setHeader("Content-Disposition","attachment; filename=report.txt");
        return res;
    }

    // AI Suggestions endpoint
    resource function get ai\-suggestions() returns json {
        json[] suggestions = [];
        foreach CloudResource r in resources {
            int score = getAIScore(r);
            AISuggestion rec = generateRecommendation(r, score);
            suggestions.push(<json>rec);
        }
        return <json>{ status:"success", timestamp:time:utcToString(time:utcNow()), suggestions:suggestions };
    }

    // All resources endpoint
    resource function get resources() returns json {
        return <json>{ status:"success", timestamp:time:utcToString(time:utcNow()), resources:resources };
    }

    // Favicon
    resource function get favicon\.ico() returns http:Response {
        http:Response res = new;
        res.statusCode = 204;
        return res;
    }
}
