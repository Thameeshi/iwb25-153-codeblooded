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

function getPricing(string provider) returns map<float> {
    match provider {
        "AWS" => { return {"vm": 0.05, "storage": 0.01, "network": 0.02}; }
        "Azure" => { return {"vm": 0.045, "storage": 0.012, "network": 0.018}; }
        "Google" => { return {"vm": 0.048, "storage": 0.011, "network": 0.019}; }
        _ => { return {"vm": 0.05, "storage": 0.01, "network": 0.02}; }
    }
}

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

service / on new http:Listener(808) {

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
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); margin: 0; padding: 20px; color: white; }
        .container { max-width: 1000px; margin: 0 auto; }
        .nav { background: rgba(255,255,255,0.1); padding: 1rem; border-radius: 10px; margin-bottom: 2rem; text-align: center; }
        .nav a { color: white; margin: 0 1rem; text-decoration: none; padding: 0.5rem 1rem; border-radius: 5px; }
        .nav a:hover { background: rgba(255,255,255,0.2); }
        .page { display: none; background: white; color: #333; padding: 2rem; border-radius: 15px; }
        .page.active { display: block; }
        .metrics { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; margin: 1rem 0; }
        .metric { background: #667eea; color: white; padding: 1rem; border-radius: 10px; text-align: center; }
        .calc-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; margin-top: 1rem; }
        .form-group { margin-bottom: 1rem; }
        .form-label { display: block; margin-bottom: 0.5rem; font-weight: bold; }
        .form-input, .form-select { width: 100%; padding: 0.5rem; border: 1px solid #ddd; border-radius: 5px; }
        .results { background: #f8f9fa; padding: 1rem; border-radius: 10px; }
        .result-item { display: flex; justify-content: space-between; padding: 0.3rem 0; }
        .suggestion { background: #f8f9fa; padding: 1rem; margin: 0.5rem 0; border-radius: 8px; border-left: 3px solid #667eea; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 0.8rem; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #667eea; color: white; }
    </style>
</head>
<body>
    <div class="container">
        <div class="nav">
            <a href="#" onclick="showPage('home')">Home</a>
            <a href="#" onclick="showPage('calculator')">Calculator</a>
            <a href="#" onclick="showPage('suggestions')">AI Suggestions</a>
            <a href="#" onclick="showPage('report')">Cost Report</a>
        </div>

        <!-- HOME -->
        <div id="home" class="page active">
            <h1 style="text-align: center; margin-bottom: 2rem;">CloudOptimizer Pro Dashboard</h1>
            <div class="metrics">
                <div class="metric">
                    <h3>$${totalCost}</h3>
                    <p>Monthly Cost</p>
                </div>
                <div class="metric">
                    <h3>$${totalSavings}</h3>
                    <p>Potential Savings</p>
                </div>
                <div class="metric">
                    <h3>${resources.length()}</h3>
                    <p>Resources</p>
                </div>
            </div>
        </div>

        <!-- CALCULATOR -->
        <div id="calculator" class="page">
            <h2>Cloud Cost Calculator</h2>
            <div class="calc-grid">
                <div>
                    <div class="form-group">
                        <label class="form-label">Cloud Provider</label>
                        <select id="provider" class="form-select" onchange="calculate()">
                            <option value="AWS">AWS</option>
                            <option value="Azure">Azure</option>
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
                        <label class="form-label">Network (GB)</label>
                        <input id="network" type="number" class="form-input" value="50" oninput="calculate()">
                    </div>
                </div>
                <div>
                    <h3>Cost Breakdown</h3>
                    <div class="results">
                        <div class="result-item"><span>VM:</span><span id="vmCost">$37.20</span></div>
                        <div class="result-item"><span>Storage:</span><span id="storageCost">$1.00</span></div>
                        <div class="result-item"><span>Network:</span><span id="networkCost">$1.00</span></div>
                        <div class="result-item"><span>Total:</span><span id="total">$39.20</span></div>
                    </div>
                    <canvas id="costChart" style="margin-top: 1rem; height: 200px;"></canvas>
                </div>
            </div>
        </div>

        <!-- AI SUGGESTIONS -->
        <div id="suggestions" class="page">
            <h2>AI Suggestions</h2>`;

        foreach var r in resources {
            AISuggestion suggestion = analyzeResource(r);
            html += string `
            <div class="suggestion">
                <h3>${r.name} (${suggestion.resourceId})</h3>
                <p><strong>Recommendation:</strong> ${suggestion.recommendation}</p>
                <p><strong>Confidence:</strong> ${suggestion.confidence}</p>`;
                if suggestion.potentialSavings > 0.0 {
                    html += string `<p><strong>Potential Savings:</strong> $${suggestion.potentialSavings}/month</p>`;
                }
                html += string `<p><strong>Actions:</strong> ${string:'join(", ", ...suggestion.actions)}</p>
            </div>`;
        }

        html += string `
        </div>

        <!-- COST REPORT -->
        <div id="report" class="page">
            <h2>Cost Report</h2>
            <table>
                <tr><th>Resource</th><th>Type</th><th>CPU %</th><th>Memory %</th><th>Cost/Month</th></tr>`;
                
        foreach var r in resources {
            html += string `<tr>
                <td>${r.name}<br><small>${r.id}</small></td>
                <td>${r.resourceType}</td>
                <td>${r.cpuUsage}%</td>
                <td>${r.memoryUsage}%</td>
                <td>$${r.costPerMonth}</td>
            </tr>`;
        }

        html += string `
            </table>
            <p style="text-align: center; margin-top: 1rem; color: #666;">
                Generated: ${time:utcToString(time:utcNow())}
            </p>
        </div>
    </div>

    <script>
        const pricing = {
            AWS: { vm: 0.05, storage: 0.01, network: 0.02 },
            Azure: { vm: 0.045, storage: 0.012, network: 0.018 },
            Google: { vm: 0.048, storage: 0.011, network: 0.019 }
        };

        let chart;

        function showPage(pageId) {
            document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
            document.getElementById(pageId).classList.add('active');
            if (pageId === 'calculator') calculate();
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

        function updateChart(vm, storage, network) {
            const ctx = document.getElementById('costChart');
            if (!ctx) return;
            
            if (chart) chart.destroy();
            
            chart = new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: ['VM', 'Storage', 'Network'],
                    datasets: [{
                        data: [vm, storage, network],
                        backgroundColor: ['#667eea', '#764ba2', '#f093fb']
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false
                }
            });
        }

        calculate();
    </script>
</body>
</html>`;

        http:Response res = new;
        res.setPayload(html);
        res.setHeader("Content-Type", "text/html");
        return res;
    }

    resource function get health() returns json {
        return {
            "status": "healthy",
            "timestamp": time:utcToString(time:utcNow()),
            "service": "CloudOptimizer"
        };
    }
}