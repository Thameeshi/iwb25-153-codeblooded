import ballerina/http;
import ballerina/time;

// -------------------------
// Simple Types
// -------------------------
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

// -------------------------
// Pricing Function (Added)
// -------------------------
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

// -------------------------
// Sample Data
// -------------------------
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

// -------------------------
// Simple AI Analysis
// -------------------------
function analyzeResource(CloudResource res) returns AISuggestion {
    string recommendation;
    string confidence;
    float savings = 0.0;
    string[] actions = [];

    if res.resourceType == "EC2" {
        if res.cpuUsage < 10.0 {
            recommendation = "Instance underutilized - consider downsizing";
            confidence = "High";
            savings = res.costPerMonth * 0.6;
            actions = ["Downsize instance", "Use spot instances"];
        } else if res.cpuUsage < 30.0 {
            recommendation = "Moderate optimization opportunity";
            confidence = "Medium";
            savings = res.costPerMonth * 0.3;
            actions = ["Right-size instance"];
        } else if res.cpuUsage > 80.0 {
            recommendation = "Consider scaling up for better performance";
            confidence = "High";
            savings = 0.0;
            actions = ["Add load balancer", "Scale horizontally"];
        } else {
            recommendation = "Resource performing optimally";
            confidence = "Low";
            savings = 0.0;
            actions = ["Continue monitoring"];
        }
    } else if res.resourceType == "S3" {
        if res.storageUsage > 90.0 {
            recommendation = "Storage nearly full - archive old data";
            confidence = "High";
            savings = 0.0;
            actions = ["Archive old files", "Set lifecycle policies"];
        } else if res.storageUsage < 40.0 {
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
    } else {
        recommendation = "Manual review needed";
        confidence = "Low";
        savings = 0.0;
        actions = ["Manual check"];
    }

    return {
        resourceId: res.id,
        recommendation: recommendation,
        confidence: confidence,
        potentialSavings: savings,
        actions: actions
    };
}

// -------------------------
// Simple Service
// -------------------------
service / on new http:Listener(8081) {

    // Enhanced Homepage
    resource function get .() returns http:Response {
        float totalCost = 0.0;
        float totalSavings = 0.0;
        
        foreach var r in resources {
            totalCost += r.costPerMonth;
            AISuggestion suggestion = analyzeResource(r);
            totalSavings += suggestion.potentialSavings;
        }

        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>CloudOptimizer Pro</title>
<style>
body { 
    font-family: 'Segoe UI', sans-serif; 
    background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
    margin: 0; padding: 20px; min-height: 100vh;
}
.container { max-width: 1000px; margin: 0 auto; }
.card { 
    background: rgba(255,255,255,0.9); border-radius: 15px; 
    padding: 30px; margin-bottom: 20px; backdrop-filter: blur(10px);
    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
}
h1 { color: #2c3e50; text-align: center; font-size: 2.5rem; margin-bottom: 10px; }
.subtitle { text-align: center; color: #7f8c8d; margin-bottom: 30px; }
.metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
.metric { 
    background: linear-gradient(45deg, #667eea, #764ba2); color: white;
    padding: 20px; border-radius: 12px; text-align: center;
}
.metric-value { font-size: 2rem; font-weight: bold; margin-bottom: 5px; }
.metric-label { font-size: 0.9rem; opacity: 0.9; }
.nav-buttons { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; }
.nav-btn { 
    display: block; padding: 18px; background: #34495e; color: white;
    text-decoration: none; border-radius: 10px; text-align: center;
    transition: all 0.3s ease; font-weight: 500;
}
.nav-btn:hover { background: #2c3e50; transform: translateY(-3px); }
</style>
</head>
<body>
<div class="container">
    <div class="card">
        <h1>CloudOptimizer Pro</h1>
        <p class="subtitle">Smart Cloud Cost Management</p>
        
        <div class="metrics">
            <div class="metric">
                <div class="metric-value">$${totalCost}</div>
                <div class="metric-label">Monthly Cost</div>
            </div>
            <div class="metric">
                <div class="metric-value">$${totalSavings}</div>
                <div class="metric-label">Potential Savings</div>
            </div>
            <div class="metric">
                <div class="metric-value">${resources.length()}</div>
                <div class="metric-label">Resources</div>
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

    // AI Suggestions Page
    resource function get ai\-suggestions() returns http:Response {
        AISuggestion[] suggestions = [];

        foreach var r in resources {
            suggestions.push(analyzeResource(r));
        }

        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AI Suggestions</title>
<style>
body { 
    font-family: 'Segoe UI', sans-serif; 
    background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
    margin: 0; padding: 20px; min-height: 100vh;
}
.container { max-width: 900px; margin: 0 auto; }
.header { 
    background: rgba(255,255,255,0.9); border-radius: 15px; 
    padding: 25px; margin-bottom: 25px; text-align: center;
}
h2 { color: #2c3e50; font-size: 2rem; margin-bottom: 10px; }
.suggestion { 
    background: rgba(255,255,255,0.9); border-radius: 12px; 
    padding: 20px; margin-bottom: 15px;
    border-left: 4px solid #3498db;
}
.suggestion.high-savings { border-left-color: #e74c3c; }
.suggestion.medium-savings { border-left-color: #f39c12; }
.suggestion.optimal { border-left-color: #27ae60; }
.suggestion-header { display: flex; justify-content: space-between; margin-bottom: 15px; }
.resource-name { font-size: 1.1rem; font-weight: bold; color: #2c3e50; }
.confidence { 
    padding: 5px 12px; border-radius: 15px; font-size: 0.9rem; font-weight: bold;
}
.conf-High { background: #d5f4e6; color: #27ae60; }
.conf-Medium { background: #fef9e7; color: #f39c12; }
.conf-Low { background: #fadbd8; color: #e74c3c; }
.savings-amount { 
    background: #27ae60; color: white; padding: 8px 15px; 
    border-radius: 8px; display: inline-block; margin: 10px 0;
}
.actions { margin-top: 15px; }
.action { 
    background: #ecf0f1; padding: 6px 12px; border-radius: 12px; 
    margin: 2px; display: inline-block; font-size: 0.9rem;
}
.back-link { 
    display: block; background: #3498db; color: white; 
    padding: 15px 30px; border-radius: 20px; text-decoration: none;
    text-align: center; margin-top: 25px;
}
.back-link:hover { background: #2980b9; }
</style>
</head>
<body>
<div class="container">
    <div class="header">
        <h2>AI Suggestions</h2>
        <p>Smart optimization recommendations</p>
    </div>`;

        foreach var suggestion in suggestions {
            string cardClass = suggestion.potentialSavings > 50.0 ? "high-savings" : 
                              suggestion.potentialSavings > 0.0 ? "medium-savings" : "optimal";
            
            html += string `
    <div class="suggestion ${cardClass}">
        <div class="suggestion-header">
            <div class="resource-name">${suggestion.resourceId}</div>
            <div class="confidence conf-${suggestion.confidence}">${suggestion.confidence}</div>
        </div>
        <div style="margin-bottom: 10px;">${suggestion.recommendation}</div>`;
        
        if suggestion.potentialSavings > 0.0 {
            html += string `<div class="savings-amount">Save $${suggestion.potentialSavings}/month</div>`;
        }
        
        html += string `<div class="actions">
            <strong>Actions:</strong><br>`;
        
        foreach var action in suggestion.actions {
            html += string `<span class="action">${action}</span>`;
        }
        
        html += string `</div></div>`;
        }

        html += string `
    <a href="/" class="back-link">Back to Dashboard</a>
</div>
</body>
</html>`;

        http:Response res = new;
        res.setPayload(html);
        res.setHeader("Content-Type", "text/html");
        return res;
    }

    // Simple Cost Report
    resource function get report() returns http:Response {
        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Cost Report</title>
<style>
body { 
    font-family: 'Segoe UI', sans-serif; 
    background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
    margin: 0; padding: 20px; min-height: 100vh;
}
.container { max-width: 800px; margin: 0 auto; }
.card { 
    background: rgba(255,255,255,0.9); border-radius: 15px; 
    padding: 30px; backdrop-filter: blur(10px);
}
h2 { color: #2c3e50; text-align: center; margin-bottom: 25px; }
.resource-table { 
    width: 100%; border-collapse: collapse; margin: 20px 0;
    border-radius: 10px; overflow: hidden;
}
.resource-table th { 
    background: #3498db; color: white; padding: 15px; text-align: left;
}
.resource-table td { padding: 12px 15px; border-bottom: 1px solid #ecf0f1; }
.resource-table tr:nth-child(even) { background: #f8f9fa; }
.resource-table tr:hover { background: #e3f2fd; }
.back-link { 
    display: block; background: #3498db; color: white; 
    padding: 15px 30px; border-radius: 20px; text-decoration: none;
    text-align: center; margin-top: 20px;
}
.back-link:hover { background: #2980b9; }
</style>
</head>
<body>
<div class="container">
    <div class="card">
        <h2>Cost Report</h2>
        
        <table class="resource-table">
            <thead>
                <tr>
                    <th>Resource</th>
                    <th>Type</th>
                    <th>CPU %</th>
                    <th>Memory %</th>
                    <th>Cost/Month</th>
                </tr>
            </thead>
            <tbody>`;

        foreach var r in resources {
            html += string `
                <tr>
                    <td><strong>${r.name}</strong><br><small>${r.id}</small></td>
                    <td>${r.resourceType}</td>
                    <td>${r.cpuUsage}%</td>
                    <td>${r.memoryUsage}%</td>
                    <td>$${r.costPerMonth}</td>
                </tr>`;
        }

        html += string `
            </tbody>
        </table>
        
        <p style="text-align: center; color: #7f8c8d;">
            Generated: ${time:utcToString(time:utcNow())}
        </p>
    </div>
    
    <a href="/" class="back-link">Back to Dashboard</a>
</div>
</body>
</html>`;

        http:Response res = new;
        res.setPayload(html);
        res.setHeader("Content-Type", "text/html");
        return res;
    }

    // JSON API - Fixed type conversion
    resource function get resources() returns json {
        AISuggestion[] suggestions = [];
        float totalCost = 0.0;
        float totalSavings = 0.0;
        
        foreach var r in resources {
            totalCost += r.costPerMonth;
            AISuggestion suggestion = analyzeResource(r);
            suggestions.push(suggestion);
            totalSavings += suggestion.potentialSavings;
        }
        
        // Convert arrays to json properly
        json resourcesJson = resources.toJson();
        json suggestionsJson = suggestions.toJson();
        
        return {
            "status": "success",
            "timestamp": time:utcToString(time:utcNow()),
            "summary": {
                "totalCost": totalCost,
                "potentialSavings": totalSavings,
                "resourceCount": resources.length()
            },
            "resources": resourcesJson,
            "suggestions": suggestionsJson
        };
    }

    // Health Check
    resource function get health() returns json {
        return {
            "status": "healthy",
            "timestamp": time:utcToString(time:utcNow()),
            "version": "1.0.0"
        };
    }

    // Favicon
    resource function get favicon\.ico() returns http:Response {
        http:Response res = new;
        res.statusCode = 204;
        return res;
    }
}
