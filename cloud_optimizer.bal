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
        return {"vm": 0.042, "storage": 0.015, "network": 0.016};
    } else if provider == "Google" {
        return {"vm": 0.048, "storage": 0.008, "network": 0.025};
    } else if provider == "GCP" {
        return {"vm": 0.048, "storage": 0.008, "network": 0.025};
    }
    return {"vm": 0.05, "storage": 0.01, "network": 0.02};
}

// Generate dynamic resources based on calculator inputs
function generateResourcesFromInputs(string provider, float vmHours, float storage, float network) returns CloudResource[] {
    map<float> rates = getPricing(provider);
    float vmRate = rates["vm"] ?: 0.05;
    float storageRate = rates["storage"] ?: 0.01;
    float networkRate = rates["network"] ?: 0.02;
    
    float vmCost = vmHours * vmRate;
    float storageCost = storage * storageRate;
    float networkCost = network * networkRate;
    
    // Simulate CPU/Memory usage based on VM hours (more hours = higher usage)
    float simulatedCpuUsage = vmHours > 500.0 ? 85.0 : (vmHours > 200.0 ? 45.0 : 15.0);
    float simulatedMemoryUsage = vmHours > 500.0 ? 78.0 : (vmHours > 200.0 ? 52.0 : 25.0);
    
    CloudResource[] resources = [];
    
    // VM Resource
    if vmHours > 0.0 {
        resources.push({
            id: provider + "-vm-001",
            name: provider + " VM Instance",
            resourceType: "VM",
            cpuUsage: simulatedCpuUsage,
            memoryUsage: simulatedMemoryUsage,
            storageUsage: 0.0,
            costPerMonth: vmCost
        });
    }
    
    // Storage Resource
    if storage > 0.0 {
        float storageUtilization = storage > 200.0 ? 85.0 : (storage > 50.0 ? 60.0 : 35.0);
        resources.push({
            id: provider + "-storage-001",
            name: provider + " Storage Bucket",
            resourceType: "Storage",
            cpuUsage: 0.0,
            memoryUsage: 0.0,
            storageUsage: storageUtilization,
            costPerMonth: storageCost
        });
    }
    
    // Network Resource
    if network > 0.0 {
        resources.push({
            id: provider + "-network-001",
            name: provider + " Data Transfer",
            resourceType: "Network",
            cpuUsage: 0.0,
            memoryUsage: 0.0,
            storageUsage: 0.0,
            costPerMonth: networkCost
        });
    }
    
    return resources;
}

