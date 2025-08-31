import ballerina/http;
import ballerina/time;

isolated function formatPrice(float value) returns string {
    return value.toString();
}

isolated function getPricingg(string provider) returns map<float> {
    match provider {
        "AWS" => { return {"vm": 0.05, "storage": 0.01, "network": 0.02}; }
        "Azure" => { return {"vm": 0.045, "storage": 0.012, "network": 0.018}; }
        "Google" => { return {"vm": 0.048, "storage": 0.011, "network": 0.019}; }
        _ => { return {"vm": 0.05, "storage": 0.01, "network": 0.02}; }
    }
}

service / on new http:Listener(8080) {
    final map<json> sessions = {};

    resource function get .() returns http:Response {
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
        
        .results { background: #f8f9fa; padding: 1.5rem; border-radius: 15px; }
        .result-item { display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid #dee2e6; }
        .result-item:last-child { border-bottom: none; font-weight: bold; font-size: 1.2rem; color: #667eea; }
        
        .chart-container { margin-top: 2rem; height: 300px; }
        .download-btn { background: #28a745; color: white; padding: 0.8rem 1.5rem; border: none; border-radius: 10px; cursor: pointer; margin-top: 1rem; }
        
        .auth-section { margin-left: auto; }
        .user-info { display: flex; align-items: center; gap: 1rem; color: white; }
        .user-avatar { width: 32px; height: 32px; border-radius: 50%; }
        .auth-btn { background: rgba(255,255,255,0.2); color: white; border: 1px solid rgba(255,255,255,0.3); padding: 0.5rem 1rem; border-radius: 20px; cursor: pointer; font-size: 0.9rem; }
        .auth-btn:hover { background: rgba(255,255,255,0.3); }
        
        /* Login Modal - Fixed positioning and z-index */
        .login-modal { 
            position: fixed; 
            top: 0; 
            left: 0; 
            width: 100vw; 
            height: 100vh; 
            background: rgba(0,0,0,0.9); 
            display: flex; 
            align-items: center; 
            justify-content: center; 
            z-index: 10000;
        }
        .login-content { 
            background: white; 
            padding: 3rem; 
            border-radius: 20px; 
            text-align: center; 
            max-width: 400px; 
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            position: relative;
            z-index: 10001;
        }
        .login-content h2 { margin-bottom: 1rem; color: #333; }
        .login-content p { margin-bottom: 2rem; color: #666; }
        
        /* Footer styles */
        .footer {
            background: rgba(0,0,0,0.2);
            color: white;
            text-align: center;
            padding: 3rem 0;
            margin-top: 4rem;
            position: relative;
            z-index: 50;
        }
        
        .footer-content {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 2rem;
        }
        
        .footer-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 2rem;
            margin-bottom: 2rem;
        }
        
        .footer-section h3,
        .footer-section h4 {
            margin-bottom: 1rem;
        }
        
        .footer-section p {
            opacity: 0.8;
        }
        
        .footer-links {
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
        }
        
        .footer-links a {
            color: white;
            text-decoration: none;
            opacity: 0.8;
        }
        
        .footer-social {
            display: flex;
            justify-content: center;
            gap: 1rem;
        }
        
        .footer-social a {
            color: white;
            opacity: 0.8;
            text-decoration: none;
        }
        
        .footer-bottom {
            border-top: 1px solid rgba(255,255,255,0.2);
            padding-top: 2rem;
            opacity: 0.8;
        }
        
        @media (max-width: 768px) {
            .calc-grid { grid-template-columns: 1fr; }
            .hero h1 { font-size: 2.5rem; }
            .nav { flex-direction: column; gap: 1rem; }
            .nav-links { flex-wrap: wrap; justify-content: center; }
        }
    </style>
</head>
<body>
    <!-- Login Modal - Moved to top level -->
    <div id="loginModal" class="login-modal">
        <div class="login-content">
            <h2>Welcome to CloudOptimizer Pro</h2>
            <p>Please sign in with Google to access the cloud cost calculator</p>
            <div id="g_id_onload"
                 data-client_id="1032851785630-o4f89gqaehhffspn0k5c861r30rvmunf.apps.googleusercontent.com"
                 data-callback="handleGoogleLogin"></div>
            <div class="g_id_signin" data-type="standard" data-size="large"></div>
        </div>
    </div>

    <!-- Header - Moved to proper position -->
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
                <a href="#" onclick="showPage('about')">About</a>
                <a href="#" onclick="showPage('contact')">Contact</a>
                <a href="http://localhost:8081/" target="_blank">Dashboard</a>
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
        <!-- HOME PAGE -->
        <div id="home" class="page active">
            <div class="hero">
                <h1>Cloud Cost Optimization Made Simple</h1>
                <p>Compare AWS, Azure & Google Cloud pricing instantly. Optimize your cloud spending with real-time cost analysis.</p>
                <button class="cta-btn" onclick="showPage('calculator')">Start Optimizing</button>
            </div>
            
            <div class="features">
                <div class="feature">
                    <div class="feature-icon">📊</div>
                    <h3>Real-time Analysis</h3>
                    <p>Get instant cost breakdowns across all major cloud providers</p>
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
                    <p>Enter your requirements to get instant cost estimates</p>
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
                        
                        <div class="chart-container">
                            <canvas id="costChart"></canvas>
                        </div>
                        
                        <button class="download-btn" onclick="downloadReport()">Download Report</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- ABOUT PAGE -->
        <div id="about" class="page">
            <div class="calc-card">
                <h2>About CloudOptimizer Pro</h2>
                <p style="line-height: 1.8; color: #666; margin-top: 1rem;">
                    CloudOptimizer Pro helps businesses make informed decisions about cloud infrastructure costs. 
                    We provide real-time pricing comparisons across AWS, Azure, and Google Cloud to help you 
                    optimize your cloud spending and choose the most cost-effective solution for your needs.
                </p>
            </div>
        </div>

        <!-- CONTACT PAGE -->
        <div id="contact" class="page">
            <div class="calc-card">
                <h2>Contact Us</h2>
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; margin-top: 2rem;">
                    <div>
                        <h3>Get in Touch</h3>
                        <p style="color: #666; margin: 1rem 0;">Have questions about cloud optimization? We're here to help!</p>
                        <div style="margin: 1rem 0;">
                            <strong>Email:</strong> support@cloudoptimizer.pro<br>
                            <strong>Phone:</strong> +1 (555) 123-4567<br>
                            <strong>Address:</strong> 123 Cloud Street, Tech City, TC 12345
                        </div>
                    </div>
                    <div>
                        <h3>Quick Contact</h3>
                        <form style="display: flex; flex-direction: column; gap: 1rem;">
                            <input type="text" placeholder="Your Name" style="padding: 0.8rem; border: 1px solid #ddd; border-radius: 5px;">
                            <input type="email" placeholder="Your Email" style="padding: 0.8rem; border: 1px solid #ddd; border-radius: 5px;">
                            <textarea placeholder="Your Message" rows="4" style="padding: 0.8rem; border: 1px solid #ddd; border-radius: 5px; resize: vertical;"></textarea>
                            <button type="submit" style="background: #667eea; color: white; padding: 0.8rem; border: none; border-radius: 5px; cursor: pointer;">Send Message</button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Footer -->
    <footer class="footer">
        <div class="footer-content">
            <div class="footer-grid">
                <div class="footer-section">
                    <h3>CloudOptimizer Pro</h3>
                    <p>Your trusted partner for cloud cost optimization and multi-cloud management.</p>
                </div>
                <div class="footer-section">
                    <h4>Quick Links</h4>
                    <div class="footer-links">
                        <a href="#" onclick="showPage('home')">Home</a>
                        <a href="#" onclick="showPage('calculator')">Calculator</a>
                        <a href="#" onclick="showPage('about')">About</a>
                        <a href="#" onclick="showPage('contact')">Contact</a>
                    </div>
                </div>
                <div class="footer-section">
                    <h4>Cloud Providers</h4>
                    <div>
                        <p>Amazon Web Services</p>
                        <p>Microsoft Azure</p>
                        <p>Google Cloud Platform</p>
                    </div>
                </div>
                <div class="footer-section">
                    <h4>Follow Us</h4>
                    <div class="footer-social">
                        <a href="#">Twitter</a>
                        <a href="#">LinkedIn</a>
                        <a href="#">GitHub</a>
                    </div>
                </div>
            </div>
            <div class="footer-bottom">
                <p>&copy; 2025 CloudOptimizer Pro. All rights reserved. | Privacy Policy | Terms of Service</p>
            </div>
        </div>
    </footer>

    <script>
        const pricing = {
            AWS: { vm: 0.05, storage: 0.01, network: 0.02 },
            Azure: { vm: 0.045, storage: 0.012, network: 0.018 },
            Google: { vm: 0.048, storage: 0.011, network: 0.019 }
        };

        let chart;
        let isLoggedIn = false;

        // Check if user is already logged in
        window.onload = function() {
            if (sessionStorage.getItem('googleCredential')) {
                handleLoginSuccess();
            }
        };

        function handleGoogleLogin(response) {
            sessionStorage.setItem('googleCredential', response.credential);
            handleLoginSuccess();
        }

        function handleLoginSuccess() {
            const credential = sessionStorage.getItem('googleCredential');
            if (credential) {
                const payload = JSON.parse(atob(credential.split('.')[1]));
                document.getElementById('loginModal').style.display = 'none';
                document.getElementById('userInfo').style.display = 'flex';
                document.getElementById('userName').textContent = payload.name;
                isLoggedIn = true;
                calculate();
            }
        }

        function logout() {
            sessionStorage.removeItem('googleCredential');
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
                        backgroundColor: ['#667eea', '#764ba2', '#f093fb'],
                        borderWidth: 0
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'bottom'
                        }
                    }
                }
            });
        }

        function downloadReport() {
            const provider = document.getElementById('provider').value;
            const vmHours = document.getElementById('vmHours').value;
            const storage = document.getElementById('storage').value;
            const network = document.getElementById('network').value;
            
            window.open('/report?provider=' + provider + '&vm=' + vmHours + '&storage=' + storage + '&network=' + network);
        }
    </script>
</body>
</html>`;

        http:Response res = new;
        res.setPayload(html);
        res.setHeader("Content-Type", "text/html");
        return res;
    }

    resource function get report(http:Request req) returns http:Response {
        map<string[]> params = req.getQueryParams();
        
        string provider = "AWS";
        float vm = 0.0;
        float storage = 0.0;
        float network = 0.0;
        
        string[]? providerParam = params["provider"];
        if providerParam is string[] && providerParam.length() > 0 {
            provider = providerParam[0];
        }
        
        string[]? vmParam = params["vm"];
        if vmParam is string[] && vmParam.length() > 0 {
            float|error vmResult = float:fromString(vmParam[0]);
            if vmResult is float {
                vm = vmResult;
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
        
        map<float> rates = getPricing(provider);
        float vmRate = rates["vm"] ?: 0.05;
        float storageRate = rates["storage"] ?: 0.01;
        float networkRate = rates["network"] ?: 0.02;
        
        float vmCost = vm * vmRate;
        float storageCost = storage * storageRate;
        float networkCost = network * networkRate;
        float total = vmCost + storageCost + networkCost;
        
        string report = string `Cloud Cost Report
Provider: ${provider}
VM: ${vm} hours = $${vmCost.toString()}
Storage: ${storage} GB = $${storageCost.toString()}
Network: ${network} GB = $${networkCost.toString()}
Total: $${total.toString()}
Generated: ${time:utcToString(time:utcNow())}`;

        http:Response res = new;
        res.setPayload(report);
        res.setHeader("Content-Type", "text/plain");
        res.setHeader("Content-Disposition", "attachment; filename=report.txt");
        return res;
    }

    resource function get favicon\.ico() returns http:Response {
        http:Response res = new;
        res.statusCode = 204;
        return res;
    }
}