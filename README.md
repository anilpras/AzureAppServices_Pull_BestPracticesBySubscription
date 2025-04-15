
# How to run

In below example Azure Portal has been used to run the script file. Please be noted, we haven't tested this in different version of bash.
**script link - https://github.com/anilpras/AzureAppServices_Pull_BestPracticesBySubscription/blob/main/appservices.sh **

STEP#1 --> Upload the scriptfile e.g. in this case i used a file name to be **script.sh**

STEP#2 --> **chmod +x script.sh**

STEP#3 --> **dos2unix script.sh**  (you may need to use this or may not be )

STEP#4 --> **./script.sh "<pass_subscription_id>" "<0 or 1>"** // 0 - Recommended, do not generate CPU and Memory Utilizaiton

STEP#5 --> download the generated file in this case it is **AppServicesRecommdentionaBeta.html**

![image](https://github.com/user-attachments/assets/be024096-88e3-420a-bbe7-05292c9601a6)

## Example Output

The script outputs tables that include the following information:

![image](https://github.com/user-attachments/assets/e649d4bd-81df-4a8d-9fdd-94e69ac52e56)

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




