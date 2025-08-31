import ballerina/http;
import ballerina/time;

type CloudResource record {
    string id;
    string name;
    string resourceType;
    float cpuUsage;
    float memoryUsage;
    float storageUsage;
    float costPerMonth;
};

type AISuggestion record {
    string resourceId;
    string recommendation;
    string confidence;
    float potentialSavings;
    string[] actions;
};

function getPricing(string provider) returns map<float> {
    if provider == "AWS" {
        return {"vm": 0.05, "storage": 0.01, "network": 0.02};
    } else if provider == "Azure" {
        return {"vm": 0.045, "storage": 0.012, "network": 0.018};
    } else if provider == "Google" {
        return {"vm": 0.048, "storage": 0.011, "network": 0.019};
    }
    return {"vm": 0.05, "storage": 0.01, "network": 0.02};
}

final CloudResource[] resources = [
    {
        id: "i-12345", name: "web-server-01", resourceType: "EC2",
        cpuUsage: 8.5, memoryUsage: 15.2, storageUsage: 30.0, costPerMonth: 120.0
    },
    {
        id: "i-67890", name: "database-server", resourceType: "EC2",
        cpuUsage: 75.0, memoryUsage: 82.3, storageUsage: 65.0, costPerMonth: 200.0
    },
    {
        id: "bucket-1", name: "static-files", resourceType: "S3",
        cpuUsage: 0.0, memoryUsage: 0.0, storageUsage: 85.0, costPerMonth: 40.0
    }
];

function analyzeResource(CloudResource res) returns AISuggestion {
    string recommendation = "Manual review needed";
    string confidence = "Low";
    float savings = 0.0;
    string[] actions = ["Manual check"];

    if res.resourceType == "EC2" {
        if res.cpuUsage < 10.0 {
            recommendation = "Instance underutilized - consider downsizing";
            confidence = "High";
            savings = res.costPerMonth * 0.6;
            actions = ["Downsize instance", "Use spot instances"];
        } else if res.cpuUsage > 80.0 {
            recommendation = "Consider scaling up for better performance";
            confidence = "High";
            savings = 0.0;
            actions = ["Add load balancer", "Scale horizontally"];
        } else {
            recommendation = "Resource performing optimally";
            confidence = "Medium";
            savings = 0.0;
            actions = ["Continue monitoring"];
        }
    } else if res.resourceType == "S3" {
        if res.storageUsage < 40.0 {
            recommendation = "Consider cheaper storage tier";
            confidence = "Medium";
            savings = res.costPerMonth * 0.25;
            actions = ["Move to IA storage", "Clean unused data"];
        } else {
            recommendation = "Storage usage is appropriate";
            confidence = "Low";
            savings = 0.0;
            actions = ["Continue monitoring"];
        }
    }

    return {
        resourceId: res.id,
        recommendation: recommendation,
        confidence: confidence,
        potentialSavings: savings,
        actions: actions
    };
}

service / on new http:Listener(8081) {

    resource function get .() returns http:Response {
        float totalCost = 0.0;
        float totalSavings = 0.0;
        
        foreach var r in resources {
            totalCost += r.costPerMonth;
            AISuggestion suggestion = analyzeResource(r);
            totalSavings += suggestion.potentialSavings;
        }

        string html = string `<!DOCTYPE html>
<html>
<head>
    <title>CloudOptimizer Pro</title>
    <style>
        body { font-family: Arial, sans-serif; background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); margin: 0; padding: 20px; }
        .container { max-width: 1000px; margin: 0 auto; }
        .card { background: white; border-radius: 15px; padding: 30px; margin-bottom: 20px; }
        h1 { color: #2c3e50; text-align: center; font-size: 2.5rem; margin-bottom: 10px; }
        .metrics { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin: 20px 0; }
        .metric { background: #667eea; color: white; padding: 20px; border-radius: 12px; text-align: center; }
        .metric-value { font-size: 2rem; font-weight: bold; }
        .nav-buttons { display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; }
        .nav-btn { display: block; padding: 18px; background: #34495e; color: white; text-decoration: none; border-radius: 10px; text-align: center; }
        .nav-btn:hover { background: #2c3e50; }
    </style>
</head>
<body>
<div class="container">
    <div class="card">
        <h1>CloudOptimizer Pro</h1>
        
        <div class="metrics">
            <div class="metric">
                <div class="metric-value">$${totalCost}</div>
                <div>Monthly Cost</div>
            </div>
            <div class="metric">
                <div class="metric-value">$${totalSavings}</div>
                <div>Potential Savings</div>
            </div>
            <div class="metric">
                <div class="metric-value">${resources.length()}</div>
                <div>Resources</div>
            </div>
        </div>
        
        <div class="nav-buttons">
            <a href="/ai-suggestions" class="nav-btn">AI Suggestions</a>
            <a href="/report" class="nav-btn">Cost Report</a>
        </div>
    </div>
</div>
</body>
</html>`;

        http:Response res = new;
        res.setPayload(html);
        res.setHeader("Content-Type", "text/html");
        return res;
    }

    resource function get ai\-suggestions() returns string {
        string result = "<h2>AI Suggestions</h2>";
        
        foreach var r in resources {
            AISuggestion suggestion = analyzeResource(r);
            result += string `
            <div style="background: #f8f9fa; padding: 1rem; margin: 0.5rem 0; border-radius: 8px; border-left: 3px solid #667eea;">
                <h3>${r.name} (${suggestion.resourceId})</h3>
                <p><strong>Recommendation:</strong> ${suggestion.recommendation}</p>
                <p><strong>Confidence:</strong> ${suggestion.confidence}</p>`;
                if suggestion.potentialSavings > 0.0 {
                    result += string `<p><strong>Potential Savings:</strong> $${suggestion.potentialSavings}/month</p>`;
                }
                result += string `<p><strong>Actions:</strong> ${string:'join(", ", ...suggestion.actions)}</p>
            </div>`;
        }
        
        result += "<br><a href='/' style='color: #667eea;'>Back to Dashboard</a>";
        return result;
    }

    resource function get report() returns string {
        string result = "<h2>Cost Report</h2><table border='1' style='width: 100%; border-collapse: collapse;'>";
        result += "<tr style='background: #667eea; color: white;'><th>Name</th><th>Type</th><th>CPU %</th><th>Memory %</th><th>Cost/Month</th></tr>";
        
        foreach var r in resources {
            result += string `<tr>
                <td>${r.name}</td>
                <td>${r.resourceType}</td>
                <td>${r.cpuUsage}%</td>
                <td>${r.memoryUsage}%</td>
                <td>$${r.costPerMonth}</td>
            </tr>`;
        }
        
        result += "</table><br><a href='/' style='color: #667eea;'>Back to Dashboard</a>";
        return result;
    }
}