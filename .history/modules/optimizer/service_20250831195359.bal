import ballerina/http;
import ballerina/time;

// Utility: format float to 2 decimals
function formatToTwoDecimals(float value) returns string {
    int absCents = <int>(value * 100.0 + (value >= 0.0 ? 0.5 : -0.5));
    int absDollars = absCents / 100;
    int absRemainder = absCents % 100;
    string sign = value < 0.0 ? "-" : "";
    return sign + absDollars.toString() + "." + (absRemainder < 10 ? "0" : "") + absRemainder.toString();
}

// Pricing per provider - FIXED to match frontend
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

service / on new http:Listener(8080) {

    // Serve favicon.ico (returns empty response to avoid errors)
    resource function get favicon\.ico(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setHeader("Content-Type", "image/x-icon");
        res.statusCode = 204; // No Content
        check caller->respond(res);
    }

    // Serve the frontend HTML (embedded) - FIXED pricing in JavaScript
    resource function get .(http:Caller caller, http:Request req) returns error? {
        string htmlContent = string `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cloud Cost Optimizer Pro</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: Arial, sans-serif; background:#f5f7fa; margin:0; padding:0; }
        .container { max-width:900px; margin:50px auto; background:#fff; padding:40px; border-radius:12px; box-shadow:0 0 20px rgba(0,0,0,0.1); }
        h1 { text-align:center; color:#333; margin-bottom:30px; }
        label { font-weight:bold; margin-top:15px; display:block; color:#555; }
        select, input { width:100%; padding:12px; margin-top:5px; border-radius:6px; border:1px solid #ddd; font-size:16px; box-sizing:border-box; }
        select:focus, input:focus { outline:none; border-color:#007BFF; box-shadow:0 0 5px rgba(0,123,255,0.3); }
        button { margin:15px 10px 0 0; padding:12px 25px; border-radius:6px; border:none; cursor:pointer; font-size:14px; font-weight:bold; }
        .calculate-btn { background-color:#007BFF; color:white; transition:background-color 0.3s; }
        .calculate-btn:hover { background-color:#0056b3; }
        .download-btn { background-color:#28a745; color:white; transition:background-color 0.3s; }
        .download-btn:hover { background-color:#1e7e34; }
        table { width:100%; margin-top:25px; border-collapse: collapse; box-shadow:0 2px 10px rgba(0,0,0,0.1); }
        th, td { padding:15px 12px; border-bottom:1px solid #ddd; text-align:left; }
        th { background-color:#007BFF; color:white; font-weight:bold; }
        tr:nth-child(even) { background-color:#f8f9fa; }
        tr:last-child th, tr:last-child td { border-bottom:2px solid #007BFF; font-weight:bold; font-size:16px; }
        #bestProvider { font-weight:bold; font-size:18px; color:#28a745; margin-top:20px; text-align:center; padding:15px; background:#f8fff9; border-radius:8px; border-left:5px solid #28a745; }
        .chart-container { display:flex; justify-content:center; margin-top:25px; }
        #costChart { max-width:400px; max-height:400px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Cloud Cost Optimizer Pro</h1>
        
        <label for="provider">Cloud Provider:</label>
        <select id="provider" onchange="calculateCost()">
            <option value="AWS">AWS</option>
            <option value="Azure">Azure</option>
            <option value="Google">Google Cloud</option>
        </select>

        <label for="vm">VM Hours:</label>
        <input id="vm" type="number" min="0" step="any" value="100" oninput="calculateCost()" placeholder="Enter VM hours">
        
        <label for="storage">Storage (GB):</label>
        <input id="storage" type="number" min="0" step="any" value="500" oninput="calculateCost()" placeholder="Enter storage in GB">
        
        <label for="network">Network (GB):</label>
        <input id="network" type="number" min="0" step="any" value="100" oninput="calculateCost()" placeholder="Enter network usage in GB">

        <table>
            <tr><th>Resource</th><th>Cost ($)</th></tr>
            <tr><td>VM</td><td id="vmCost">5.00</td></tr>
            <tr><td>Storage</td><td id="storageCost">5.00</td></tr>
            <tr><td>Network</td><td id="networkCost">2.00</td></tr>
            <tr><th>Total</th><th id="totalCost">12.00</th></tr>
        </table>

        <p id="bestProvider">Best Option: AWS ($12.00)</p>

        <div class="chart-container">
            <canvas id="costChart"></canvas>
        </div>

        <div style="text-align:center; margin-top:20px;">
            <button class="calculate-btn" onclick="calculateCost(); return false;">Recalculate</button>
            <button class="download-btn" onclick="downloadReport(); return false;">Download Report</button>
        </div>
    </div>

<script>
// FIXED: Consistent pricing with backend
function getPricing(provider) {
    if(provider == 'AWS') return {vm: 0.05, storage: 0.01, network: 0.02};
    else if(provider == 'Azure') return {vm: 0.045, storage: 0.012, network: 0.018};
    else if(provider == 'Google') return {vm: 0.048, storage: 0.011, network: 0.019};
    return {vm: 0.05, storage: 0.01, network: 0.02}; // Default to AWS
}

let chart;
function calculateCost() {
    let vm = parseFloat(document.getElementById('vm').value) || 0;
    let storage = parseFloat(document.getElementById('storage').value) || 0;
    let network = parseFloat(document.getElementById('network').value) || 0;
    let provider = document.getElementById('provider').value;
    let pricing = getPricing(provider);

    let vmCost = vm * pricing.vm;
    let storageCost = storage * pricing.storage;
    let networkCost = network * pricing.network;
    let total = vmCost + storageCost + networkCost;

    document.getElementById('vmCost').innerText = vmCost.toFixed(2);
    document.getElementById('storageCost').innerText = storageCost.toFixed(2);
    document.getElementById('networkCost').innerText = networkCost.toFixed(2);
    document.getElementById('totalCost').innerText = total.toFixed(2);

    updateChart(vmCost, storageCost, networkCost);
    showBestProvider(vm, storage, network);
}

function updateChart(vmCost, storageCost, networkCost) {
    let ctx = document.getElementById('costChart').getContext('2d');
    if(chart) chart.destroy();
    
    // Only show chart if there are actual costs
    if(vmCost + storageCost + networkCost > 0) {
        chart = new Chart(ctx, {
            type: 'pie',
            data: { 
                labels: ['VM', 'Storage', 'Network'], 
                datasets: [{
                    data: [vmCost, storageCost, networkCost], 
                    backgroundColor: ['#007BFF', '#28a745', '#dc3545'],
                    borderWidth: 2,
                    borderColor: '#fff'
                }] 
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            padding: 15,
                            usePointStyle: true
                        }
                    }
                }
            }
        });
    }
}

function showBestProvider(vm, storage, network) {
    const providers = ['AWS', 'Azure', 'Google'];
    let bestProvider = '';
    let minCost = Number.MAX_VALUE;

    // If no usage, show default message
    if(vm === 0 && storage === 0 && network === 0) {
        document.getElementById('bestProvider').innerText = 'Enter values to see best option';
        document.getElementById('bestProvider').style.color = '#6c757d';
        return;
    }

    for (let i = 0; i < providers.length; i++) {
        let p = getPricing(providers[i]);
        let cost = vm * p.vm + storage * p.storage + network * p.network;
        console.log(providers[i] + ': $' + cost.toFixed(2));
        if (cost < minCost) { 
            minCost = cost; 
            bestProvider = providers[i]; 
        }
    }

    document.getElementById('bestProvider').innerText = 'Best Option: ' + bestProvider + ' ($' + minCost.toFixed(2) + ')';
    document.getElementById('bestProvider').style.color = '#28a745';
}

function downloadReport() {
    let vm = document.getElementById('vm').value || 0;
    let storage = document.getElementById('storage').value || 0;
    let network = document.getElementById('network').value || 0;
    let provider = document.getElementById('provider').value;
    window.location.href = '/downloadReport?vmHours=' + vm + '&storageGB=' + storage + '&networkGB=' + network + '&provider=' + provider;
}

// Initialize with default values on page load
document.addEventListener('DOMContentLoaded', function() {
    calculateCost();
});
</script>
</body>
</html>`;
        
        http:Response resp = new();
        resp.setPayload(htmlContent);
        resp.setHeader("Content-Type", "text/html");
        check caller->respond(resp);
    }

    // Generate downloadable report (TXT)
    resource function get downloadReport(http:Caller caller, http:Request req) returns error? {
        map<string[]> params = req.getQueryParams();

        // Safe parameter access
        string vmStr = "0";
        string stStr = "0";
        string netStr = "0";
        string provider = "AWS";
        
        string[]? vmParams = params["vmHours"];
        if vmParams is string[] && vmParams.length() > 0 {
            vmStr = vmParams[0];
        }
        
        string[]? stParams = params["storageGB"];
        if stParams is string[] && stParams.length() > 0 {
            stStr = stParams[0];
        }
        
        string[]? netParams = params["networkGB"];
        if netParams is string[] && netParams.length() > 0 {
            netStr = netParams[0];
        }
        
        string[]? providerParams = params["provider"];
        if providerParams is string[] && providerParams.length() > 0 {
            provider = providerParams[0];
        }

        float|error vm = float:fromString(vmStr);
        float|error st = float:fromString(stStr);
        float|error net = float:fromString(netStr);

        float vmHours = vm is float ? vm : 0.0;
        float storageGB = st is float ? st : 0.0;
        float networkGB = net is float ? net : 0.0;

        map<float> pricing = getPricing(provider);

        // Safe map access with null checks
        float vmPrice = pricing["vm"] ?: 0.05;
        float storagePrice = pricing["storage"] ?: 0.01;
        float networkPrice = pricing["network"] ?: 0.02;
        
        float vmCost = vmHours * vmPrice;
        float storageCost = storageGB * storagePrice;
        float networkCost = networkGB * networkPrice;
        float total = vmCost + storageCost + networkCost;

        // Compare all providers for the report
        string[] allProviders = ["AWS", "Azure", "Google"];
        string comparisons = "\nProvider Comparison:\n";
        comparisons += "====================\n";
        
        foreach string p in allProviders {
            map<float> pPricing = getPricing(p);
            float pVmCost = vmHours * (pPricing["vm"] ?: 0.05);
            float pStorageCost = storageGB * (pPricing["storage"] ?: 0.01);
            float pNetworkCost = networkGB * (pPricing["network"] ?: 0.02);
            float pTotal = pVmCost + pStorageCost + pNetworkCost;
            
            comparisons += p + ": $" + formatToTwoDecimals(pTotal) + 
                          " (VM: $" + formatToTwoDecimals(pVmCost) + 
                          ", Storage: $" + formatToTwoDecimals(pStorageCost) + 
                          ", Network: $" + formatToTwoDecimals(pNetworkCost) + ")\n";
        }

        string reportContent = string `Cloud Cost Optimizer Report
========================================
Selected Provider: ${provider}
Configuration:
  VM Hours   : ${vmHours}
  Storage GB : ${storageGB} 
  Network GB : ${networkGB}

Cost Breakdown:
  VM Cost      : $${formatToTwoDecimals(vmCost)}
  Storage Cost : $${formatToTwoDecimals(storageCost)}
  Network Cost : $${formatToTwoDecimals(networkCost)}
  
TOTAL COST   : $${formatToTwoDecimals(total)}

${comparisons}
Generated: ${time:utcToString(time:utcNow())}
========================================
`;

        http:Response resp = new();
        resp.setPayload(reportContent);
        resp.setHeader("Content-Type", "text/plain");
        resp.setHeader("Content-Disposition", "attachment; filename=cloud-cost-report.txt");
        check caller->respond(resp);
    }

    // Catch-all resource to handle DevTools and other requests
    resource function default [string... path](http:Caller caller, http:Request req) returns error? {
        http:Response resp = new();
        resp.statusCode = 404;
        resp.setPayload("Path not found");
        check caller->respond(resp);
    }
}