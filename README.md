# CloudOptimizer Pro

## Overview
CloudOptimizer Pro optimizes cloud costs across AWS, Azure, and Google Cloud using AI-powered analysis and real-time calculations built with Ballerina.

## Key Features
- **Multi-Cloud Cost Calculator**: Compare pricing across AWS, Azure, and Google Cloud
- **AI-Powered Suggestions**: Get intelligent recommendations for cost optimization
- **Real-Time Dashboard**: Interactive dashboard with live cost metrics
- **Comprehensive Reports**: Generate detailed cost analysis reports
- **Resource Utilization Analysis**: Monitor CPU, memory, and storage usage patterns
- **Google OAuth Integration**: Secure user authentication

## Problem Statement
Organizations struggle with unpredictable cloud costs and lack visibility into resource utilization across multiple cloud providers. Manual cost optimization is time-consuming and often leads to overspending on underutilized resources.

## Solution
CloudOptimizer Pro addresses these challenges by:
- Providing instant cost comparisons across major cloud providers
- Using AI algorithms to analyze resource utilization patterns
- Generating actionable optimization recommendations
- Offering intuitive dashboards for cost monitoring

## Architecture
The application consists of two main Ballerina services:

### Landing Page Service (Port 8080)
- **Frontend**: Interactive web interface with cost calculator
- **Authentication**: Google OAuth integration
- **Cost Engine**: Real-time pricing calculations
- **Navigation**: Seamless routing to dashboard and reports

### Dashboard Service (Port 8081)
- **Resource Analysis**: Dynamic resource generation based on user inputs
- **AI Suggestions**: Intelligent optimization recommendations
- **Reporting**: Detailed cost breakdowns and utilization metrics
- **REST API**: JSON endpoints for programmatic access

## Technology Stack
- **Backend**: Ballerina language
- **Frontend**: HTML5, CSS3, JavaScript
- **Charts**: Chart.js for data visualization
- **Authentication**: Google OAuth
- **Styling**: Modern CSS with glassmorphism effects

## Prerequisites
- Ballerina Swan Lake (latest version)
- Web browser with JavaScript enabled
- Internet connection for Google OAuth

## Setup Instructions

### 1. Clone the Repository
```bash
git clone (https://github.com/Thameeshi/iwb25-153-codeblooded.git)
cd iwb25-153-codeblooded
```

### 2. Install Ballerina
Download and install Ballerina from: https://ballerina.io/downloads/

### 3. Verify Installation
```bash
bal version
```

### 4. Project Structure
```
project-root/
├── main.bal          # Landing page service (port 8080)
├── cloud_optimizer.bal       # Dashboard service (port 8081)
├── README.md
└── Ballerina.toml
```

## Execution Instructions

### 1. Start the Landing Page Service
```bash
# In the project root directory
bal run main.bal
```
The landing page will be available at: `http://localhost:8080`

### 2. Start the Dashboard Service
```bash
# In a new terminal, in the project root directory
bal run cloud_optimizer.bal
```
The dashboard service will be available at: `http://localhost:8081`

### 3. Access the Application
1. Open your web browser
2. Navigate to `http://localhost:8080`
3. Sign in with Google (required for access)
4. Use the cost calculator to input your cloud requirements
5. Click "Go to Advanced Dashboard" to access detailed analysis

## How to Use

### Cost Calculator
1. Select your cloud provider (AWS, Azure, or Google Cloud)
2. Enter your monthly VM hours
3. Specify storage requirements in GB
4. Input network transfer needs in GB
5. View real-time cost breakdown and charts

### Advanced Dashboard
1. From the calculator, click "Go to Advanced Dashboard"
2. View comprehensive cost metrics and resource analysis
3. Access AI-powered optimization suggestions
4. Generate detailed cost reports

### API Endpoints
- `GET /` - Main dashboard with cost overview
- `GET /ai-suggestions` - AI optimization recommendations
- `GET /report` - Detailed cost report
- `GET /resources` - JSON API for resource data
- `GET /health` - Service health check

## Key Ballerina Features Utilized

### 1. HTTP Services
- Multiple service endpoints for different functionalities
- RESTful API design with proper HTTP status codes
- Query parameter handling and validation

### 2. Type System
- Strong typing with custom record types (`CloudResource`, `AISuggestion`)
- Union types for error handling (`float|error`)
- Optional types for flexible parameter handling

### 3. Data Processing
- JSON serialization/deserialization
- String interpolation for dynamic HTML generation
- Map operations for pricing calculations

### 4. Error Handling
- Graceful error handling with default values
- Type-safe parameter extraction
- Robust null checking

### 5. Time Utilities
- UTC timestamp generation for reports
- Time formatting for user display

## Configuration

### Google OAuth Setup
The application uses Google OAuth for authentication. The client ID is preconfigured, but for production use, you should:
1. Create a Google Cloud Console project
2. Enable Google+ API
3. Create OAuth 2.0 credentials
4. Update the client ID in the landing page HTML

### Pricing Configuration
Cloud provider pricing is configurable in the `getPricing()` function:
- AWS: VM $0.05/hour, Storage $0.01/GB, Network $0.02/GB
- Azure: VM $0.042/hour, Storage $0.015/GB, Network $0.016/GB
- Google: VM $0.048/hour, Storage $0.008/GB, Network $0.025/GB

## API Documentation

### Resource Data Structure
```json
{
  "id": "string",
  "name": "string", 
  "resourceType": "VM|Storage|Network",
  "cpuUsage": "float",
  "memoryUsage": "float", 
  "storageUsage": "float",
  "costPerMonth": "float"
}
```

### AI Suggestion Structure
```json
{
  "resourceId": "string",
  "recommendation": "string",
  "confidence": "High|Medium|Low",
  "potentialSavings": "float",
  "actions": ["string"]
}
```

## Troubleshooting

### Common Issues
1. **Port conflicts**: Ensure ports 8080 and 8081 are available
2. **Authentication issues**: Check internet connection for Google OAuth
3. **Service startup**: Wait for services to fully initialize before accessing

### Debug Mode
Enable debug logging by adding the `--debug` flag:
```bash
bal run --debug landing_page.bal
```

## Contributing
This project was developed for the Innovate with Ballerina 2025 competition. For questions or improvements, please refer to the competition guidelines.


## Team Information
- **Team Name**: CodeBlooded
- **Project**: CloudOptimizer Pro
- **Competition**: Innovate with Ballerina 2025
- **Technology**: Ballerina Swan Lake

## Performance Notes
- The application handles real-time calculations efficiently
- Resource generation is optimized for quick response times
- AI suggestions are computed dynamically based on usage patterns
- All data processing is done in-memory for optimal performance

