import ballerina/http;
import ballerina/time;

// Utility: format float to 2 decimals
function formatToTwoDecimals(float value) returns string {
    int absCents = <int>(value * 100.0 + (value >= 0.0 ? 0.5 : -0.5));
    int absDollars = absCents / 100;
    int absRemainder = absCents % 100;
    return string `${absDollars}.${absRemainder < 10 ? "0" : ""}${absRemainder}`;
}

// Service config
service / on new http:Listener(8081) {

    // Serve favicon.ico
    resource function get favicon\.ico(http:Caller caller, http:Request req) returns error? {
        http:Response res = new;
        res.setHeader("Content-Type", "image/x-icon");
        res.statusCode = 204;
        check caller->respond(res);
    }

    // Main page with navbar
    resource function get .(http:Caller caller, http:Request req) returns error? {
        string html = 
        `<!DOCTYPE html>
        <html>
        <head>
            <title>Cloud Cost Optimizer Lite</title>
            <style>
                body { font-family: Arial, sans-serif; margin:0; padding:0; background:#f4f7f9; }
                nav { background:#2c3e50; color:white; padding:15px; }
                nav a { color:white; margin-right:20px; text-decoration:none; }
                .container { padding:20px; }
                .card { background:white; padding:20px; margin-bottom:20px; border-radius:8px;
                        box-shadow:0 2px 6px rgba(0,0,0,0.1); }
                h2 { color:#34495e; }
                input, select { padding:10px; margin:5px 0; width:100%; }
                button { background:#2980b9; color:white; border:none; padding:10px 15px;
                         border-radius:5px; cursor:pointer; }
                button:hover { background:#3498db; }
            </style>
        </head>
        <body>
            <nav>
                <a href="/">Home</a>
                <a href="/report">Cost Report</a>
                <a href="/ai-suggest">AI Suggestions</a>
            </nav>
            <div class="container">
                <div class="card">
                    <h2>Welcome to Cloud Cost Optimizer Lite</h2>
                    <p>This tool helps estimate cloud costs across providers.</p>
                </div>
                <div class="card">
                    <h3>Try a Cost Estimation</h3>
                    <form method="get" action="/report">
                        <label>Provider:</label>
                        <select name="provider">
                            <option value="aws">AWS</option>
                            <option value="azure">Azure</option>
                            <option value="gcp">GCP</option>
                        </select>
                        <label>VM Hours:</label>
                        <input type="number" name="vm" value="100">
                        <label>Storage (GB):</label>
                        <input type="number" name="storage" value="500">
                        <label>Network Out (GB):</label>
                        <input type="number" name="network" value="100">
                        <button type="submit">Generate Report</button>
                    </form>
                </div>
            </div>
        </body>
        </html>`;
        http:Response res = new;
        res.setHeader("Content-Type", "text/html");
        res.setTextPayload(html);
        check caller->respond(res);
    }

    // Cost report endpoint
    resource function get report(http:Caller caller, http:Request req) returns error? {
        string provider = req.getQueryParamValue("provider").toString();
        int vm = check req.getQueryParamValue("vm").ensureType(int);
        int storage = check req.getQueryParamValue("storage").ensureType(int);
        int network = check req.getQueryParamValue("network").ensureType(int);

        float vmCost = vm * 0.05;
        float storageCost = storage * 0.02;
        float networkCost = network * 0.08;
        float total = vmCost + storageCost + networkCost;

        string html =
        `<!DOCTYPE html>
        <html>
        <head><title>Report</title>
        <style>
            body { font-family:Arial; margin:20px; background:#f9f9f9; }
            table { border-collapse:collapse; width:80%; margin:auto; background:white; }
            th, td { border:1px solid #ddd; padding:8px; text-align:center; }
            th { background:#2980b9; color:white; }
        </style>
        </head>
        <body>
            <h2>Cloud Cost Report - ${provider}</h2>
            <table>
                <tr><th>Resource</th><th>Usage</th><th>Cost (USD)</th></tr>
                <tr><td>VM</td><td>${vm} hours</td><td>${vmCost}</td></tr>
                <tr><td>Storage</td><td>${storage} GB</td><td>${storageCost}</td></tr>
                <tr><td>Network</td><td>${network} GB</td><td>${networkCost}</td></tr>
                <tr><th>Total</th><td></td><th>${total}</th></tr>
            </table>
            <p>Generated: ${time:utcToString(time:utcNow())}</p>
        </body>
        </html>`;

        http:Response res = new;
        res.setHeader("Content-Type", "text/html");
        res.setTextPayload(html);
        check caller->respond(res);
    }

    // AI Suggestion endpoint
    resource function get ai-suggest(http:Caller caller, http:Request req) returns error? {
        // Example: Return dummy recommendations
        string[][] recommendations = [
            ["VM123", "Switch to Spot Instances", "High"],
            ["ST456", "Move infrequent data to cold storage", "Medium"],
            ["NET789", "Use CDN for static content", "High"]
        ];

        string html = 
        `<!DOCTYPE html>
        <html>
        <head><title>AI Suggestions</title>
        <style>
            body { font-family:Arial; margin:20px; }
            table { border-collapse:collapse; width:90%; margin:auto; }
            th, td { border:1px solid #ddd; padding:8px; }
            th { background:#16a085; color:white; }
            .conf-High { color:green; font-weight:bold; }
            .conf-Medium { color:orange; }
            .conf-Low { color:gray; }
        </style>
        </head>
        <body>
            <h2>AI Optimization Suggestions</h2>
            <table>
                <tr><th>Resource</th><th>Recommendation</th><th>Confidence</th></tr>`;

        foreach var rec in recommendations {
            html += string `<tr><td>${rec[0]}</td><td>${rec[1]}</td>
                            <td class="conf-${rec[2]}">${rec[2]}</td></tr>`;
        }

        html += "</table></body></html>";

        http:Response res = new;
        res.setHeader("Content-Type", "text/html");
        res.setTextPayload(html);
        check caller->respond(res);
    }
}
