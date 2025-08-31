import ballerina/http;
import ballerina/time;
import ballerina/log;
import ballerina/uuid;
import ballerina/lang.array;
import ballerina/math;

// -------------------------
// Advanced Types & Records
// -------------------------
type CloudProvider "AWS"|"Azure"|"GCP"|"DigitalOcean"|"Linode";

type ResourceType "EC2"|"S3"|"RDS"|"Lambda"|"ELB"|"CloudFront"|"EBS"|"VPC";

type MetricThreshold record {
    float warning;
    float critical;
    string unit;
};

type CloudResource record {|
    string id;
    string name;
    ResourceType resourceType;
    CloudProvider provider;
    string region;
    float cpuUsage;
    float memoryUsage;
    float storageUsage;
    float networkIO;
    float costPerMonth;
    time:Utc lastUpdated;
    string[] tags;
    boolean isProduction;
    MetricThreshold thresholds;
|};

type OptimizationLevel "AGGRESSIVE"|"MODERATE"|"CONSERVATIVE";

type AISuggestion record {|
    string id;
    string resourceId;
    string category;
    string recommendation;
    string reasoning;
    float potentialSavings;
    string confidence;
    OptimizationLevel level;
    string[] actionItems;
    time:Utc generatedAt;
|};

type CostBreakdown record {|
    string provider;
    float compute;
    float storage;
    float network;
    float database;
    float misc;
    float total;
    string currency;
|};

type AlertRule record {|
    string id;
    string name;
    string condition;
    float threshold;
    boolean enabled;
|};

// -------------------------
// Advanced Pricing Engine
// -------------------------
class PricingEngine {
    private map<map<float>> providerRates;
    private map<float> regionMultipliers;

    function init() {
        self.providerRates = {
            "AWS": {"vm": 0.05, "storage": 0.01, "network": 0.02, "database": 0.15, "load_balancer": 0.025},
            "Azure": {"vm": 0.045, "storage": 0.012, "network": 0.018, "database": 0.14, "load_balancer": 0.022},
            "GCP": {"vm": 0.048, "storage": 0.011, "network": 0.019, "database": 0.13, "load_balancer": 0.024},
            "DigitalOcean": {"vm": 0.04, "storage": 0.008, "network": 0.015, "database": 0.12, "load_balancer": 0.02},
            "Linode": {"vm": 0.042, "storage": 0.009, "network": 0.016, "database": 0.125, "load_balancer": 0.021}
        };
        
        self.regionMultipliers = {
            "us-east-1": 1.0, "us-west-2": 1.05, "eu-west-1": 1.08, 
            "ap-southeast-1": 1.12, "ap-northeast-1": 1.15
        };
    }

    function calculateCost(CloudResource resource) returns float {
        map<float> rates = self.providerRates[resource.provider] ?: {"vm": 0.05, "storage": 0.01, "network": 0.02};
        float regionMultiplier = self.regionMultipliers[resource.region] ?: 1.0;
        
        float baseCost = 0.0;
        match resource.resourceType {
            "EC2" => { baseCost = resource.cpuUsage * rates["vm"]; }
            "S3" => { baseCost = resource.storageUsage * rates["storage"]; }
            "RDS" => { baseCost = resource.cpuUsage * rates["database"]; }
            "ELB" => { baseCost = rates["load_balancer"] * 24 * 30; }
            _ => { baseCost = resource.costPerMonth; }
        }
        
        return baseCost * regionMultiplier;
    }
}

// -------------------------
// AI Analytics Engine
// -------------------------
class AIAnalyticsEngine {
    private PricingEngine pricingEngine;

    function init() {
        self.pricingEngine = new PricingEngine();
    }

