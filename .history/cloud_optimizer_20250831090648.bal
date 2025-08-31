import ballerina/http;
import ballerina/time;

// -------------------------
// Enhanced Types
// -------------------------
type CloudResource record {
    string id;
    string name;
    string resourceType;
    string provider;
    float cpuUsage;
    float memoryUsage;
    float storageUsage;
    float costPerMonth;
    boolean isProduction;
    string[] tags;
};

type AISuggestion record {
    string resourceId;
    string category;
    string recommendation;
    string reasoning;
    float potentialSavings;
    string confidence;
    string[] actionItems;
};

type CostSummary record {
    float totalCost;
    float potentialSavings;
    int totalResources;
    int needsOptimization;
};

// -------------------------
// Enhanced Sample Data
// -------------------------
final CloudResource[] resources = [
    {
        id: "i-12345", name: "web-server-01", resourceType: "EC2", provider: "AWS",
        cpuUsage: 8.5, memoryUsage: 15.2, storageUsage: 30.0, costPerMonth: 120.0,
        isProduction: false, tags: ["web", "frontend", "dev"]
    },
    {
        id: "i-67890", name: "database-primary", resourceType: "EC2", provider: "AWS",
        cpuUsage: 75.0, memoryUsage: 82.3, storageUsage: 65.0, costPerMonth: 200.0,
        isProduction: true, tags: ["database", "mysql", "prod"]
    },
    {
        id: "bucket-1", name: "static-assets", resourceType: "S3", provider: "AWS",
        cpuUsage: 0.0, memoryUsage: 0.0, storageUsage: 85.0, costPerMonth: 40.0,
        isProduction: true, tags: ["storage", "static", "prod"]
    },
    {
        id: "rds-001", name: "analytics-db", resourceType: "RDS", provider: "AWS",
        cpuUsage: 25.0, memoryUsage: 45.0, storageUsage: 40.0, costPerMonth: 180.0,
        isProduction: false, tags: ["database", "analytics", "dev"]
    }
];

// -------------------------
// Enhanced AI Analysis
// -------------------------
function analyzeResource(CloudResource res) returns AISuggestion {
    string category;
    string recommendation;
    string reasoning;
    float potentialSavings = 0.0;
    string confidence;
    string[] actionItems = [];

    if res.resourceType == "EC2" {
        if res.cpuUsage < 10.0 && res.memoryUsage < 20.0 {
            category = "UNDERUTILIZED";
            recommendation = "Instance severely underutilized - consider downsizing";
            reasoning = "CPU at " + res.cpuUsage.toString() + "% and memory at " + res.memoryUsage.toString() + "%";
            potentialSavings = res.costPerMonth * 0.7;
            confidence = "High";
            actionItems = ["Downsize instance", "Schedule auto-stop", "Consider spot instances"];
        } else if res.cpuUsage < 30.0 {
            category = "OPTIMIZATION";
            recommendation = "Good optimization opportunity available";
            reasoning = "CPU usage at " + res.cpuUsage.toString() + "% suggests right-sizing potential";
            potentialSavings = res.costPerMonth * 0.3;
            confidence = "Medium";
            actionItems = ["Right-size instance", "Enable auto-scaling"];
        } else if res.cpuUsage > 80.0 {
            category = "SCALING";
            recommendation = "Consider scaling up - high utilization detected";
            reasoning = "CPU at " + res.cpuUsage.toString() + "% may impact performance";
            potentialSavings = 0.0;
            confidence = "High";
            actionItems = ["Scale horizontally", "Upgrade instance type"];
        } else {
            category = "OPTIMAL";
            recommendation = "Resource performing well";
            reasoning = "Good utilization at " + res.cpuUsage.toString() + "% CPU";
            potentialSavings = 0.0;
            confidence = "Low";
            actionItems = ["Continue monitoring"];
        }
    } else if res.resourceType == "S3" {
        if res.storageUsage > 90.0 {
            category = "CAPACITY";
            recommendation = "Storage nearly full - action needed";
            reasoning = "Storage at " + res.storageUsage.toString() + "% capacity";
            potentialSavings = 0.0;
            confidence = "High";
            actionItems = ["Archive old data", "Implement lifecycle policies"];
        } else if res.storageUsage < 40.0 {
            category = "UNDERUTILIZED";
            recommendation = "Consider storage optimization";
            reasoning = "Low storage usage at " + res.storageUsage.toString() + "%";
            potentialSavings = res.costPerMonth * 0.2;
            confidence = "Medium";
            actionItems = ["Move to cheaper storage tier", "Clean up unused data"];
        } else {
            category = "OPTIMAL";
            recommendation = "Storage usage is appropriate";
            reasoning = "Well-utilized at " + res.storageUsage.toString() + "%";
            potentialSavings = 0.0;
            confidence = "Low";
            actionItems = ["Continue monitoring"];
        }
    } else {
        category = "UNKNOWN";
        recommendation = "Manual review recommended";
        reasoning = "Resource type requires manual analysis";
        potentialSavings = 0.0;
        confidence = "Low";
        actionItems = ["Manual assessment"];
    }

    return {
        resourceId: res.id,
        category: category,
        recommendation: recommendation,
        reasoning: reasoning,
        potentialSavings: potentialSavings,
        confidence: confidence,
        actionItems: actionItems
    };
}

