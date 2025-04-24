# Azure App Services: Best Practices Script

A Bash script to analyze and recommend best practices for Azure App Services and App Service Plans. This tool provides actionable insights to optimize configurations, enhance performance, and reduce costs across your Azure subscriptions.

---

## Table of Contents
1. [Key Features](#key-features)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Usage Instructions](#usage-instructions)
5. [Example Output](#example-output)
6. [Script Details](#script-details)
7. [License](#license)
8. [Contact](#contact)

---

## Key Features

### 1. App Service Configuration:
- Lists all web apps within a subscription and evaluates the following settings:
  - **Auto Heal**: Checks if auto-heal is enabled.
  - **Health Check**: Verifies if a health check path is configured.
  - **Always On**: Ensures the "Always On" setting is activated.
  - **TLS Version**: Ensures the "Always On" setting is activated.
  - **FTP State**: Ensures the "Always On" setting is activated.
- Displayed with a color-coded representation:
  - Green: **All good**
  - Red: **Need Attention**
  - Yellow: **Good to have but based on specific condition and requirement**

### 2. App Service Plan Configuration:
- Retrieves and lists all App Service Plans within the subscription.
- Provides details for each plan, including:
  - **Tier**
  - **Size**
  - **Instance Count**
  - **Recommended Apps Count**.
  - **Zone Information**
  - **App Service Plan CPU & Memory Utilization**

### 3. Recommendations:
- **Density Optimization**: Flags App Service Plans with more web apps than the recommended capacity.
- **Cost Reduction**: Identifies unused App Service Plans for potential deletion.

---

## Prerequisites
1. Azure CLI installed and authenticated or run it from the azure portal.
2. Access to Azure subscriptions with appropriate permissions.
3. A Bash shell environment (Linux/macOS or Windows with WSL).
4. [Script link](https://github.com/anilpras/AzureAppServices_Pull_BestPracticesBySubscription/blob/main/appservices.sh).

---

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/anilpras/AzureAppServices_Pull_BestPracticesBySubscription.git
   ```
2. Upload the script file to your execution environment (e.g., Azure Portal or local system).
3. Grant execution permissions:
   ```bash
   chmod +x script.sh
   ```
4. (Optional) Convert the file format if needed:
   ```bash
   dos2unix script.sh
   ```

---

## Usage Instructions
1. Run the script with the following syntax:
   ```bash
   ./script.sh "<subscription_id>" "<0 or 1>"
   ```
   - `0`: Recommended settings (does not generate CPU and Memory Utilization).
   - `1`: Includes additional CPU and Memory Utilization details.

2. Download the generated output file. The output file will be named `AppServicesRecommendationBeta.html`.

---

## Example Output

The script provides outputs in HTML format, visually representing the configurations and recommendations. Below are sample screenshots of the output:

**App Service Configuration Example:**

![App Service Configuration Example](https://github.com/user-attachments/assets/e649d4bd-81df-4a8d-9fdd-94e69ac52e56)

**App Service Plan Configuration Example:**

![App Service Plan Configuration Example](https://github.com/user-attachments/assets/80c394a4-3dad-4c9a-9316-975063c3f958)

---

## Script Details

This Bash script is designed to retrieve and display configurations for Azure App Services and App Service Plans. Its primary focus is on identifying misconfigurations and providing actionable recommendations.

### Features:
- **Automation**: Fully automated script requiring minimal user input.
- **Scalability**: Handles multiple App Services and App Service Plans across subscriptions.
- **Output**: Generates an easy-to-read HTML report for analysis.

---

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Contact
For support or inquiries, please reach out via [GitHub Issues](https://github.com/anilpras/AzureAppServices_Pull_BestPracticesBySubscription/issues).

---
