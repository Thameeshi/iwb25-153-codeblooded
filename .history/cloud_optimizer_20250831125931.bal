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

    resource function get .() returns string {
        float totalCost = 0.0;
        float totalSavings = 0.0;
        
        foreach var r in resources {
            totalCost += r.costPerMonth;
            AISuggestion suggestion = analyzeResource(r);
            totalSavings += suggestion.potentialSavings;
        }

        return string `
        <h1>CloudOptimizer Pro</h1>
        <p>Total Cost: $${totalCost}/month</p>
        <p>Potential Savings: $${totalSavings}/month</p>
        <p>Resources: ${resources.length()}</p>
        <br>
        <a href="/ai-suggestions">AI Suggestions</a> | 
        <a href="/report">Cost Report</a> | 
        <a href="/resources">Resources JSON</a> | 
        <a href="/health">Health Check</a>
        `;
    }

    resource function get ai\-suggestions() returns string {
        string result = "<h2>AI Suggestions</h2>";
        
        foreach var r in resources {
            AISuggestion suggestion = analyzeResource(r);
            result += string `
            <div>
                <h3>${r.name} (${suggestion.resourceId})</h3>
                <p><strong>Recommendation:</strong> ${suggestion.recommendation}</p>
                <p><strong>Confidence:</strong> ${suggestion.confidence}</p>
                <p><strong>Potential Savings:</strong> $${suggestion.potentialSavings}/month</p>
                <p><strong>Actions:</strong> ${string:'join(", ", ...suggestion.actions)}</p>
            </div><hr>`;
        }
        
        result += "<br><a href='/'>Back to Dashboard</a>";
        return result;
    }

    resource function get report() returns string {
        string result = "<h2>Cost Report</h2><table border='1'>";
        result += "<tr><th>Name</th><th>Type</th><th>CPU %</th><th>Memory %</th><th>Cost/Month</th></tr>";
        
        foreach var r in resources {
            result += string `<tr>
                <td>${r.name}</td>
                <td>${r.resourceType}</td>
                <td>${r.cpuUsage}%</td>
                <td>${r.memoryUsage}%</td>
                <td>$${r.costPerMonth}</td>
            </tr>`;
        }
        
        result += "</table><br><a href='/'>Back to Dashboard</a>";
        return result;
    }

    resource function get resources() returns json {
        return {
            "resources": resources,
            "timestamp": time:utcToString(time:utcNow())
        };
    }

    resource function get health() returns json {
        return {
            "status": "healthy",
            "timestamp": time:utcToString(time:utcNow())
        };
    }
}