    function analyzeResource(CloudResource res) returns AISuggestion {
        string suggestionId = uuid:createType1AsString();
        float efficiency = self.calculateEfficiency(res);
        OptimizationLevel level = self.determineOptimizationLevel(res, efficiency);
        
        string category;
        string recommendation;
        string reasoning;
        float potentialSavings = 0.0;
        string confidence;
        string[] actionItems = [];

        if res.resourceType == "EC2" {
            if res.cpuUsage < 5.0 && res.memoryUsage < 20.0 {
                category = "UNDERUTILIZED";
                recommendation = "Critical: Instance severely underutilized";
                reasoning = string `CPU usage at ${res.cpuUsage}% and memory at ${res.memoryUsage}% indicate wasteful spending`;
                potentialSavings = res.costPerMonth * 0.8;
                confidence = "High";
                actionItems = ["Terminate instance", "Migrate to smaller instance type", "Schedule auto-stop"];
            } else if res.cpuUsage < 20.0 {
                category = "OPTIMIZATION";
                recommendation = "Moderate optimization opportunity";
                reasoning = string `CPU usage at ${res.cpuUsage}% suggests right-sizing potential`;
                potentialSavings = res.costPerMonth * 0.4;
                confidence = "Medium";
                actionItems = ["Right-size instance", "Implement auto-scaling"];
            } else if res.cpuUsage > 80.0 {
                category = "SCALING";
                recommendation = "Consider scaling up or load balancing";
                reasoning = string `High CPU usage at ${res.cpuUsage}% may impact performance`;
                potentialSavings = 0.0;
                confidence = "High";
                actionItems = ["Add load balancer", "Scale horizontally", "Upgrade instance"];
            } else {
                category = "OPTIMAL";
                recommendation = "Resource performing within optimal range";
                reasoning = string `CPU usage at ${res.cpuUsage}% indicates good utilization`;
                potentialSavings = 0.0;
                confidence = "Low";
                actionItems = ["Continue monitoring"];
            }
        } else if res.resourceType == "S3" {
            if res.storageUsage > 90.0 {
                category = "CAPACITY";
                recommendation = "Storage nearing capacity limits";
                reasoning = string `Storage at ${res.storageUsage}% capacity`;
                potentialSavings = 0.0;
                confidence = "High";
                actionItems = ["Archive old data", "Implement lifecycle policies"];
            } else if res.storageUsage < 30.0 {
                category = "UNDERUTILIZED";
                recommendation = "Consider storage tier optimization";
                reasoning = string `Low storage usage at ${res.storageUsage}%`;
                potentialSavings = res.costPerMonth * 0.3;
                confidence = "Medium";
                actionItems = ["Move to cheaper storage class", "Implement intelligent tiering"];
            } else {
                category = "OPTIMAL";
                recommendation = "Storage usage is appropriate";
                reasoning = string `Storage at ${res.storageUsage}% is well-utilized`;
                potentialSavings = 0.0;
                confidence = "Low";
                actionItems = ["Continue monitoring"];
            }
        } else {
            category = "UNKNOWN";
            recommendation = "Manual review recommended";
            reasoning = "Insufficient data for automated analysis";
            potentialSavings = 0.0;
            confidence = "Low";
            actionItems = ["Manual assessment needed"];
        }

        return {
            id: suggestionId,
            resourceId: res.id,
            category: category,
            recommendation: recommendation,
            reasoning: reasoning,
            potentialSavings: potentialSavings,
            confidence: confidence,
            level: level,
            actionItems: actionItems,
            generatedAt: time:utcNow()
        };
    }

    private function calculateEfficiency(CloudResource res) returns float {
        if res.resourceType == "EC2" {
            return (res.cpuUsage + res.memoryUsage) / 2.0;
        } else if res.resourceType == "S3" {
            return res.storageUsage;
        }
        return 50.0; // Default efficiency
    }

    private function determineOptimizationLevel(CloudResource res, float efficiency) returns OptimizationLevel {
        if res.isProduction {
            return efficiency < 20.0 ? "MODERATE" : "CONSERVATIVE";
        } else {
            return efficiency < 30.0 ? "AGGRESSIVE" : "MODERATE";
        }
    }

    function generateInsights(CloudResource[] resources) returns map<anydata> {
        float totalCost = 0.0;
        float totalSavings = 0.0;
        int underutilized = 0;
        int optimal = 0;
        
        foreach var res in resources {
            totalCost += res.costPerMonth;
            AISuggestion suggestion = self.analyzeResource(res);
            totalSavings += suggestion.potentialSavings;
            
            if suggestion.category == "UNDERUTILIZED" {
                underutilized += 1;
            } else if suggestion.category == "OPTIMAL" {
                optimal += 1;
            }
        }

        return {
            "totalResources": resources.length(),
            "totalMonthlyCost": totalCost,
            "potentialSavings": totalSavings,
            "savingsPercentage": totalCost > 0 ? (totalSavings / totalCost) * 100 : 0,
            "underutilizedCount": underutilized,
            "optimalCount": optimal,
            "analysisTimestamp": time:utcToString(time:utcNow())
        };
    }
}

