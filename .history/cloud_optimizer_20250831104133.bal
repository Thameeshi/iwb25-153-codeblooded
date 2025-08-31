import ballerina/http;
import ballerina/time;

// -------------------------
// Data Types
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

type CostCalculation record {
    string provider;
    float vmHours;
    float storageGB;
    float networkGB;
    float vmCost;
    float storageCost;
    float networkCost;
    float totalCost;
};

// -------------------------
// Utility Functions
// -------------------------
function formatToTwoDecimals(float value) returns string {
    int absCents = <int>(value * 100.0 + (value >= 0.0 ? 0.5 : -0.5));
    int absDollars = absCents / 100;
    int absRemainder = absCents % 100;
    string sign = value < 0.0 ? "-" : "";
    return sign + absDollars.toString() + "." + (absRemainder < 10 ? "0" : "") + absRemainder.toString();
}

// Fixed pricing function (consistent across all components)
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

// Calculate costs for given inputs
function calculateCosts(string provider, float vmHours, float storageGB, float networkGB) returns CostCalculation {
    map<float> rates = getPricing(provider);
    float vmCost = vmHours * (rates["vm"] ?: 0.05);
    float storageCost = storageGB * (rates["storage"] ?: 0.01);
    float networkCost = networkGB * (rates["network"] ?: 0.02);
    float totalCost = vmCost + storageCost + networkCost;
    
    return {
        provider: provider,
        vmHours: vmHours,
        storageGB: storageGB,
        networkGB: networkGB,
        vmCost: vmCost,
        storageCost: storageCost,
        networkCost: networkCost,
        totalCost: totalCost
    };
}

// Find best provider for given requirements
function findBestProvider(float vmHours, float storageGB, float networkGB) returns CostCalculation {
    string[] providers = ["AWS", "Azure", "Google"];
    CostCalculation? bestOption = ();
    
    foreach string provider in providers {
        CostCalculation calc = calculateCosts(provider, vmHours, storageGB, networkGB);
        if bestOption is () || calc.totalCost < bestOption.totalCost {
            bestOption = calc;
        }
    }
    
    return bestOption ?: calculateCosts("AWS", vmHours, storageGB, networkGB);
}

