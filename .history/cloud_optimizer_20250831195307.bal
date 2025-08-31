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
<title>CloudOptimizer Pro - Dashboard</title>
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
<style>
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body { 
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #9b59b6 100%);
    min-height: 100vh;
    color: #333;
    line-height: 1.6;
    padding: 20px;
}

.container { 
    max-width: 1200px; 
    margin: 0 auto;
}

.header {
    text-align: center;
    margin-bottom: 30px;
    padding: 30px 0;
}

.header h1 {
    color: white;
    font-size: 3rem;
    font-weight: 700;
    margin-bottom: 10px;
    text-shadow: 0 2px 20px rgba(0,0,0,0.3);
}

.header p {
    color: rgba(255,255,255,0.9);
    font-size: 1.2rem;
    font-weight: 300;
}

.main-card { 
    background: rgba(255, 255, 255, 0.95);
    border-radius: 24px;
    padding: 40px;
    margin-bottom: 20px;
    backdrop-filter: blur(20px);
    box-shadow: 0 25px 60px rgba(0,0,0,0.15);
    border: 1px solid rgba(255,255,255,0.2);
}

.back-btn { 
    background: linear-gradient(135deg, #8b7cf8, #9b59b6);
    color: white;
    padding: 12px 24px;
    text-decoration: none;
    border-radius: 12px;
    display: inline-flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 20px;
    transition: all 0.3s ease;
    font-weight: 500;
    box-shadow: 0 4px 15px rgba(139, 124, 248, 0.3);
}

.back-btn:hover { 
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(139, 124, 248, 0.4);
}

.dashboard-title {
    text-align: center;
    margin-bottom: 30px;
}

.dashboard-title h1 {
    color: #5a4fcf;
    font-size: 2.5rem;
    font-weight: 700;
    margin-bottom: 10px;
}

.dashboard-title .subtitle {
    color: #8e9aaf;
    font-size: 1.1rem;
}

.input-summary { 
    background: linear-gradient(135deg, #f8f9ff, #f0f2ff);
    padding: 25px;
    border-radius: 16px;
    margin-bottom: 30px;
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 20px;
    border: 1px solid rgba(139, 124, 248, 0.1);
}

.input-item { 
    text-align: center;
    padding: 15px;
    background: white;
    border-radius: 12px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.05);
}

.input-label { 
    font-size: 0.9rem;
    color: #8e9aaf;
    margin-bottom: 8px;
    font-weight: 500;
}

.input-value { 
    font-size: 1.4rem;
    font-weight: 700;
    color: #5a4fcf;
}

.metrics { 
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 25px;
    margin: 30px 0;
}

.metric { 
    background: linear-gradient(135deg, #8b7cf8, #9b59b6);
    color: white;
    padding: 30px;
    border-radius: 18px;
    text-align: center;
    box-shadow: 0 10px 30px rgba(139, 124, 248, 0.3);
    transition: all 0.3s ease;
    border: 1px solid rgba(255,255,255,0.1);
}

.metric:hover {
    transform: translateY(-5px);
    box-shadow: 0 15px 40px rgba(139, 124, 248, 0.4);
}

.metric-value { 
    font-size: 2.5rem;
    font-weight: 700;
    margin-bottom: 8px;
    text-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.metric-label { 
    font-size: 1rem;
    opacity: 0.9;
    font-weight: 500;
}

.nav-buttons { 
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 20px;
    margin-top: 30px;
}

.nav-btn { 
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    padding: 20px;
    background: linear-gradient(135deg, #5a4fcf, #6c63ff);
    color: white;
    text-decoration: none;
    border-radius: 15px;
    text-align: center;
    transition: all 0.3s ease;
    font-weight: 600;
    font-size: 1.1rem;
    box-shadow: 0 8px 25px rgba(90, 79, 207, 0.3);
}

.nav-btn:hover { 
    transform: translateY(-3px);
    box-shadow: 0 12px 35px rgba(90, 79, 207, 0.4);
    background: linear-gradient(135deg, #4a3fb8, #5b52e6);
}

@media (max-width: 768px) {
    body { padding: 15px; }
    
    .header h1 { font-size: 2.2rem; }
    
    .main-card { padding: 25px; }
    
    .input-summary {
        grid-template-columns: 1fr;
        gap: 15px;
    }
    
    .metrics {
        grid-template-columns: 1fr;
        gap: 15px;
    }
    
    .nav-buttons {
        grid-template-columns: 1fr;
        gap: 15px;
    }
}
</style>
</head>
<body>
<div class="container">
    <div class="header">
        <h1><i class="fas fa-cloud"></i> CloudOptimizer Pro</h1>
        <p>Smart Cloud Cost Management Dashboard</p>
    </div>

    <div class="main-card">
        <a href="http://localhost:8080/" class="back-btn">
            <i class="fas fa-arrow-left"></i>
            Back to Landing Page
        </a>
        
        <div class="dashboard-title">
            <h1><i class="fas fa-chart-line"></i> Cost Analysis Results</h1>
            <p class="subtitle">Your cloud infrastructure overview and optimization insights</p>
        </div>
        
        <div class="input-summary">
            <div class="input-item">
                <div class="input-label"><i class="fas fa-cloud"></i> Provider</div>
                <div class="input-value">${provider}</div>
            </div>
            <div class="input-item">
                <div class="input-label"><i class="fas fa-server"></i> VM Hours</div>
                <div class="input-value">${vmHours}</div>
            </div>
            <div class="input-item">
                <div class="input-label"><i class="fas fa-database"></i> Storage (GB)</div>
                <div class="input-value">${storage}</div>
            </div>
            <div class="input-item">
                <div class="input-label"><i class="fas fa-network-wired"></i> Network (GB)</div>
                <div class="input-value">${network}</div>
            </div>
        </div>
        
        <div class="metrics">
            <div class="metric">
                <div class="metric-value"><i class="fas fa-dollar-sign"></i>${totalCost.toString()}</div>
                <div class="metric-label">Monthly Cost</div>
            </div>
            <div class="metric">
                <div class="metric-value"><i class="fas fa-piggy-bank"></i>${totalSavings.toString()}</div>
                <div class="metric-label">Potential Savings</div>
            </div>
            <div class="metric">
                <div class="metric-value"><i class="fas fa-cubes"></i>${resources.length()}</div>
                <div class="metric-label">Resources Analyzed</div>
            </div>
        </div>
        
        <div class="nav-buttons">
            <a href="/ai-suggestions?provider=${provider}&vm=${vmHours}&storage=${storage}&network=${network}" class="nav-btn">
                <i class="fas fa-brain"></i>
                AI Optimization Suggestions
            </a>
            <a href="/report?provider=${provider}&vm=${vmHours}&storage=${storage}&network=${network}" class="nav-btn">
                <i class="fas fa-file-alt"></i>
                Detailed Cost Report
            </a>
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
<title>AI Suggestions - CloudOptimizer Pro</title>
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
<style>
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body { 
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #9b59b6 100%);
    min-height: 100vh;
    color: #333;
    line-height: 1.6;
    padding: 20px;
}

.container { 
    max-width: 1000px; 
    margin: 0 auto;
}

.header { 
    background: rgba(255, 255, 255, 0.95);
    border-radius: 24px;
    padding: 40px;
    margin-bottom: 25px;
    text-align: center;
    backdrop-filter: blur(20px);
    box-shadow: 0 25px 60px rgba(0,0,0,0.15);
    border: 1px solid rgba(255,255,255,0.2);
}

.header h2 { 
    color: #5a4fcf;
    font-size: 2.5rem;
    font-weight: 700;
    margin-bottom: 15px;
}

.header p {
    color: #8e9aaf;
    font-size: 1.2rem;
    font-weight: 300;
    margin-bottom: 20px;
}

.input-info { 
    background: linear-gradient(135deg, #f8f9ff, #f0f2ff);
    padding: 15px 25px;
    border-radius: 12px;
    font-size: 1rem;
    color: #6c63ff;
    text-align: center;
    font-weight: 500;
    border: 1px solid rgba(139, 124, 248, 0.2);
}

.suggestion { 
    background: rgba(255, 255, 255, 0.95);
    border-radius: 18px;
    padding: 25px;
    margin-bottom: 20px;
    backdrop-filter: blur(20px);
    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
    border: 1px solid rgba(255,255,255,0.2);
    transition: all 0.3s ease;
}

.suggestion:hover {
    transform: translateY(-3px);
    box-shadow: 0 15px 40px rgba(0,0,0,0.15);
}

.suggestion.high-savings { 
    border-left: 5px solid #e74c3c;
    background: linear-gradient(135deg, rgba(231, 76, 60, 0.05), rgba(255,255,255,0.95));
}

.suggestion.medium-savings { 
    border-left: 5px solid #f39c12;
    background: linear-gradient(135deg, rgba(243, 156, 18, 0.05), rgba(255,255,255,0.95));
}

.suggestion.optimal { 
    border-left: 5px solid #27ae60;
    background: linear-gradient(135deg, rgba(39, 174, 96, 0.05), rgba(255,255,255,0.95));
}

.suggestion-header { 
    display: flex; 
    justify-content: space-between; 
    align-items: center;
    margin-bottom: 15px;
    flex-wrap: wrap;
    gap: 10px;
}

.resource-name { 
    font-size: 1.3rem; 
    font-weight: 700; 
    color: #ffffffff;
    display: flex;
    align-items: center;
    gap: 10px;
}

.confidence { 
    padding: 8px 16px; 
    border-radius: 20px; 
    font-size: 0.9rem; 
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.conf-High { 
    background: linear-gradient(135deg, #d5f4e6, #a7e6d7); 
    color: #27ae60;
    border: 1px solid #27ae60;
}

.conf-Medium { 
    background: linear-gradient(135deg, #fef9e7, #fdeaa7); 
    color: #f39c12;
    border: 1px solid #f39c12;
}

.conf-Low { 
    background: linear-gradient(135deg, #fadbd8, #f5b7b1); 
    color: #e74c3c;
    border: 1px solid #e74c3c;
}

.recommendation-text {
    font-size: 1.1rem;
    color: #2c3e50;
    margin-bottom: 15px;
    line-height: 1.6;
}

.savings-amount { 
    background: linear-gradient(135deg, #27ae60, #2ecc71);
    color: white; 
    padding: 12px 20px;
    border-radius: 12px; 
    display: inline-flex;
    align-items: center;
    gap: 8px;
    margin: 15px 0;
    font-weight: 600;
    font-size: 1.1rem;
    box-shadow: 0 4px 15px rgba(39, 174, 96, 0.3);
}

.actions { 
    margin-top: 20px;
}

.actions-label {
    font-weight: 600;
    color: #5a4fcf;
    margin-bottom: 10px;
    font-size: 1.1rem;
}

.action { 
    background: linear-gradient(135deg, #f8f9ff, #f0f2ff);
    padding: 8px 16px;
    border-radius: 20px;
    margin: 5px 8px 5px 0;
    display: inline-block;
    font-size: 0.9rem;
    color: #6c63ff;
    border: 1px solid rgba(139, 124, 248, 0.2);
    transition: all 0.3s ease;
}

.action:hover {
    background: linear-gradient(135deg, #8b7cf8, #9b59b6);
    color: white;
    transform: translateY(-1px);
}

.back-link { 
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    background: linear-gradient(135deg, #8b7cf8, #9b59b6);
    color: white;
    padding: 18px 35px;
    border-radius: 15px;
    text-decoration: none;
    text-align: center;
    margin-top: 30px;
    font-weight: 600;
    font-size: 1.1rem;
    box-shadow: 0 8px 25px rgba(139, 124, 248, 0.3);
    transition: all 0.3s ease;
}

.back-link:hover { 
    transform: translateY(-3px);
    box-shadow: 0 12px 35px rgba(139, 124, 248, 0.4);
}

@media (max-width: 768px) {
    body { padding: 15px; }
    
    .header { padding: 25px; }
    
    .header h2 { font-size: 2rem; }
    
    .suggestion { padding: 20px; }
    
    .suggestion-header {
        flex-direction: column;
        align-items: flex-start;
    }
    
    .resource-name { font-size: 1.1rem; }
}
</style>
</head>
<body>
<div class="container">
    <div class="header">
        <h2><i class="fas fa-brain"></i> AI Optimization Suggestions</h2>
        <p>Smart recommendations to optimize your cloud infrastructure</p>
        <div class="input-info">
            <i class="fas fa-info-circle"></i>
            Analysis based on: ${provider} | VM: ${vmHours}h | Storage: ${storage}GB | Network: ${network}GB
        </div>
    </div>`;

        foreach var suggestion in suggestions {
            string cardClass = suggestion.potentialSavings > 50.0 ? "high-savings" : 
                              suggestion.potentialSavings > 0.0 ? "medium-savings" : "optimal";
            
            string resourceIcon = suggestion.resourceId.includes("vm") ? "fas fa-server" : 
                                 suggestion.resourceId.includes("storage") ? "fas fa-database" : 
                                 "fas fa-network-wired";
            
            html += string `
    <div class="suggestion ${cardClass}">
        <div class="suggestion-header">
            <div class="resource-name">
                <i class="${resourceIcon}"></i>
                ${suggestion.resourceId}
            </div>
            <div class="confidence conf-${suggestion.confidence}">${suggestion.confidence}</div>
        </div>
        <div class="recommendation-text">${suggestion.recommendation}</div>`;
        
        if suggestion.potentialSavings > 0.0 {
            html += string `<div class="savings-amount">
                <i class="fas fa-piggy-bank"></i>
                Save ${suggestion.potentialSavings.toString()}/month
            </div>`;
        }
        
        html += string `<div class="actions">
            <div class="actions-label">
                <i class="fas fa-tasks"></i> Recommended Actions:
            </div>`;
        
        foreach var action in suggestion.actions {
            html += string `<span class="action">${action}</span>`;
        }
        
        html += string `</div></div>`;
        }

        html += string `
    <a href="/?provider=${provider}&vm=${vmHours}&storage=${storage}&network=${network}" class="back-link">
        <i class="fas fa-arrow-left"></i>
        Back to Dashboard
    </a>
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
<title>Cost Report - CloudOptimizer Pro</title>
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
<style>
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body { 
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #9b59b6 100%);
    min-height: 100vh;
    color: #333;
    line-height: 1.6;
    padding: 20px;
}

.container { 
    max-width: 1000px; 
    margin: 0 auto;
}

.main-card { 
    background: rgba(255, 255, 255, 0.95);
    border-radius: 24px;
    padding: 40px;
    backdrop-filter: blur(20px);
    box-shadow: 0 25px 60px rgba(0,0,0,0.15);
    border: 1px solid rgba(255,255,255,0.2);
}

.header {
    text-align: center;
    margin-bottom: 30px;
}

.header h2 { 
    color: #5a4fcf;
    font-size: 2.5rem;
    font-weight: 700;
    margin-bottom: 15px;
}

.header p {
    color: #8e9aaf;
    font-size: 1.2rem;
    font-weight: 300;
}

.input-info { 
    background: linear-gradient(135deg, #f8f9ff, #f0f2ff);
    padding: 20px 25px;
    border-radius: 12px;
    margin-bottom: 30px;
    text-align: center;
    color: #6c63ff;
    font-weight: 500;
    border: 1px solid rgba(139, 124, 248, 0.2);
}

.resource-table { 
    width: 100%; 
    border-collapse: collapse; 
    margin: 25px 0;
    border-radius: 15px; 
    overflow: hidden;
    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
}

.resource-table th { 
    background: linear-gradient(135deg, #8b7cf8, #9b59b6);
    color: white; 
    padding: 20px 15px; 
    text-align: left;
    font-weight: 600;
    font-size: 1rem;
}

.resource-table td { 
    padding: 18px 15px; 
    border-bottom: 1px solid rgba(139, 124, 248, 0.1);
    background: white;
}

.resource-table tr:nth-child(even) td { 
    background: rgba(139, 124, 248, 0.02);
}

.resource-table tr:hover td { 
    background: rgba(139, 124, 248, 0.05);
    transform: scale(1.01);
    transition: all 0.3s ease;
}

.resource-name {
    font-weight: 600;
    color: #5a4fcf;
    margin-bottom: 5px;
}

.resource-id {
    font-size: 0.85rem;
    color: #8e9aaf;
}

.resource-type {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 6px 12px;
    background: linear-gradient(135deg, #f8f9ff, #f0f2ff);
    border-radius: 20px;
    font-size: 0.9rem;
    font-weight: 500;
    color: #6c63ff;
    border: 1px solid rgba(139, 124, 248, 0.2);
}

.usage-bar {
    width: 100px;
    height: 8px;
    background: #f0f2ff;
    border-radius: 4px;
    overflow: hidden;
    margin: 5px 0;
}

.usage-fill {
    height: 100%;
    background: linear-gradient(135deg, #8b7cf8, #9b59b6);
    border-radius: 4px;
    transition: width 0.3s ease;
}

.cost-amount {
    font-weight: 700;
    font-size: 1.1rem;
    color: #5a4fcf;
}

.timestamp {
    text-align: center;
    color: #8e9aaf;
    margin-top: 25px;
    padding-top: 20px;
    border-top: 1px solid rgba(139, 124, 248, 0.1);
    font-style: italic;
}

.back-link { 
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    background: linear-gradient(135deg, #8b7cf8, #9b59b6);
    color: white;
    padding: 18px 35px;
    border-radius: 15px;
    text-decoration: none;
    text-align: center;
    margin-top: 30px;
    font-weight: 600;
    font-size: 1.1rem;
    box-shadow: 0 8px 25px rgba(139, 124, 248, 0.3);
    transition: all 0.3s ease;
}

.back-link:hover { 
    transform: translateY(-3px);
    box-shadow: 0 12px 35px rgba(139, 124, 248, 0.4);
}

@media (max-width: 768px) {
    body { padding: 15px; }
    
    .main-card { padding: 25px; }
    
    .header h2 { font-size: 2rem; }
    
    .resource-table {
        font-size: 0.9rem;
    }
    
    .resource-table th,
    .resource-table td {
        padding: 12px 10px;
    }
}
</style>
</head>
<body>
<div class="container">
    <div class="main-card">
        <div class="header">
            <h2><i class="fas fa-file-alt"></i> Detailed Cost Report</h2>
            <p>Comprehensive analysis of your cloud resources and utilization</p>
        </div>
        
        <div class="input-info">
            <i class="fas fa-info-circle"></i>
            <strong>Configuration:</strong> ${provider} | VM Hours: ${vmHours} | Storage: ${storage}GB | Network: ${network}GB
        </div>
        
        <table class="resource-table">
            <thead>
                <tr>
                    <th><i class="fas fa-cube"></i> Resource</th>
                    <th><i class="fas fa-tag"></i> Type</th>
                    <th><i class="fas fa-microchip"></i> CPU Usage</th>
                    <th><i class="fas fa-memory"></i> Memory Usage</th>
                    <th><i class="fas fa-database"></i> Storage Usage</th>
                    <th><i class="fas fa-dollar-sign"></i> Monthly Cost</th>
                </tr>
            </thead>
            <tbody>`;

        foreach var r in resources {
            string resourceIcon = r.resourceType == "VM" ? "fas fa-server" : 
                                 r.resourceType == "Storage" ? "fas fa-database" : 
                                 "fas fa-network-wired";
            
            html += string `
                <tr>
                    <td>
                        <div class="resource-name">
                            <i class="${resourceIcon}"></i>
                            ${r.name}
                        </div>
                        <div class="resource-id">${r.id}</div>
                    </td>
                    <td>
                        <div class="resource-type">
                            <i class="${resourceIcon}"></i>
                            ${r.resourceType}
                        </div>
                    </td>
                    <td>`;
            
            if r.cpuUsage > 0.0 {
                html += string `
                        <div>${r.cpuUsage.toString()}%</div>
                        <div class="usage-bar">
                            <div class="usage-fill" style="width: ${r.cpuUsage.toString()}%"></div>
                        </div>`;
            } else {
                html += string `<span style="color: #8e9aaf;">N/A</span>`;
            }
            
            html += string `</td>
                    <td>`;
            
            if r.memoryUsage > 0.0 {
                html += string `
                        <div>${r.memoryUsage.toString()}%</div>
                        <div class="usage-bar">
                            <div class="usage-fill" style="width: ${r.memoryUsage.toString()}%"></div>
                        </div>`;
            } else {
                html += string `<span style="color: #8e9aaf;">N/A</span>`;
            }
            
            html += string `</td>
                    <td>`;
            
            if r.storageUsage > 0.0 {
                html += string `
                        <div>${r.storageUsage.toString()}%</div>
                        <div class="usage-bar">
                            <div class="usage-fill" style="width: ${r.storageUsage.toString()}%"></div>
                        </div>`;
            } else {
                html += string `<span style="color: #8e9aaf;">N/A</span>`;
            }
            
            html += string `</td>
                    <td><div class="cost-amount">${r.costPerMonth.toString()}</div></td>
                </tr>`;
        }

        html += string `
            </tbody>
        </table>
        
        <div class="timestamp">
            <i class="fas fa-clock"></i>
            Report generated: ${time:utcToString(time:utcNow())}
        </div>
    </div>
    
    <a href="/?provider=${provider}&vm=${vmHours}&storage=${storage}&network=${network}" class="back-link">
        <i class="fas fa-arrow-left"></i>
        Back to Dashboard
    </a>
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