// -------------------------
// Enhanced Sample Data
// -------------------------
final CloudResource[] resources = [
    {
        id: "i-12345", name: "web-server-01", resourceType: "EC2", provider: "AWS",
        region: "us-east-1", cpuUsage: 8.5, memoryUsage: 15.2, storageUsage: 30.0,
        networkIO: 2.1, costPerMonth: 120.0, lastUpdated: time:utcNow(),
        tags: ["web", "frontend", "dev"], isProduction: false,
        thresholds: {warning: 70.0, critical: 90.0, unit: "%"}
    },
    {
        id: "i-67890", name: "database-primary", resourceType: "EC2", provider: "AWS",
        region: "us-east-1", cpuUsage: 75.0, memoryUsage: 82.3, storageUsage: 65.0,
        networkIO: 8.5, costPerMonth: 200.0, lastUpdated: time:utcNow(),
        tags: ["database", "mysql", "prod"], isProduction: true,
        thresholds: {warning: 75.0, critical: 85.0, unit: "%"}
    },
    {
        id: "bucket-1", name: "static-assets", resourceType: "S3", provider: "AWS",
        region: "us-east-1", cpuUsage: 0.0, memoryUsage: 0.0, storageUsage: 85.0,
        networkIO: 1.2, costPerMonth: 40.0, lastUpdated: time:utcNow(),
        tags: ["storage", "static", "prod"], isProduction: true,
        thresholds: {warning: 80.0, critical: 95.0, unit: "%"}
    },
    {
        id: "rds-001", name: "analytics-db", resourceType: "RDS", provider: "AWS",
        region: "us-west-2", cpuUsage: 25.0, memoryUsage: 45.0, storageUsage: 40.0,
        networkIO: 3.2, costPerMonth: 180.0, lastUpdated: time:utcNow(),
        tags: ["database", "analytics", "dev"], isProduction: false,
        thresholds: {warning: 70.0, critical: 85.0, unit: "%"}
    }
];

final AlertRule[] alertRules = [
    {id: "rule-1", name: "High CPU Alert", condition: "cpu > 80", threshold: 80.0, enabled: true},
    {id: "rule-2", name: "Storage Full Alert", condition: "storage > 90", threshold: 90.0, enabled: true},
    {id: "rule-3", name: "Cost Spike Alert", condition: "cost_increase > 20", threshold: 20.0, enabled: true}
];