function generateSummary(CloudResource[] res) returns CostSummary {
    float totalCost = 0.0;
    float totalSavings = 0.0;
    int needsOpt = 0;

    foreach var r in res {
        totalCost += r.costPerMonth;
        AISuggestion suggestion = analyzeResource(r);
        totalSavings += suggestion.potentialSavings;
        if suggestion.category == "UNDERUTILIZED" || suggestion.category == "OPTIMIZATION" {
            needsOpt += 1;
        }
    }

    return {
        totalCost: totalCost,
        potentialSavings: totalSavings,
        totalResources: res.length(),
        needsOptimization: needsOpt
    };
}

// -------------------------
// Enhanced Service
// -------------------------
service / on new http:Listener(8081) {

    // Modern Dashboard Homepage
    resource function get .() returns http:Response {
        CostSummary summary = generateSummary(resources);
        
        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>CloudOptimizer Pro</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { 
    font-family: 'Segoe UI', sans-serif; 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh; padding: 20px;
}
.container { max-width: 1200px; margin: 0 auto; }
.dashboard { 
    background: rgba(255,255,255,0.95); border-radius: 20px; 
    padding: 40px; backdrop-filter: blur(10px);
    box-shadow: 0 20px 40px rgba(0,0,0,0.1);
}
h1 { color: #2c3e50; font-size: 2.5rem; margin-bottom: 20px; text-align: center; }
.metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 30px 0; }
.metric-card { 
    background: linear-gradient(45deg, #3498db, #2980b9); color: white;
    padding: 25px; border-radius: 15px; text-align: center;
    transition: transform 0.3s ease;
}
.metric-card:hover { transform: translateY(-5px); }
.metric-value { font-size: 2rem; font-weight: bold; margin-bottom: 8px; }
.metric-label { font-size: 0.9rem; opacity: 0.9; }
.nav-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px; margin-top: 30px; }
.nav-btn { 
    display: block; padding: 20px; background: #34495e; color: white;
    text-decoration: none; border-radius: 12px; text-align: center;
    transition: all 0.3s ease; font-weight: 500;
}
.nav-btn:hover { background: #2c3e50; transform: scale(1.02); }
.savings-highlight { background: linear-gradient(45deg, #27ae60, #2ecc71) !important; }
</style>
</head>
<body>
<div class="container">
    <div class="dashboard">
        <h1>🚀 CloudOptimizer Pro</h1>
        <p style="text-align: center; color: #7f8c8d; font-size: 1.2rem; margin-bottom: 30px;">
            AI-Powered Cloud Cost Management
        </p>
        
        <div class="metrics">
            <div class="metric-card">
                <div class="metric-value">$${summary.totalCost}</div>
                <div class="metric-label">Monthly Cost</div>
            </div>
            <div class="metric-card savings-highlight">
                <div class="metric-value">$${summary.potentialSavings}</div>
                <div class="metric-label">Potential Savings</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">${summary.totalResources}</div>
                <div class="metric-label">Total Resources</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">${summary.needsOptimization}</div>
                <div class="metric-label">Need Optimization</div>
            </div>
        </div>
        
        <div class="nav-grid">
            <a href="/ai-suggestions" class="nav-btn">🤖 AI Suggestions</a>
            <a href="/report" class="nav-btn">📊 Cost Reports</a>
            <a href="/resources" class="nav-btn">☁️ All Resources</a>
            <a href="/health" class="nav-btn">💚 Health Check</a>
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

    // Enhanced AI Suggestions
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
* { margin: 0; padding: 0; box-sizing: border-box; }
body { 
    font-family: 'Segoe UI', sans-serif; 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh; padding: 20px;
}
.container { max-width: 1000px; margin: 0 auto; }
.header { 
    background: rgba(255,255,255,0.95); border-radius: 15px; 
    padding: 25px; margin-bottom: 25px; text-align: center;
}
h2 { color: #2c3e50; font-size: 2rem; }
.suggestion-card { 
    background: rgba(255,255,255,0.95); border-radius: 15px; 
    padding: 25px; margin-bottom: 20px; backdrop-filter: blur(10px);
    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
    border-left: 5px solid #3498db;
}
.suggestion-card.critical { border-left-color: #e74c3c; }
.suggestion-card.warning { border-left-color: #f39c12; }
.suggestion-card.optimal { border-left-color: #27ae60; }
.card-header { display: flex; justify-content: space-between; margin-bottom: 15px; }
.resource-info { font-size: 1.2rem; font-weight: bold; color: #2c3e50; }
.confidence { 
    padding: 8px 15px; border-radius: 20px; font-size: 0.9rem; font-weight: bold;
}
.conf-High { background: #d5f4e6; color: #27ae60; }
.conf-Medium { background: #fef9e7; color: #f39c12; }
.conf-Low { background: #fadbd8; color: #e74c3c; }
.recommendation { font-size: 1.1rem; margin-bottom: 10px; font-weight: 500; }
.reasoning { color: #7f8c8d; margin-bottom: 15px; }
.savings { 
    background: linear-gradient(45deg, #27ae60, #2ecc71);
    color: white; padding: 10px 15px; border-radius: 10px;
    display: inline-block; margin-bottom: 15px; font-weight: bold;
}
.actions { margin-top: 15px; }
.action-tag { 
    background: #ecf0f1; padding: 8px 12px; border-radius: 15px; 
    margin: 3px; display: inline-block; font-size: 0.9rem;
}
.back-link { 
    display: block; background: #3498db; color: white; 
    padding: 15px 30px; border-radius: 25px; text-decoration: none;
    text-align: center; margin-top: 30px; transition: all 0.3s ease;
}
.back-link:hover { background: #2980b9; transform: translateY(-3px); }
</style>
</head>
<body>
<div class="container">
    <div class="header">
        <h2>🤖 AI Optimization Suggestions</h2>
        <p>Smart recommendations powered by advanced analytics</p>
    </div>`;

        foreach var suggestion in suggestions {
            string cardClass = suggestion.category == "UNDERUTILIZED" ? "critical" : 
                              suggestion.category == "OPTIMIZATION" ? "warning" : "optimal";
            
            html += string `
    <div class="suggestion-card ${cardClass}">
        <div class="card-header">
            <div class="resource-info">${suggestion.resourceId}</div>
            <div class="confidence conf-${suggestion.confidence}">${suggestion.confidence}</div>
        </div>
        <div class="recommendation">${suggestion.recommendation}</div>
        <div class="reasoning">${suggestion.reasoning}</div>`;
        
        if suggestion.potentialSavings > 0.0 {
            html += string `<div class="savings">💰 Save $${suggestion.potentialSavings}/month</div>`;
        }
        
        html += string `<div class="actions">
            <strong>Recommended Actions:</strong><br>`;
        
        foreach var action in suggestion.actionItems {
            html += string `<span class="action-tag">${action}</span>`;
        }
        
        html += string `</div></div>`;
        }

        html += string `
    <a href="/" class="back-link">← Back to Dashboard</a>
</div>
</body>
</html>`;

        http:Response res = new;
        res.setPayload(html);
        res.setHeader("Content-Type", "text/html");
        return res;
    }

    // Simple but Enhanced Cost Report
    resource function get report() returns http:Response {
        CostSummary summary = generateSummary(resources);
        
        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Cost Report</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { 
    font-family: 'Segoe UI', sans-serif; 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh; padding: 20px;
}
.container { max-width: 800px; margin: 0 auto; }
.report-card { 
    background: rgba(255,255,255,0.95); border-radius: 15px; 
    padding: 30px; backdrop-filter: blur(10px);
    box-shadow: 0 15px 35px rgba(0,0,0,0.1);
}
h2 { color: #2c3e50; margin-bottom: 25px; text-align: center; }
.summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; margin: 25px 0; }
.summary-item { background: #f8f9fa; padding: 20px; border-radius: 10px; text-align: center; }
.summary-value { font-size: 1.5rem; font-weight: bold; color: #3498db; }
.summary-label { color: #7f8c8d; margin-top: 5px; }
.resource-table { 
    width: 100%; border-collapse: collapse; margin: 25px 0;
    border-radius: 10px; overflow: hidden;
}
.resource-table th { 
    background: linear-gradient(45deg, #3498db, #2980b9);
    color: white; padding: 15px; text-align: left; font-weight: 600;
}
.resource-table td { padding: 12px 15px; border-bottom: 1px solid #ecf0f1; }
.resource-table tr:hover { background: #e3f2fd; }
.back-link { 
    display: block; background: #3498db; color: white; 
    padding: 15px 30px; border-radius: 25px; text-decoration: none;
    text-align: center; margin-top: 25px; transition: all 0.3s ease;
}
.back-link:hover { background: #2980b9; transform: translateY(-3px); }
</style>
</head>
<body>
<div class="container">
    <div class="report-card">
        <h2>📊 Cloud Cost Report</h2>
        
        <div class="summary-grid">
            <div class="summary-item">
                <div class="summary-value">$${summary.totalCost}</div>
                <div class="summary-label">Total Cost</div>
            </div>
            <div class="summary-item">
                <div class="summary-value">$${summary.potentialSavings}</div>
                <div class="summary-label">Potential Savings</div>
            </div>
            <div class="summary-item">
                <div class="summary-value">${summary.totalResources}</div>
                <div class="summary-label">Resources</div>
            </div>
            <div class="summary-item">
                <div class="summary-value">${summary.needsOptimization}</div>
                <div class="summary-label">Need Optimization</div>
            </div>
        </div>
        
        <table class="resource-table">
            <thead>
                <tr>
                    <th>Resource</th>
                    <th>Type</th>
                    <th>CPU %</th>
                    <th>Memory %</th>
                    <th>Cost/Month</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>`;

        foreach var r in resources {
            AISuggestion suggestion = analyzeResource(r);
            string status = suggestion.category == "OPTIMAL" ? "✅ Good" : 
                           suggestion.category == "UNDERUTILIZED" ? "🔴 Underused" : 
                           "🟡 Monitor";
            
            html += string `
                <tr>
                    <td><strong>${r.name}</strong><br><small>${r.id}</small></td>
                    <td>${r.resourceType}</td>
                    <td>${r.cpuUsage}%</td>
                    <td>${r.memoryUsage}%</td>
                    <td>$${r.costPerMonth}</td>
                    <td>${status}</td>
                </tr>`;
        }

        html += string `
            </tbody>
        </table>
        
        <p style="color: #7f8c8d; text-align: center;">
            📅 Generated: ${time:utcToString(time:utcNow())}
        </p>
    </div>
    
    <a href="/" class="back-link">← Back to Dashboard</a>
</div>
</body>
</html>`;

        http:Response res = new;
        res.setPayload(html);
        res.setHeader("Content-Type", "text/html");
        return res;
    }

    // Enhanced JSON API
    resource function get resources() returns json {
        AISuggestion[] suggestions = [];
        foreach var r in resources {
            suggestions.push(analyzeResource(r));
        }
        
        CostSummary summary = generateSummary(resources);
        
        return {
            "status": "success",
            "timestamp": time:utcToString(time:utcNow()),
            "summary": summary,
            "resources": resources,
            "suggestions": suggestions
        };
    }

    // Health Check
    resource function get health() returns json {
        return {
            "status": "healthy",
            "timestamp": time:utcToString(time:utcNow()),
            "version": "1.5.0",
            "resources_count": resources.length()
        };
    }

    // Favicon
    resource function get favicon\.ico() returns http:Response {
        http:Response res = new;
        res.statusCode = 204;
        return res;
    }
}