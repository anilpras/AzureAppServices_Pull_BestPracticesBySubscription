
# How to run

dos2unix RecommendationBestPractices.sh  (you may need to use this or may not be )

./RecommendationBestPractices.sh "<pass_subscription_id>"

# App Services Best Practices Script

This Bash script retrieves and displays App Service and App Service Plan configurations in Azure. It provides actionable recommendations based on best practices, with a focus on optimizing settings and reducing costs. Below is an overview of the script's functionality:

## Features

1. **App Service Configuration**:
   - Lists all web apps in a subscription and checks the following settings for each:
     - **Auto Heal**: Indicates if auto-heal is enabled.
     - **Health Check**: Verifies if a health check path is configured.
     - **Always On**: Checks if Always On is enabled.
   - Displays the configuration status with color coding (green for "ENABLED" and red for "DISABLED").

2. **App Service Plan Configuration**:
   - Retrieves and lists all App Service Plans.
   - For each plan, checks the number of web apps assigned to it.
   - Displays the plan's **tier**, **size**, and **worker capacity**.
   
3. **Recommendations**:
   - **Density Check**: Flags App Service Plans with more web apps than the recommended capacity, suggesting possible density optimization.
   - **Cost Recommendations**: Flags App Service Plans with no web apps for potential deletion to reduce costs.

## Usage

1. Ensure you have the Azure CLI installed and authenticated with your Azure subscription.
2. Set the `_subscriptionId` variable to the desired Azure subscription ID.
3. Run the script to retrieve configurations and recommendations for your App Services and App Service Plans.

## Example Output

The script outputs tables that include the following information:

![image](https://github.com/user-attachments/assets/dbba7f39-efb8-44d2-a441-2ee77d195282)