// -------------------------
// Sample Data & AI Analysis
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
// Main Service (Port 8080)
// -------------------------
service / on new http:Listener(8080) {
    final map<json> sessions = {};

    // Homepage with integrated dashboard
    resource function get .() returns http:Response {
        float totalResourceCost = 0.0;
        float totalPotentialSavings = 0.0;
        
        foreach var r in resources {
            totalResourceCost += r.costPerMonth;
            AISuggestion suggestion = analyzeResource(r);
            totalPotentialSavings += suggestion.potentialSavings;
        }

        string html = string `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CloudOptimizer Pro</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://accounts.google.com/gsi/client" async defer></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        
        .header { background: rgba(255,255,255,0.1); backdrop-filter: blur(10px); padding: 1rem 0; border-bottom: 1px solid rgba(255,255,255,0.2); position: relative; z-index: 100; }
        .nav { max-width: 1200px; margin: 0 auto; display: flex; justify-content: space-between; align-items: center; padding: 0 2rem; }
        .logo { display: flex; align-items: center; gap: 0.5rem; color: white; font-size: 1.8rem; font-weight: bold; text-decoration: none; }
        .logo-icon { font-size: 2rem; }
        .logo-text { font-weight: 300; }
        .logo-pro { background: linear-gradient(45deg, #ff6b6b, #ffd93d); -webkit-background-clip: text; -webkit-text-fill-color: transparent; font-weight: 600; }
        .nav-links { display: flex; gap: 2rem; }
        .nav-links a { color: white; text-decoration: none; padding: 0.5rem 1rem; border-radius: 25px; transition: all 0.3s; }
        .nav-links a:hover, .nav-links a.active { background: rgba(255,255,255,0.2); }

        .container { max-width: 1200px; margin: 0 auto; padding: 2rem; position: relative; z-index: 50; }
        .page { display: none; }
        .page.active { display: block; }
        
        .hero { text-align: center; color: white; margin: 4rem 0; }
        .hero h1 { font-size: 3.5rem; margin-bottom: 1rem; font-weight: 300; }
        .hero p { font-size: 1.3rem; opacity: 0.9; margin-bottom: 2rem; }
        .cta-btn { background: #ff6b6b; color: white; padding: 1rem 2rem; border: none; border-radius: 50px; font-size: 1.1rem; cursor: pointer; transition: all 0.3s; text-decoration: none; display: inline-block; }
        .cta-btn:hover { background: #ff5252; transform: translateY(-2px); box-shadow: 0 10px 20px rgba(0,0,0,0.2); }
        
        .dashboard-metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 2rem; margin: 2rem 0; }
        .metric-card { background: rgba(255,255,255,0.1); padding: 2rem; border-radius: 15px; text-align: center; color: white; backdrop-filter: blur(10px); }
        .metric-value { font-size: 2.5rem; font-weight: bold; margin-bottom: 0.5rem; }
        .metric-label { font-size: 1rem; opacity: 0.9; }
        
        .features { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 2rem; margin-top: 4rem; }
        .feature { background: rgba(255,255,255,0.1); padding: 2rem; border-radius: 15px; text-align: center; color: white; }
        .feature-icon { font-size: 3rem; margin-bottom: 1rem; }
        
        .calc-card { background: white; border-radius: 20px; padding: 2rem; box-shadow: 0 20px 40px rgba(0,0,0,0.1); }
        .calc-header { text-align: center; margin-bottom: 2rem; color: #333; }
        .calc-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 3rem; }
        
        .form-group { margin-bottom: 1.5rem; }
        .form-label { display: block; margin-bottom: 0.5rem; font-weight: 600; color: #555; }
        .form-input, .form-select { width: 100%; padding: 0.8rem; border: 2px solid #e1e5e9; border-radius: 10px; font-size: 1rem; transition: border-color 0.3s; }
        .form-input:focus, .form-select:focus { outline: none; border-color: #667eea; }
        
        .results { background: #f8f9fa; padding: 1.5rem; border-radius: 15px; margin-bottom: 1rem; }
        .result-item { display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid #dee2e6; }
        .result-item:last-child { border-bottom: none; font-weight: bold; font-size: 1.2rem; color: #667eea; }
        
        .best-provider { background: #d4edda; color: #155724; padding: 1rem; border-radius: 10px; margin: 1rem 0; text-align: center; font-weight: bold; }
        .chart-container { margin-top: 2rem; height: 300px; }
        .download-btn { background: #28a745; color: white; padding: 0.8rem 1.5rem; border: none; border-radius: 10px; cursor: pointer; margin-top: 1rem; }
        
        .auth-section { margin-left: auto; }
        .user-info { display: flex; align-items: center; gap: 1rem; color: white; }
        .auth-btn { background: rgba(255,255,255,0.2); color: white; border: 1px solid rgba(255,255,255,0.3); padding: 0.5rem 1rem; border-radius: 20px; cursor: pointer; font-size: 0.9rem; }
        .auth-btn:hover { background: rgba(255,255,255,0.3); }
        
        .login-modal { 
            position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; 
            background: rgba(0,0,0,0.9); display: flex; align-items: center; justify-content: center; z-index: 10000;
        }
        .login-content { 
            background: white; padding: 3rem; border-radius: 20px; text-align: center; 
            max-width: 400px; box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        
        .ai-suggestions { margin-top: 2rem; }
        .suggestion-card { background: #f8f9fa; border-left: 4px solid #007bff; padding: 1rem; margin-bottom: 1rem; border-radius: 0 10px 10px 0; }
        .suggestion-card.high-savings { border-left-color: #dc3545; }
        .suggestion-card.medium-savings { border-left-color: #ffc107; }
        .suggestion-card.optimal { border-left-color: #28a745; }
        .suggestion-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem; }
        .confidence-badge { padding: 0.25rem 0.75rem; border-radius: 15px; font-size: 0.8rem; font-weight: bold; }
        .conf-High { background: #d4edda; color: #155724; }
        .conf-Medium { background: #fff3cd; color: #856404; }
        .conf-Low { background: #f8d7da; color: #721c24; }
        .savings-badge { background: #28a745; color: white; padding: 0.5rem 1rem; border-radius: 8px; }
        .actions { margin-top: 0.5rem; }
        .action-tag { background: #e9ecef; padding: 0.25rem 0.5rem; border-radius: 8px; margin: 0.25rem; display: inline-block; font-size: 0.8rem; }
        
        @media (max-width: 768px) {
            .calc-grid { grid-template-columns: 1fr; }
            .hero h1 { font-size: 2.5rem; }
            .nav { flex-direction: column; gap: 1rem; }
            .nav-links { flex-wrap: wrap; justify-content: center; }
            .dashboard-metrics { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div id="loginModal" class="login-modal">
        <div class="login-content">
            <h2>Welcome to CloudOptimizer Pro</h2>
            <p>Please sign in with Google to access the full features</p>
            <div id="g_id_onload"
                 data-client_id="1032851785630-o4f89gqaehhffspn0k5c861r30rvmunf.apps.googleusercontent.com"
                 data-callback="handleGoogleLogin"></div>
            <div class="g_id_signin" data-type="standard" data-size="large"></div>
        </div>
    </div>

    <div class="header">
        <nav class="nav">
            <a href="#" class="logo">
                <span class="logo-icon">☁</span>
                <span class="logo-text">CloudOptimizer</span>
                <span class="logo-pro">Pro</span>
            </a>
            <div class="nav-links">
                <a href="#" onclick="showPage('home')" class="active">Home</a>
                <a href="#" onclick="showPage('calculator')">Calculator</a>
                <a href="#" onclick="showPage('ai-analysis')">AI Analysis</a>
                <a href="#" onclick="showPage('resources')">Resources</a>
                <a href="#" onclick="showPage('about')">About</a>
            </div>
            <div class="auth-section">
                <div id="userInfo" class="user-info" style="display:none;">
                    <span id="userName"></span>
                    <button class="auth-btn" onclick="logout()">Logout</button>
                </div>
            </div>
        </nav>
    </div>

    <div class="container">
        <!-- HOME PAGE WITH DASHBOARD -->
        <div id="home" class="page active">
            <div class="hero">
                <h1>Cloud Cost Optimization Made Simple</h1>
                <p>Compare AWS, Azure & Google Cloud pricing instantly. Get AI-powered optimization suggestions.</p>
                <button class="cta-btn" onclick="showPage('calculator')">Start Optimizing</button>
            </div>
            
            <!-- Dashboard Metrics -->
            <div class="dashboard-metrics">
                <div class="metric-card">
                    <div class="metric-value">$${totalResourceCost}</div>
                    <div class="metric-label">Current Monthly Cost</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">$${totalPotentialSavings}</div>
                    <div class="metric-label">Potential Savings</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${resources.length()}</div>
                    <div class="metric-label">Resources Monitored</div>
                </div>
                <div class="metric-card">
                    <div class="metric-value">${(totalPotentialSavings/totalResourceCost*100).toFixed(1)}%</div>
                    <div class="metric-label">Savings Potential</div>
                </div>
            </div>
            
            <div class="features">
                <div class="feature">
                    <div class="feature-icon">📊</div>
                    <h3>Real-time Analysis</h3>
                    <p>Get instant cost breakdowns across all major cloud providers</p>
                </div>
                <div class="feature">
                    <div class="feature-icon">🤖</div>
                    <h3>AI Optimization</h3>
                    <p>Smart recommendations based on resource usage patterns</p>
                </div>
                <div class="feature">
                    <div class="feature-icon">💰</div>
                    <h3>Cost Optimization</h3>
                    <p>Find the most cost-effective cloud solution for your needs</p>
                </div>
                <div class="feature">
                    <div class="feature-icon">📈</div>
                    <h3>Visual Reports</h3>
                    <p>Beautiful charts and downloadable reports for easy analysis</p>
                </div>
            </div>
        </div>

        <!-- CALCULATOR PAGE -->
        <div id="calculator" class="page">
            <div class="calc-card">
                <div class="calc-header">
                    <h2>Cloud Cost Calculator</h2>
                    <p>Enter your requirements to get instant cost estimates and find the best provider</p>
                </div>
                
                <div class="calc-grid">
                    <div>
                        <div class="form-group">
                            <label class="form-label">Cloud Provider</label>
                            <select id="provider" class="form-select" onchange="calculate()">
                                <option value="AWS">Amazon Web Services</option>
                                <option value="Azure">Microsoft Azure</option>
                                <option value="Google">Google Cloud</option>
                            </select>
                        </div>
                        
                        <div class="form-group">
                            <label class="form-label">VM Hours/Month</label>
                            <input id="vmHours" type="number" class="form-input" value="744" oninput="calculate()">
                        </div>
                        
                        <div class="form-group">
                            <label class="form-label">Storage (GB)</label>
                            <input id="storage" type="number" class="form-input" value="100" oninput="calculate()">
                        </div>
                        
                        <div class="form-group">
                            <label class="form-label">Network Transfer (GB)</label>
                            <input id="network" type="number" class="form-input" value="50" oninput="calculate()">
                        </div>
                        
                        <button class="cta-btn" onclick="findBestOption()" style="width: 100%; margin-top: 1rem;">Find Best Provider</button>
                    </div>

                    <div>
                        <h3>Cost Breakdown</h3>
                        <div class="results">
                            <div class="result-item">
                                <span>VM Cost:</span>
                                <span id="vmCost">$37.20</span>
                            </div>
                            <div class="result-item">
                                <span>Storage Cost:</span>
                                <span id="storageCost">$1.00</span>
                            </div>
                            <div class="result-item">
                                <span>Network Cost:</span>
                                <span id="networkCost">$1.00</span>
                            </div>
                            <div class="result-item">
                                <span>Total:</span>
                                <span id="total">$39.20</span>
                            </div>
                        </div>
                        
                        <div id="bestProviderCard" class="best-provider" style="display: none;">
                            Best Option: <span id="bestProviderText"></span>
                        </div>
                        
                        <div class="chart-container">
                            <canvas id="costChart"></canvas>
                        </div>
                        
                        <button class="download-btn" onclick="downloadReport()">Download Report</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- AI ANALYSIS PAGE -->
        <div id="ai-analysis" class="page">
            <div class="calc-card">
                <div class="calc-header">
                    <h2>AI-Powered Optimization Analysis</h2>
                    <p>Smart recommendations based on your current resource usage</p>
                </div>
                
                <div class="ai-suggestions" id="aiSuggestions">
                    <!-- AI suggestions will be loaded here -->
                </div>
            </div>
        </div>

        <!-- RESOURCES PAGE -->
        <div id="resources" class="page">
            <div class="calc-card">
                <div class="calc-header">
                    <h2>Resource Overview</h2>
                    <p>Current cloud resources and their utilization</p>
                </div>
                
                <div id="resourcesList">
                    <!-- Resources will be loaded here -->
                </div>
            </div>
        </div>

        <!-- ABOUT PAGE -->
        <div id="about" class="page">
            <div class="calc-card">
                <h2>About CloudOptimizer Pro</h2>
                <p style="line-height: 1.8; color: #666; margin-top: 1rem;">
                    CloudOptimizer Pro combines real-time cloud cost calculation with AI-powered optimization 
                    recommendations. Our integrated platform helps businesses make data-driven decisions about 
                    cloud infrastructure costs across AWS, Azure, and Google Cloud.
                </p>
            </div>
        </div>
    </div>

    <script>
        const pricing = {
            AWS: { vm: 0.05, storage: 0.01, network: 0.02 },
            Azure: { vm: 0.045, storage: 0.012, network: 0.018 },
            Google: { vm: 0.048, storage: 0.011, network: 0.019 }
        };

        let chart;
        let isLoggedIn = false;

        window.onload = function() {
            if (sessionStorage && sessionStorage.getItem('googleCredential')) {
                handleLoginSuccess();
            }
            loadAISuggestions();
            loadResources();
        };

        function handleGoogleLogin(response) {
            if (sessionStorage) {
                sessionStorage.setItem('googleCredential', response.credential);
            }
            handleLoginSuccess();
        }

        function handleLoginSuccess() {
            const credential = sessionStorage ? sessionStorage.getItem('googleCredential') : null;
            if (credential) {
                try {
                    const payload = JSON.parse(atob(credential.split('.')[1]));
                    document.getElementById('loginModal').style.display = 'none';
                    document.getElementById('userInfo').style.display = 'flex';
                    document.getElementById('userName').textContent = payload.name;
                    isLoggedIn = true;
                    calculate();
                } catch (e) {
                    console.error('Login error:', e);
                }
            }
        }

        function logout() {
            if (sessionStorage) {
                sessionStorage.removeItem('googleCredential');
            }
            document.getElementById('loginModal').style.display = 'flex';
            document.getElementById('userInfo').style.display = 'none';
            isLoggedIn = false;
            if (typeof google !== 'undefined' && google.accounts && google.accounts.id) {
                google.accounts.id.disableAutoSelect();
            }
        }

        function showPage(pageId) {
            document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
            document.querySelectorAll('.nav-links a').forEach(a => a.classList.remove('active'));
            
            document.getElementById(pageId).classList.add('active');
            if (event && event.target) {
                event.target.classList.add('active');
            }
            
            if (pageId === 'calculator') {
                setTimeout(() => calculate(), 100);
            } else if (pageId === 'ai-analysis') {
                loadAISuggestions();
            } else if (pageId === 'resources') {
                loadResources();
            }
        }

        function calculate() {
            const provider = document.getElementById('provider').value;
            const vmHours = parseFloat(document.getElementById('vmHours').value) || 0;
            const storage = parseFloat(document.getElementById('storage').value) || 0;
            const network = parseFloat(document.getElementById('network').value) || 0;
            
            const rates = pricing[provider];
            const vmCost = vmHours * rates.vm;
            const storageCost = storage * rates.storage;
            const networkCost = network * rates.network;
            const total = vmCost + storageCost + networkCost;
            
            document.getElementById('vmCost').textContent = '$' + vmCost.toFixed(2);
            document.getElementById('storageCost').textContent = '$' + storageCost.toFixed(2);
            document.getElementById('networkCost').textContent = '$' + networkCost.toFixed(2);
            document.getElementById('total').textContent = '$' + total.toFixed(2);
            
            updateChart(vmCost, storageCost, networkCost);
        }

        function findBestOption() {
            const vmHours = parseFloat(document.getElementById('vmHours').value) || 0;
            const storage = parseFloat(document.getElementById('storage').value) || 0;
            const network = parseFloat(document.getElementById('network').value) || 0;
            
            let bestProvider = '';
            let minCost = Number.MAX_VALUE;
            
            Object.keys(pricing).forEach(provider => {
                const rates = pricing[provider];
                const cost = vmHours * rates.vm + storage * rates.storage + network * rates.network;
                if (cost < minCost) {
                    minCost = cost;
                    bestProvider = provider;
                }
            });
            
            // Update UI to show best provider
            document.getElementById('provider').value = bestProvider;
            document.getElementById('bestProviderText').textContent = bestProvider + ' ($' + minCost.toFixed(2) + ')';
            document.getElementById('bestProviderCard').style.display = 'block';
            calculate();
        }

        function updateChart(vm, storage, network) {
            const ctx = document.getElementById('costChart');
            if (!ctx) return;
            
            if (chart) chart.destroy();
            
            if (vm + storage + network > 0) {
                chart = new Chart(ctx, {
                    type: 'doughnut',
                    data: {
                        labels: ['VM', 'Storage', 'Network'],
                        datasets: [{
                            data: [vm, storage, network],
                            backgroundColor: ['#667eea', '#764ba2', '#f093fb'],
                            borderWidth: 0
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: { position: 'bottom' }
                        }
                    }
                });
            }
        }

        function loadAISuggestions() {
            fetch('/api/suggestions')
                .then(response => response.json())
                .then(data => {
                    const container = document.getElementById('aiSuggestions');
                    container.innerHTML = '';
                    
                    data.suggestions.forEach(suggestion => {
                        const cardClass = suggestion.potentialSavings > 50 ? 'high-savings' : 
                                         suggestion.potentialSavings > 0 ? 'medium-savings' : 'optimal';
                        
                        const card = document.createElement('div');
                        card.className = 'suggestion-card ' + cardClass;
                        card.innerHTML = `
                            <div class="suggestion-header">
                                <strong>${suggestion.resourceId}</strong>
                                <span class="confidence-badge conf-${suggestion.confidence}">${suggestion.confidence}</span>
                            </div>
                            <div>${suggestion.recommendation}</div>
                            ${suggestion.potentialSavings > 0 ? 
                                `<div class="savings-badge">Save ${suggestion.potentialSavings.toFixed(2)}/month</div>` : ''}
                            <div class="actions">
                                <strong>Actions:</strong><br>
                                ${suggestion.actions.map(action => `<span class="action-tag">${action}</span>`).join('')}
                            </div>
                        `;
                        container.appendChild(card);
                    });
                })
                .catch(err => console.error('Failed to load AI suggestions:', err));
        }

        function loadResources() {
            fetch('/api/resources')
                .then(response => response.json())
                .then(data => {
                    const container = document.getElementById('resourcesList');
                    container.innerHTML = `
                        <table style="width: 100%; border-collapse: collapse; margin-top: 1rem;">
                            <thead>
                                <tr style="background: #f8f9fa;">
                                    <th style="padding: 1rem; text-align: left; border-bottom: 2px solid #dee2e6;">Resource</th>
                                    <th style="padding: 1rem; text-align: left; border-bottom: 2px solid #dee2e6;">Type</th>
                                    <th style="padding: 1rem; text-align: left; border-bottom: 2px solid #dee2e6;">CPU %</th>
                                    <th style="padding: 1rem; text-align: left; border-bottom: 2px solid #dee2e6;">Memory %</th>
                                    <th style="padding: 1rem; text-align: left; border-bottom: 2px solid #dee2e6;">Cost/Month</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${data.resources.map(r => `
                                    <tr style="border-bottom: 1px solid #dee2e6;">
                                        <td style="padding: 1rem;"><strong>${r.name}</strong><br><small>${r.id}</small></td>
                                        <td style="padding: 1rem;">${r.resourceType}</td>
                                        <td style="padding: 1rem;">${r.cpuUsage}%</td>
                                        <td style="padding: 1rem;">${r.memoryUsage}%</td>
                                        <td style="padding: 1rem;">${r.costPerMonth}</td>
                                    </tr>
                                `).join('')}
                            </tbody>
                        </table>
                    `;
                })
                .catch(err => console.error('Failed to load resources:', err));
        }

        function downloadReport() {
            const provider = document.getElementById('provider').value;
            const vmHours = document.getElementById('vmHours').value;
            const storage = document.getElementById('storage').value;
            const network = document.getElementById('network').value;
            
            window.open(`/api/report?provider=${provider}&vmHours=${vmHours}&storageGB=${storage}&networkGB=${network}`);
        }
    </script>
</body>
</html>`;

        http:Response res = new;
        res.setPayload(html);
        res.setHeader("Content-Type", "text/html");
        return res;
    }

    // API: Get AI suggestions
    resource function get api/suggestions() returns json {
        AISuggestion[] suggestions = [];
        
        foreach var r in resources {
            suggestions.push(analyzeResource(r));
        }
        
        return {
            "status": "success",
            "timestamp": time:utcToString(time:utcNow()),
            "suggestions": suggestions.toJson()
        };
    }

    // API: Get resources data
    resource function get api/resources() returns json {
        float totalCost = 0.0;
        foreach var r in resources {
            totalCost += r.costPerMonth;
        }
        
        return {
            "status": "success",
            "timestamp": time:utcToString(time:utcNow()),
            "summary": {
                "totalCost": totalCost,
                "resourceCount": resources.length()
            },
            "resources": resources.toJson()
        };
    }

    // API: Calculate costs for given parameters
    resource function get api/calculate(http:Request req) returns json {
        map<string[]> params = req.getQueryParams();
        
        string provider = "AWS";
        float vmHours = 0.0;
        float storageGB = 0.0;
        float networkGB = 0.0;
        
        // Parse parameters safely
        string[]? providerParam = params["provider"];
        if providerParam is string[] && providerParam.length() > 0 {
            provider = providerParam[0];
        }
        
        string[]? vmParam = params["vmHours"];
        if vmParam is string[] && vmParam.length() > 0 {
            float|error vmResult = float:fromString(vmParam[0]);
            if vmResult is float {
                vmHours = vmResult;
            }
        }
        
        string[]? storageParam = params["storageGB"];
        if storageParam is string[] && storageParam.length() > 0 {
            float|error storageResult = float:fromString(storageParam[0]);
            if storageResult is float {
                storageGB = storageResult;
            }
        }
        
        string[]? networkParam = params["networkGB"];
        if networkParam is string[] && networkParam.length() > 0 {
            float|error networkResult = float:fromString(networkParam[0]);
            if networkResult is float {
                networkGB = networkResult;
            }
        }
        
        CostCalculation calculation = calculateCosts(provider, vmHours, storageGB, networkGB);
        CostCalculation bestOption = findBestProvider(vmHours, storageGB, networkGB);
        
        // Calculate all providers for comparison
        CostCalculation awsCost = calculateCosts("AWS", vmHours, storageGB, networkGB);
        CostCalculation azureCost = calculateCosts("Azure", vmHours, storageGB, networkGB);
        CostCalculation googleCost = calculateCosts("Google", vmHours, storageGB, networkGB);
        
        return {
            "status": "success",
            "timestamp": time:utcToString(time:utcNow()),
            "selectedProvider": calculation.toJson(),
            "bestProvider": bestOption.toJson(),
            "comparison": {
                "AWS": awsCost.toJson(),
                "Azure": azureCost.toJson(),
                "Google": googleCost.toJson()
            }
        };
    }

    // API: Find best provider
    resource function get api/best\-provider(http:Request req) returns json {
        map<string[]> params = req.getQueryParams();
        
        float vmHours = 0.0;
        float storageGB = 0.0;
        float networkGB = 0.0;
        
        string[]? vmParam = params["vmHours"];
        if vmParam is string[] && vmParam.length() > 0 {
            float|error vmResult = float:fromString(vmParam[0]);
            if vmResult is float {
                vmHours = vmResult;
            }
        }
        
        string[]? storageParam = params["storageGB"];
        if storageParam is string[] && storageParam.length() > 0 {
            float|error storageResult = float:fromString(storageParam[0]);
            if storageResult is float {
                storageGB = storageResult;
            }
        }
        
        string[]? networkParam = params["networkGB"];
        if networkParam is string[] && networkParam.length() > 0 {
            float|error networkResult = float:fromString(networkParam[0]);
            if networkResult is float {
                networkGB = networkResult;
            }
        }
        
        CostCalculation bestOption = findBestProvider(vmHours, storageGB, networkGB);
        
        return {
            "status": "success",
            "bestProvider": bestOption.toJson(),
            "timestamp": time:utcToString(time:utcNow())
        };
    }

    // Generate downloadable report (integrates both cost calc and AI analysis)
    resource function get api/report(http:Request req) returns http:Response {
        map<string[]> params = req.getQueryParams();
        
        string provider = "AWS";
        float vmHours = 0.0;
        float storageGB = 0.0;
        float networkGB = 0.0;
        
        // Parse parameters
        string[]? providerParam = params["provider"];
        if providerParam is string[] && providerParam.length() > 0 {
            provider = providerParam[0];
        }
        
        string[]? vmParam = params["vmHours"];
        if vmParam is string[] && vmParam.length() > 0 {
            float|error vmResult = float:fromString(vmParam[0]);
            if vmResult is float {
                vmHours = vmResult;
            }
        }
        
        string[]? storageParam = params["storageGB"];
        if storageParam is string[] && storageParam.length() > 0 {
            float|error storageResult = float:fromString(storageParam[0]);
            if storageResult is float {
                storageGB = storageResult;
            }
        }
        
        string[]? networkParam = params["networkGB"];
        if networkParam is string[] && networkParam.length() > 0 {
            float|error networkResult = float:fromString(networkParam[0]);
            if networkResult is float {
                networkGB = networkResult;
            }
        }
        
        // Calculate costs
        CostCalculation selectedCalc = calculateCosts(provider, vmHours, storageGB, networkGB);
        CostCalculation bestOption = findBestProvider(vmHours, storageGB, networkGB);
        
        // Generate AI analysis
        AISuggestion[] suggestions = [];
        float totalResourceSavings = 0.0;
        foreach var r in resources {
            AISuggestion suggestion = analyzeResource(r);
            suggestions.push(suggestion);
            totalResourceSavings += suggestion.potentialSavings;
        }
        
        // Build comprehensive report
        string report = string `CLOUDOPTIMIZER PRO - COMPREHENSIVE COST REPORT
================================================================
Generated: ${time:utcToString(time:utcNow())}

COST CALCULATION
================================================================
Selected Provider: ${selectedCalc.provider}
Configuration:
  VM Hours/Month    : ${selectedCalc.vmHours}
  Storage (GB)      : ${selectedCalc.storageGB}
  Network Transfer  : ${selectedCalc.networkGB}

Cost Breakdown:
  VM Cost          : ${formatToTwoDecimals(selectedCalc.vmCost)}
  Storage Cost     : ${formatToTwoDecimals(selectedCalc.storageCost)}
  Network Cost     : ${formatToTwoDecimals(selectedCalc.networkCost)}
  TOTAL COST       : ${formatToTwoDecimals(selectedCalc.totalCost)}

PROVIDER COMPARISON
================================================================`;

        string[] allProviders = ["AWS", "Azure", "Google"];
        foreach string p in allProviders {
            CostCalculation calc = calculateCosts(p, vmHours, storageGB, networkGB);
            report += string `
${p}: ${formatToTwoDecimals(calc.totalCost)} (VM: ${formatToTwoDecimals(calc.vmCost)}, Storage: ${formatToTwoDecimals(calc.storageCost)}, Network: ${formatToTwoDecimals(calc.networkCost)})`;
        }

        report += string `

BEST RECOMMENDATION: ${bestOption.provider} - ${formatToTwoDecimals(bestOption.totalCost)}
Potential Monthly Savings: ${formatToTwoDecimals(selectedCalc.totalCost - bestOption.totalCost)}

AI OPTIMIZATION ANALYSIS
================================================================
Current Resource Analysis:`;

        foreach var suggestion in suggestions {
            report += string `

Resource: ${suggestion.resourceId}
Recommendation: ${suggestion.recommendation}
Confidence: ${suggestion.confidence}
Potential Savings: ${formatToTwoDecimals(suggestion.potentialSavings)}/month
Actions: ${string:'join(suggestion.actions, ", ")}`;
        }

        float totalCurrentResourceCost = 0.0;
        foreach var r in resources {
            totalCurrentResourceCost += r.costPerMonth;
        }

        report += string `

SUMMARY
================================================================
Current Resource Costs    : ${formatToTwoDecimals(totalCurrentResourceCost)}/month
Potential Resource Savings: ${formatToTwoDecimals(totalResourceSavings)}/month
New Calculation Costs     : ${formatToTwoDecimals(selectedCalc.totalCost)}/month
Best Provider Option      : ${formatToTwoDecimals(bestOption.totalCost)}/month

TOTAL OPTIMIZATION POTENTIAL: ${formatToTwoDecimals(totalResourceSavings + (selectedCalc.totalCost - bestOption.totalCost))}/month

================================================================
Report generated by CloudOptimizer Pro
For more details, visit: http://localhost:8080
================================================================`;

        http:Response res = new;
        res.setPayload(report);
        res.setHeader("Content-Type", "text/plain");
        res.setHeader("Content-Disposition", "attachment; filename=cloudoptimizer-comprehensive-report.txt");
        return res;
    }

    // Health check endpoint
    resource function get health() returns json {
        return {
            "status": "healthy",
            "timestamp": time:utcToString(time:utcNow()),
            "version": "1.0.0",
            "features": ["cost-calculator", "ai-analysis", "resource-monitoring"]
        };
    }

    // Favicon
    resource function get favicon\.ico() returns http:Response {
        http:Response res = new;
        res.statusCode = 204;
        return res;
    }

    // Catch-all for undefined routes
    resource function default [string... path]() returns http:Response {
        http:Response res = new;
        res.statusCode = 404;
        res.setPayload("Path not found");
        return res;
    }
}