function analyzeResource(CloudResource res) returns AISuggestion {
    string recommendation;
    string confidence;
    float savings = 0.0;
    string[] actions = [];

    if res.resourceType == "VM" {
        if res.cpuUsage < 10.0 {
            recommendation = "VM severely underutilized - consider downsizing or spot instances";
            confidence = "High";
            savings = res.costPerMonth * 0.7;
            actions = ["Downsize to smaller instance", "Use spot instances", "Consider serverless"];
        } else if res.cpuUsage < 30.0 {
            recommendation = "VM underutilized - optimization opportunity available";
            confidence = "High";
            savings = res.costPerMonth * 0.4;
            actions = ["Right-size instance", "Use reserved instances"];
        } else if res.cpuUsage < 60.0 {
            recommendation = "VM moderately utilized - minor optimization possible";
            confidence = "Medium";
            savings = res.costPerMonth * 0.15;
            actions = ["Monitor usage patterns", "Consider reserved pricing"];
        } else if res.cpuUsage > 80.0 {
            recommendation = "VM highly utilized - consider scaling for performance";
            confidence = "High";
            savings = 0.0;
            actions = ["Add auto-scaling", "Distribute load", "Monitor performance"];
        } else {
            recommendation = "VM optimally utilized";
            confidence = "Low";
            savings = 0.0;
            actions = ["Continue monitoring"];
        }
    } else if res.resourceType == "Storage" {
        if res.storageUsage > 90.0 {
            recommendation = "Storage nearly full - immediate action needed";
            confidence = "High";
            savings = 0.0;
            actions = ["Archive old data", "Implement lifecycle policies", "Add capacity"];
        } else if res.storageUsage < 40.0 {
            recommendation = "Storage underutilized - consider cheaper tiers";
            confidence = "Medium";
            savings = res.costPerMonth * 0.3;
            actions = ["Move to infrequent access tier", "Clean unused data", "Compress files"];
        } else if res.storageUsage > 70.0 {
            recommendation = "Storage well utilized - monitor growth";
            confidence = "Low";
            savings = res.costPerMonth * 0.1;
            actions = ["Set up monitoring alerts", "Plan capacity"];
        } else {
            recommendation = "Storage appropriately utilized";
            confidence = "Low";
            savings = 0.0;
            actions = ["Continue monitoring"];
        }
    } else if res.resourceType == "Network" {
        if res.costPerMonth > 50.0 {
            recommendation = "High network costs - optimize data transfer";
            confidence = "Medium";
            savings = res.costPerMonth * 0.25;
            actions = ["Use CDN", "Compress data", "Cache frequently accessed content"];
        } else if res.costPerMonth > 20.0 {
            recommendation = "Moderate network usage - minor optimizations available";
            confidence = "Low";
            savings = res.costPerMonth * 0.1;
            actions = ["Review data transfer patterns", "Optimize API calls"];
        } else {
            recommendation = "Network usage is cost-effective";
            confidence = "Low";
            savings = 0.0;
            actions = ["Continue monitoring"];
        }
    } else {
        recommendation = "Manual review recommended";
        confidence = "Low";
        savings = 0.0;
        actions = ["Manual analysis required"];
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

    resource function get .(http:Request req) returns http:Response {
        // Get parameters from URL
        map<string[]> params = req.getQueryParams();
        
        string provider = "AWS";
        float vmHours = 744.0;
        float storage = 100.0;
        float network = 50.0;
        
        // Extract parameters
        string[]? providerParam = params["provider"];
        if providerParam is string[] && providerParam.length() > 0 {
            provider = providerParam[0];
        }
        
        string[]? vmParam = params["vm"];
        if vmParam is string[] && vmParam.length() > 0 {
            float|error vmResult = float:fromString(vmParam[0]);
            if vmResult is float {
                vmHours = vmResult;
            }
        }
        
        string[]? storageParam = params["storage"];
        if storageParam is string[] && storageParam.length() > 0 {
            float|error storageResult = float:fromString(storageParam[0]);
            if storageResult is float {
                storage = storageResult;
            }
        }
        
        string[]? networkParam = params["network"];
        if networkParam is string[] && networkParam.length() > 0 {
            float|error networkResult = float:fromString(networkParam[0]);
            if networkResult is float {
                network = networkResult;
            }
        }

        // Generate resources based on actual inputs
        CloudResource[] resources = generateResourcesFromInputs(provider, vmHours, storage, network);
        
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
.input-summary { 
    background: #ecf0f1; padding: 15px; border-radius: 10px; margin-bottom: 20px;
    display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px;
}
.input-item { text-align: center; }
.input-label { font-size: 0.9rem; color: #7f8c8d; margin-bottom: 5px; }
.input-value { font-size: 1.2rem; font-weight: bold; color: #2c3e50; }
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
.back-btn { 
    background: #27ae60; color: white; padding: 12px 24px; 
    text-decoration: none; border-radius: 8px; display: inline-block;
    margin-bottom: 20px; transition: all 0.3s ease;
}
.back-btn:hover { background: #219a52; }
</style>
</head>
<body>
<div class="container">
    <div class="card">
        <a href="http://localhost:8080/" class="back-btn">← Back to Home Page</a>
        <h1>CloudOptimizer Pro</h1>
        <p class="subtitle">Smart Cloud Cost Management Dashboard</p>
        
        <div class="input-summary">
            <div class="input-item">
                <div class="input-label">Provider</div>
                <div class="input-value">${provider}</div>
            </div>
            <div class="input-item">
                <div class="input-label">VM Hours</div>
                <div class="input-value">${vmHours}</div>
            </div>
            <div class="input-item">
                <div class="input-label">Storage (GB)</div>
                <div class="input-value">${storage}</div>
            </div>
            <div class="input-item">
                <div class="input-label">Network (GB)</div>
                <div class="input-value">${network}</div>
            </div>
        </div>
        
        <div class="metrics">
            <div class="metric">
                <div class="metric-value">$${totalCost.toString()}</div>
                <div class="metric-label">Monthly Cost</div>
            </div>
            <div class="metric">
                <div class="metric-value">$${totalSavings.toString()}</div>
                <div class="metric-label">Potential Savings</div>
            </div>
            <div class="metric">
                <div class="metric-value">${resources.length()}</div>
                <div class="metric-label">Resources</div>
            </div>
        </div>
        
        <div class="nav-buttons">
            <a href="/ai-suggestions?provider=${provider}&vm=${vmHours}&storage=${storage}&network=${network}" class="nav-btn">AI Suggestions</a>
            <a href="/report?provider=${provider}&vm=${vmHours}&storage=${storage}&network=${network}" class="nav-btn">Cost Report</a>
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

    resource function get ai\-suggestions(http:Request req) returns http:Response {
        // Get parameters from URL
        map<string[]> params = req.getQueryParams();
        
        string provider = "AWS";
        float vmHours = 744.0;
        float storage = 100.0;
        float network = 50.0;
        
        // Extract parameters
        string[]? providerParam = params["provider"];
        if providerParam is string[] && providerParam.length() > 0 {
            provider = providerParam[0];
        }
        
        string[]? vmParam = params["vm"];
        if vmParam is string[] && vmParam.length() > 0 {
            float|error vmResult = float:fromString(vmParam[0]);
            if vmResult is float {
                vmHours = vmResult;
            }
        }
        
        string[]? storageParam = params["storage"];
        if storageParam is string[] && storageParam.length() > 0 {
            float|error storageResult = float:fromString(storageParam[0]);
            if storageResult is float {
                storage = storageResult;
            }
        }
        
        string[]? networkParam = params["network"];
        if networkParam is string[] && networkParam.length() > 0 {
            float|error networkResult = float:fromString(networkParam[0]);
            if networkResult is float {
                network = networkResult;
            }
        }

        // Generate resources and suggestions based on actual inputs
        CloudResource[] resources = generateResourcesFromInputs(provider, vmHours, storage, network);
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
.input-info { 
    background: #ecf0f1; padding: 10px; border-radius: 8px; margin-bottom: 15px;
    font-size: 0.9rem; color: #7f8c8d; text-align: center;
}
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
        <div class="input-info">
            Based on: ${provider} | VM: ${vmHours}h | Storage: ${storage}GB | Network: ${network}GB
        </div>
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
            html += string `<div class="savings-amount">Save $${suggestion.potentialSavings.toString()}/month</div>`;
        }
        
        html += string `<div class="actions">
            <strong>Actions:</strong><br>`;
        
        foreach var action in suggestion.actions {
            html += string `<span class="action">${action}</span>`;
        }
        
        html += string `</div></div>`;
        }

        html += string `
    <a href="/?provider=${provider}&vm=${vmHours}&storage=${storage}&network=${network}" class="back-link">Back to Dashboard</a>
</div>
</body>
</html>`;

        http:Response res = new;
        res.setPayload(html);
        res.setHeader("Content-Type", "text/html");
        return res;
    }

    resource function get report(http:Request req) returns http:Response {
        // Get parameters from URL
        map<string[]> params = req.getQueryParams();
        
        string provider = "AWS";
        float vmHours = 744.0;
        float storage = 100.0;
        float network = 50.0;
        
        // Extract parameters
        string[]? providerParam = params["provider"];
        if providerParam is string[] && providerParam.length() > 0 {
            provider = providerParam[0];
        }
        
        string[]? vmParam = params["vm"];
        if vmParam is string[] && vmParam.length() > 0 {
            float|error vmResult = float:fromString(vmParam[0]);
            if vmResult is float {
                vmHours = vmResult;
            }
        }
        
        string[]? storageParam = params["storage"];
        if storageParam is string[] && storageParam.length() > 0 {
            float|error storageResult = float:fromString(storageParam[0]);
            if storageResult is float {
                storage = storageResult;
            }
        }
        
        string[]? networkParam = params["network"];
        if networkParam is string[] && networkParam.length() > 0 {
            float|error networkResult = float:fromString(networkParam[0]);
            if networkResult is float {
                network = networkResult;
            }
        }

        // Generate resources based on actual inputs
        CloudResource[] resources = generateResourcesFromInputs(provider, vmHours, storage, network);

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
.input-info { 
    background: #ecf0f1; padding: 15px; border-radius: 8px; margin-bottom: 20px;
    text-align: center; color: #7f8c8d;
}
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
        
        <div class="input-info">
            <strong>Configuration:</strong> ${provider} | VM Hours: ${vmHours} | Storage: ${storage}GB | Network: ${network}GB
        </div>
        
        <table class="resource-table">
            <thead>
                <tr>
                    <th>Resource</th>
                    <th>Type</th>
                    <th>CPU %</th>
                    <th>Memory %</th>
                    <th>Storage %</th>
                    <th>Cost/Month</th>
                </tr>
            </thead>
            <tbody>`;

        foreach var r in resources {
            html += string `
                <tr>
                    <td><strong>${r.name}</strong><br><small>${r.id}</small></td>
                    <td>${r.resourceType}</td>
                    <td>${r.cpuUsage > 0.0 ? r.cpuUsage.toString() + "%" : "N/A"}</td>
                    <td>${r.memoryUsage > 0.0 ? r.memoryUsage.toString() + "%" : "N/A"}</td>
                    <td>${r.storageUsage > 0.0 ? r.storageUsage.toString() + "%" : "N/A"}</td>
                    <td>$${r.costPerMonth.toString()}</td>
                </tr>`;
        }

        html += string `
            </tbody>
        </table>
        
        <p style="text-align: center; color: #7f8c8d;">
            Generated: ${time:utcToString(time:utcNow())}
        </p>
    </div>
    
    <a href="/?provider=${provider}&vm=${vmHours}&storage=${storage}&network=${network}" class="back-link">Back to Dashboard</a>
</div>
</body>
</html>`;

        http:Response res = new;
        res.setPayload(html);
        res.setHeader("Content-Type", "text/html");
        return res;
    }

    resource function get resources(http:Request req) returns json {
        // Get parameters from URL
        map<string[]> params = req.getQueryParams();
        
        string provider = "AWS";
        float vmHours = 744.0;
        float storage = 100.0;
        float network = 50.0;
        
        // Extract parameters
        string[]? providerParam = params["provider"];
        if providerParam is string[] && providerParam.length() > 0 {
            provider = providerParam[0];
        }
        
        string[]? vmParam = params["vm"];
        if vmParam is string[] && vmParam.length() > 0 {
            float|error vmResult = float:fromString(vmParam[0]);
            if vmResult is float {
                vmHours = vmResult;
            }
        }
        
        string[]? storageParam = params["storage"];
        if storageParam is string[] && storageParam.length() > 0 {
            float|error storageResult = float:fromString(storageParam[0]);
            if storageResult is float {
                storage = storageResult;
            }
        }
        
        string[]? networkParam = params["network"];
        if networkParam is string[] && networkParam.length() > 0 {
            float|error networkResult = float:fromString(networkParam[0]);
            if networkResult is float {
                network = networkResult;
            }
        }

        // Generate resources based on actual inputs
        CloudResource[] resources = generateResourcesFromInputs(provider, vmHours, storage, network);
        
        AISuggestion[] suggestions = [];
        float totalCost = 0.0;
        float totalSavings = 0.0;
        
        foreach var r in resources {
            totalCost += r.costPerMonth;
            AISuggestion suggestion = analyzeResource(r);
            suggestions.push(suggestion);
            totalSavings += suggestion.potentialSavings;
        }
        
        json resourcesJson = resources.toJson();
        json suggestionsJson = suggestions.toJson();
        
        return {
            "status": "success",
            "timestamp": time:utcToString(time:utcNow()),
            "inputs": {
                "provider": provider,
                "vmHours": vmHours,
                "storage": storage,
                "network": network
            },
            "summary": {
                "totalCost": totalCost,
                "potentialSavings": totalSavings,
                "resourceCount": resources.length()
            },
            "resources": resourcesJson,
            "suggestions": suggestionsJson
        };
    }

    resource function get health() returns json {
        return {
            "status": "healthy",
            "timestamp": time:utcToString(time:utcNow()),
            "version": "1.0.0"
        };
    }

    resource function get favicon\.ico() returns http:Response {
        http:Response res = new;
        res.statusCode = 204;
        return res;
    }
}