// -------------------------
// Enhanced Service
// -------------------------
service / on new http:Listener(8081) {
    private AIAnalyticsEngine aiEngine;
    private PricingEngine pricingEngine;

    function init() {
        self.aiEngine = new AIAnalyticsEngine();
        self.pricingEngine = new PricingEngine();
        log:printInfo("CloudOptimizer Pro Advanced - Server started on port 8081");
    }

    // Enhanced Homepage with Dashboard
    resource function get .() returns http:Response {
        map<anydata> insights = self.aiEngine.generateInsights(resources);
        
        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>CloudOptimizer Pro - Advanced</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { 
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh; padding: 20px; color: #333;
}
.container { max-width: 1200px; margin: 0 auto; }
.header { 
    background: rgba(255,255,255,0.95); border-radius: 15px; 
    padding: 30px; margin-bottom: 30px; backdrop-filter: blur(10px);
    box-shadow: 0 8px 32px rgba(0,0,0,0.1);
}
h1 { color: #2c3e50; font-size: 2.5rem; margin-bottom: 10px; }
.subtitle { color: #7f8c8d; font-size: 1.2rem; }
.dashboard { 
    display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); 
    gap: 20px; margin-bottom: 30px; 
}
.card { 
    background: rgba(255,255,255,0.95); border-radius: 15px; 
    padding: 25px; backdrop-filter: blur(10px);
    box-shadow: 0 8px 32px rgba(0,0,0,0.1);
    transition: transform 0.3s ease;
}
.card:hover { transform: translateY(-5px); }
.metric-value { font-size: 2rem; font-weight: bold; color: #3498db; }
.metric-label { color: #7f8c8d; margin-top: 5px; }
.nav-section { 
    background: rgba(255,255,255,0.95); border-radius: 15px; 
    padding: 25px; backdrop-filter: blur(10px);
    box-shadow: 0 8px 32px rgba(0,0,0,0.1);
}
.nav-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; }
.nav-link { 
    display: block; padding: 15px 20px; background: linear-gradient(45deg, #3498db, #2980b9);
    color: white; text-decoration: none; border-radius: 10px; text-align: center;
    transition: all 0.3s ease; font-weight: 500;
}
.nav-link:hover { transform: scale(1.05); box-shadow: 0 5px 15px rgba(52,152,219,0.4); }
.savings { color: #27ae60; font-weight: bold; }
.warning { color: #e74c3c; font-weight: bold; }
</style>
</head>
<body>
<div class="container">
    <div class="header">
        <h1>CloudOptimizer Pro</h1>
        <p class="subtitle">Advanced AI-Powered Cloud Cost Management</p>
    </div>
    
    <div class="dashboard">
        <div class="card">
            <div class="metric-value">$${insights["totalMonthlyCost"]}</div>
            <div class="metric-label">Monthly Cost</div>
        </div>
        <div class="card">
            <div class="metric-value savings">$${insights["potentialSavings"]}</div>
            <div class="metric-label">Potential Savings</div>
        </div>
        <div class="card">
            <div class="metric-value">${insights["totalResources"]}</div>
            <div class="metric-label">Total Resources</div>
        </div>
        <div class="card">
            <div class="metric-value ${<float>insights["savingsPercentage"] > 20 ? "warning" : ""}">
                ${math:round(<float>insights["savingsPercentage"])}%
            </div>
            <div class="metric-label">Savings Opportunity</div>
        </div>
    </div>
    
    <div class="nav-section">
        <h3 style="margin-bottom: 20px; color: #2c3e50;">Navigation</h3>
        <div class="nav-grid">
            <a href="/report" class="nav-link">📊 Cost Reports</a>
            <a href="/ai-suggestions" class="nav-link">🤖 AI Suggestions</a>
            <a href="/resources" class="nav-link">☁️ Resources (JSON)</a>
            <a href="/analytics" class="nav-link">📈 Analytics</a>
            <a href="/alerts" class="nav-link">🚨 Alert Rules</a>
            <a href="/optimization" class="nav-link">⚡ Optimization</a>
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

    // Enhanced AI Suggestions with Advanced Analytics
    resource function get ai\-suggestions() returns http:Response {
        AISuggestion[] suggestions = [];

        foreach var r in resources {
            suggestions.push(self.aiEngine.analyzeResource(r));
        }

        // Sort by potential savings (highest first)
        AISuggestion[] sortedSuggestions = suggestions.sort(array:DESCENDING, 
            suggestion => suggestion.potentialSavings);

        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AI Suggestions - CloudOptimizer Pro</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { 
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh; padding: 20px; color: #333;
}
.container { max-width: 1400px; margin: 0 auto; }
.header { 
    background: rgba(255,255,255,0.95); border-radius: 15px; 
    padding: 25px; margin-bottom: 25px; backdrop-filter: blur(10px);
}
h2 { color: #2c3e50; font-size: 2rem; margin-bottom: 10px; }
.suggestions-grid { display: grid; gap: 20px; }
.suggestion-card { 
    background: rgba(255,255,255,0.95); border-radius: 15px; 
    padding: 25px; backdrop-filter: blur(10px);
    box-shadow: 0 8px 32px rgba(0,0,0,0.1);
    border-left: 5px solid #3498db;
}
.suggestion-card.critical { border-left-color: #e74c3c; }
.suggestion-card.warning { border-left-color: #f39c12; }
.suggestion-card.optimal { border-left-color: #27ae60; }
.card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; }
.resource-info { font-size: 1.1rem; font-weight: bold; color: #2c3e50; }
.confidence-badge { 
    padding: 5px 12px; border-radius: 20px; font-size: 0.9rem; font-weight: bold;
}
.conf-High { background: #d5f4e6; color: #27ae60; }
.conf-Medium { background: #fef9e7; color: #f39c12; }
.conf-Low { background: #fadbd8; color: #e74c3c; }
.recommendation { font-size: 1.1rem; margin-bottom: 10px; }
.reasoning { color: #7f8c8d; margin-bottom: 15px; font-style: italic; }
.savings { font-size: 1.2rem; font-weight: bold; color: #27ae60; margin-bottom: 15px; }
.actions { margin-top: 15px; }
.action-item { 
    display: inline-block; background: #ecf0f1; padding: 5px 10px; 
    border-radius: 15px; margin: 2px; font-size: 0.9rem;
}
.back-link { 
    display: inline-block; background: #3498db; color: white; 
    padding: 12px 25px; border-radius: 25px; text-decoration: none;
    margin-top: 20px; transition: all 0.3s ease;
}
.back-link:hover { background: #2980b9; transform: translateY(-2px); }
</style>
</head>
<body>
<div class="container">
    <div class="header">
        <h2>🤖 AI-Powered Optimization Suggestions</h2>
        <p>Advanced machine learning recommendations for cost optimization</p>
    </div>
    
    <div class="suggestions-grid">`;

        foreach var suggestion in sortedSuggestions {
            string cardClass = suggestion.category == "UNDERUTILIZED" ? "critical" : 
                              suggestion.category == "OPTIMIZATION" ? "warning" : "optimal";
            
            html += string `
        <div class="suggestion-card ${cardClass}">
            <div class="card-header">
                <div class="resource-info">${suggestion.resourceId}</div>
                <div class="confidence-badge conf-${suggestion.confidence}">${suggestion.confidence}</div>
            </div>
            <div class="recommendation">${suggestion.recommendation}</div>
            <div class="reasoning">${suggestion.reasoning}</div>`;
            
            if suggestion.potentialSavings > 0 {
                html += string `<div class="savings">💰 Potential Savings: $${suggestion.potentialSavings}/month</div>`;
            }
            
            html += string `<div class="actions">
                <strong>Action Items:</strong><br>`;
            
            foreach var action in suggestion.actionItems {
                html += string `<span class="action-item">${action}</span>`;
            }
            
            html += string `</div>
        </div>`;
        }

        html += string `
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

    // Advanced Analytics Endpoint
    resource function get analytics() returns http:Response {
        map<anydata> insights = self.aiEngine.generateInsights(resources);
        
        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Analytics - CloudOptimizer Pro</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { 
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh; padding: 20px; color: #333;
}
.container { max-width: 1000px; margin: 0 auto; }
.analytics-card { 
    background: rgba(255,255,255,0.95); border-radius: 15px; 
    padding: 30px; margin-bottom: 25px; backdrop-filter: blur(10px);
    box-shadow: 0 8px 32px rgba(0,0,0,0.1);
}
h2 { color: #2c3e50; margin-bottom: 20px; }
.metrics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; }
.metric-box { 
    background: linear-gradient(45deg, #3498db, #2980b9);
    color: white; padding: 20px; border-radius: 10px; text-align: center;
}
.metric-value { font-size: 2rem; font-weight: bold; margin-bottom: 5px; }
.metric-label { font-size: 0.9rem; opacity: 0.9; }
.chart-placeholder { 
    height: 300px; background: #ecf0f1; border-radius: 10px; 
    display: flex; align-items: center; justify-content: center;
    color: #7f8c8d; font-size: 1.2rem;
}
.back-link { 
    display: inline-block; background: #3498db; color: white; 
    padding: 12px 25px; border-radius: 25px; text-decoration: none;
    transition: all 0.3s ease;
}
.back-link:hover { background: #2980b9; transform: translateY(-2px); }
</style>
</head>
<body>
<div class="container">
    <div class="analytics-card">
        <h2>📈 Cost Analytics Dashboard</h2>
        <div class="metrics-grid">
            <div class="metric-box">
                <div class="metric-value">${insights["totalResources"]}</div>
                <div class="metric-label">Total Resources</div>
            </div>
            <div class="metric-box">
                <div class="metric-value">$${insights["totalMonthlyCost"]}</div>
                <div class="metric-label">Monthly Cost</div>
            </div>
            <div class="metric-box">
                <div class="metric-value">$${insights["potentialSavings"]}</div>
                <div class="metric-label">Potential Savings</div>
            </div>
            <div class="metric-box">
                <div class="metric-value">${math:round(<float>insights["savingsPercentage"])}%</div>
                <div class="metric-label">Optimization Potential</div>
            </div>
        </div>
    </div>
    
    <div class="analytics-card">
        <h3>Resource Utilization Overview</h3>
        <div class="chart-placeholder">
            📊 Interactive charts would be rendered here<br>
            (Integration with Chart.js or D3.js recommended)
        </div>
    </div>
    
    <div class="analytics-card">
        <h3>Performance Insights</h3>
        <p><strong>Underutilized Resources:</strong> ${insights["underutilizedCount"]} resources could be optimized</p>
        <p><strong>Optimal Resources:</strong> ${insights["optimalCount"]} resources are well-utilized</p>
        <p><strong>Last Analysis:</strong> ${insights["analysisTimestamp"]}</p>
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

    // Alert Rules Management
    resource function get alerts() returns http:Response {
        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Alert Rules - CloudOptimizer Pro</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { 
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh; padding: 20px; color: #333;
}
.container { max-width: 1000px; margin: 0 auto; }
.alerts-card { 
    background: rgba(255,255,255,0.95); border-radius: 15px; 
    padding: 30px; margin-bottom: 25px; backdrop-filter: blur(10px);
    box-shadow: 0 8px 32px rgba(0,0,0,0.1);
}
h2 { color: #2c3e50; margin-bottom: 20px; }
.alert-item { 
    background: #f8f9fa; padding: 15px; border-radius: 10px; 
    margin-bottom: 15px; border-left: 4px solid #3498db;
}
.alert-item.enabled { border-left-color: #27ae60; }
.alert-item.disabled { border-left-color: #e74c3c; opacity: 0.7; }
.alert-name { font-weight: bold; font-size: 1.1rem; color: #2c3e50; }
.alert-condition { color: #7f8c8d; margin: 5px 0; }
.alert-threshold { color: #e67e22; font-weight: bold; }
.status-enabled { color: #27ae60; font-weight: bold; }
.status-disabled { color: #e74c3c; font-weight: bold; }
.back-link { 
    display: inline-block; background: #3498db; color: white; 
    padding: 12px 25px; border-radius: 25px; text-decoration: none;
    transition: all 0.3s ease;
}
.back-link:hover { background: #2980b9; transform: translateY(-2px); }
</style>
</head>
<body>
<div class="container">
    <div class="alerts-card">
        <h2>🚨 Alert Rules Configuration</h2>`;

        foreach var rule in alertRules {
            html += string `
        <div class="alert-item ${rule.enabled ? "enabled" : "disabled"}">
            <div class="alert-name">${rule.name}</div>
            <div class="alert-condition">Condition: ${rule.condition}</div>
            <div class="alert-threshold">Threshold: ${rule.threshold}</div>
            <div class="status-${rule.enabled ? "enabled" : "disabled"}">
                Status: ${rule.enabled ? "Active" : "Disabled"}
            </div>
        </div>`;
        }

        html += string `
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

    // Advanced Cost Report with Multi-Provider Support
    resource function get report(http:Request req) returns http:Response|error {
        map<string[]> queryParams = req.getQueryParams();

        string provider = "AWS";
        if queryParams.hasKey("provider") {
            string[]? pArr = queryParams["provider"];
            if pArr is string[] && pArr.length() > 0 {
                provider = pArr[0];
            }
        }

        // Calculate actual costs from resources
        CostBreakdown breakdown = self.calculateAdvancedCosts(provider);

        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Advanced Cost Report - CloudOptimizer Pro</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { 
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh; padding: 20px; color: #333;
}
.container { max-width: 1000px; margin: 0 auto; }
.report-card { 
    background: rgba(255,255,255,0.95); border-radius: 15px; 
    padding: 30px; margin-bottom: 25px; backdrop-filter: blur(10px);
    box-shadow: 0 8px 32px rgba(0,0,0,0.1);
}
h2 { color: #2c3e50; margin-bottom: 20px; }
.cost-table { 
    width: 100%; border-collapse: collapse; margin: 20px 0;
    border-radius: 10px; overflow: hidden; box-shadow: 0 5px 15px rgba(0,0,0,0.1);
}
.cost-table th { 
    background: linear-gradient(45deg, #3498db, #2980b9); 
    color: white; padding: 15px; text-align: left; font-weight: 600;
}
.cost-table td { padding: 12px 15px; border-bottom: 1px solid #ecf0f1; }
.cost-table tr:nth-child(even) { background: #f8f9fa; }
.cost-table tr:hover { background: #e3f2fd; }
.total-row { background: #2c3e50 !important; color: white; font-weight: bold; }
.provider-selector { 
    margin: 20px 0; padding: 15px; background: #f8f9fa; 
    border-radius: 10px; border: 2px solid #ecf0f1;
}
.provider-selector select { 
    padding: 8px 12px; border-radius: 5px; border: 1px solid #bdc3c7;
    font-size: 1rem; margin-left: 10px;
}
.back-link { 
    display: inline-block; background: #3498db; color: white; 
    padding: 12px 25px; border-radius: 25px; text-decoration: none;
    transition: all 0.3s ease;
}
.back-link:hover { background: #2980b9; transform: translateY(-2px); }
</style>
</head>
<body>
<div class="container">
    <div class="report-card">
        <h2>📊 Advanced Cost Breakdown - ${provider}</h2>
        
        <div class="provider-selector">
            <label><strong>Switch Provider:</strong></label>
            <select onchange="window.location.href='/report?provider=' + this.value">
                <option value="AWS" ${provider == "AWS" ? "selected" : ""}>Amazon Web Services</option>
                <option value="Azure" ${provider == "Azure" ? "selected" : ""}>Microsoft Azure</option>
                <option value="GCP" ${provider == "GCP" ? "selected" : ""}>Google Cloud Platform</option>
                <option value="DigitalOcean" ${provider == "DigitalOcean" ? "selected" : ""}>DigitalOcean</option>
                <option value="Linode" ${provider == "Linode" ? "selected" : ""}>Linode</option>
            </select>
        </div>
        
        <table class="cost-table">
            <thead>
                <tr>
                    <th>💻 Service Category</th>
                    <th>📈 Usage Metrics</th>
                    <th>💰 Monthly Cost (${breakdown.currency})</th>
                    <th>📊 Percentage</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><strong>Compute (EC2/VM)</strong></td>
                    <td>Active instances, CPU hours</td>
                    <td>${breakdown.compute}</td>
                    <td>${math:round((breakdown.compute / breakdown.total) * 100)}%</td>
                </tr>
                <tr>
                    <td><strong>Storage (S3/Blob)</strong></td>
                    <td>Data storage, requests</td>
                    <td>${breakdown.storage}</td>
                    <td>${math:round((breakdown.storage / breakdown.total) * 100)}%</td>
                </tr>
                <tr>
                    <td><strong>Network & CDN</strong></td>
                    <td>Data transfer, bandwidth</td>
                    <td>${breakdown.network}</td>
                    <td>${math:round((breakdown.network / breakdown.total) * 100)}%</td>
                </tr>
                <tr>
                    <td><strong>Database Services</strong></td>
                    <td>RDS, managed databases</td>
                    <td>${breakdown.database}</td>
                    <td>${math:round((breakdown.database / breakdown.total) * 100)}%</td>
                </tr>
                <tr>
                    <td><strong>Other Services</strong></td>
                    <td>Load balancers, misc</td>
                    <td>${breakdown.misc}</td>
                    <td>${math:round((breakdown.misc / breakdown.total) * 100)}%</td>
                </tr>
                <tr class="total-row">
                    <td><strong>🎯 TOTAL MONTHLY COST</strong></td>
                    <td><strong>All Services</strong></td>
                    <td><strong>${breakdown.total}</strong></td>
                    <td><strong>100%</strong></td>
                </tr>
            </tbody>
        </table>
        
        <p><strong>📅 Generated:</strong> ${time:utcToString(time:utcNow())}</p>
        <p><strong>🔄 Auto-refresh:</strong> Every 15 minutes</p>
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

    // Optimization Engine Endpoint
    resource function get optimization(http:Request req) returns http:Response {
        map<string[]> queryParams = req.getQueryParams();
        OptimizationLevel level = "MODERATE";
        
        if queryParams.hasKey("level") {
            string[]? levelArr = queryParams["level"];
            if levelArr is string[] && levelArr.length() > 0 {
                match levelArr[0] {
                    "AGGRESSIVE" => { level = "AGGRESSIVE"; }
                    "CONSERVATIVE" => { level = "CONSERVATIVE"; }
                    _ => { level = "MODERATE"; }
                }
            }
        }

        AISuggestion[] suggestions = [];
        foreach var r in resources {
            suggestions.push(self.aiEngine.analyzeResource(r));
        }

        // Filter suggestions by optimization level
        AISuggestion[] filteredSuggestions = suggestions.filter(s => s.level == level || level == "MODERATE");
        float totalPotentialSavings = filteredSuggestions.reduce(
            function(float acc, AISuggestion s) returns float => acc + s.potentialSavings, 0.0);

        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Optimization Engine - CloudOptimizer Pro</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { 
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh; padding: 20px; color: #333;
}
.container { max-width: 1200px; margin: 0 auto; }
.optimization-card { 
    background: rgba(255,255,255,0.95); border-radius: 15px; 
    padding: 30px; margin-bottom: 25px; backdrop-filter: blur(10px);
    box-shadow: 0 8px 32px rgba(0,0,0,0.1);
}
h2 { color: #2c3e50; margin-bottom: 20px; }
.level-selector { 
    display: flex; gap: 15px; margin: 20px 0; justify-content: center;
}
.level-btn { 
    padding: 12px 25px; border: none; border-radius: 25px; 
    font-weight: bold; cursor: pointer; transition: all 0.3s ease;
    text-decoration: none; text-align: center;
}
.level-aggressive { background: #e74c3c; color: white; }
.level-moderate { background: #f39c12; color: white; }
.level-conservative { background: #27ae60; color: white; }
.level-btn:hover { transform: scale(1.05); }
.level-btn.active { box-shadow: 0 0 20px rgba(0,0,0,0.3); }
.savings-summary { 
    background: linear-gradient(45deg, #27ae60, #2ecc71);
    color: white; padding: 20px; border-radius: 10px; margin: 20px 0;
    text-align: center; font-size: 1.2rem;
}
.back-link { 
    display: inline-block; background: #3498db; color: white; 
    padding: 12px 25px; border-radius: 25px; text-decoration: none;
    transition: all 0.3s ease;
}
.back-link:hover { background: #2980b9; transform: translateY(-2px); }
</style>
</head>
<body>
<div class="container">
    <div class="optimization-card">
        <h2>⚡ Advanced Optimization Engine</h2>
        
        <div class="level-selector">
            <a href="/optimization?level=AGGRESSIVE" 
               class="level-btn level-aggressive ${level == "AGGRESSIVE" ? "active" : ""}">
               🔥 Aggressive
            </a>
            <a href="/optimization?level=MODERATE" 
               class="level-btn level-moderate ${level == "MODERATE" ? "active" : ""}">
               ⚖️ Moderate
            </a>
            <a href="/optimization?level=CONSERVATIVE" 
               class="level-btn level-conservative ${level == "CONSERVATIVE" ? "active" : ""}">
               🛡️ Conservative
            </a>
        </div>
        
        <div class="savings-summary">
            💰 Total Potential Savings with ${level} optimization: ${totalPotentialSavings}/month
        </div>
        
        <h3>Optimization Recommendations (${level} Level)</h3>
        <p>Found ${filteredSuggestions.length()} recommendations for ${level.toLowerAscii()} optimization strategy.</p>
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

    // Enhanced JSON API with Filtering and Pagination
    resource function get resources(http:Request req) returns json|error {
        map<string[]> queryParams = req.getQueryParams();
        
        CloudResource[] filteredResources = resources;
        
        // Filter by provider
        if queryParams.hasKey("provider") {
            string[]? providerArr = queryParams["provider"];
            if providerArr is string[] && providerArr.length() > 0 {
                string filterProvider = providerArr[0];
                filteredResources = resources.filter(r => r.provider == filterProvider);
            }
        }
        
        // Filter by resource type
        if queryParams.hasKey("type") {
            string[]? typeArr = queryParams["type"];
            if typeArr is string[] && typeArr.length() > 0 {
                string filterType = typeArr[0];
                filteredResources = filteredResources.filter(r => r.resourceType == filterType);
            }
        }
        
        // Generate suggestions for filtered resources
        AISuggestion[] suggestions = [];
        foreach var r in filteredResources {
            suggestions.push(self.aiEngine.analyzeResource(r));
        }
        
        map<anydata> insights = self.aiEngine.generateInsights(filteredResources);

        return {
            "status": "success",
            "timestamp": time:utcToString(time:utcNow()),
            "metadata": {
                "totalResources": filteredResources.length(),
                "apiVersion": "v2.0",
                "responseTime": "< 100ms"
            },
            "insights": insights,
            "resources": filteredResources,
            "suggestions": suggestions,
            "filters": {
                "provider": queryParams["provider"] ?: [],
                "type": queryParams["type"] ?: []
            }
        };
    }

    // Health Check Endpoint
    resource function get health() returns json {
        return {
            "status": "healthy",
            "timestamp": time:utcToString(time:utcNow()),
            "version": "2.0.0",
            "uptime": "Available",
            "components": {
                "aiEngine": "operational",
                "pricingEngine": "operational",
                "database": "connected"
            }
        };
    }

    // Favicon
    resource function get favicon\.ico() returns http:Response {
        http:Response res = new;
        res.statusCode = 204;
        return res;
    }

    // Helper function for advanced cost calculation
    private function calculateAdvancedCosts(string provider) returns CostBreakdown {
        float compute = 0.0;
        float storage = 0.0;
        float network = 0.0;
        float database = 0.0;
        float misc = 0.0;

        foreach var res in resources {
            if res.provider == provider {
                match res.resourceType {
                    "EC2" => { compute += res.costPerMonth; }
                    "S3" => { storage += res.costPerMonth; }
                    "RDS" => { database += res.costPerMonth; }
                    "ELB" => { misc += res.costPerMonth; }
                    _ => { misc += res.costPerMonth; }
                }
                network += res.networkIO * 5.0; // Estimate network costs
            }
        }

        float total = compute + storage + network + database + misc;

        return {
            provider: provider,
            compute: compute,
            storage: storage,
            network: network,
            database: database,
            misc: misc,
            total: total,
            currency: "USD"
        };
    }
}