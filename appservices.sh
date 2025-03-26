#!/bin/bash

# Ensure a subscription ID is passed
if [ -z "$1" ]; then
    echo "Usage: $0 <Enter Subscription_Id>"
    exit 1
fi

# Assigning the subscription ID from the first argument
_subscriptionId="$1"

# az login
# az account set --subscription "$1"

# # Subscription ID and other variables
# _subscriptionId="ad265e87-5b4c-4c3c-b490-939e5907c6a5"

# HTML output file
html_output="AppServicesRecommdentionaBeta.html"

# Main Execution Flow and function calls

# ====================================================================================
# Region: Fetch App Services Plan Configuration to build recommendations.
#====================================================================================

# Function to generate the App Services Configuration Table
generate_App_Services_Recommendations() {

    # Recommendation Table.
    config_reccommendation_table

    # Fetch web apps list
    _webApps=$(az webapp list --subscription $_subscriptionId --query "[].{name:name, resourceGroup:resourceGroup}" --output jsonc)

    for item in $(echo "$_webApps" | jq -r '.[] | @base64'); do
        _jq() {
            echo ${item} | base64 --decode | jq -r ${1}
        }

        _name=$(_jq '.name')
        _resourceGroup=$(_jq '.resourceGroup')

        # # Fetch app service configuration details
        # _autoHealEnabled=$(az webapp config show --subscription $_subscriptionId --resource-group $_resourceGroup --name $_name --query "autoHealEnabled" --output tsv | grep -q "^true$" && echo "ENABLED" || echo "DISABLED")
        # _healthCheckPath=$(az webapp config show --subscription $_subscriptionId --resource-group $_resourceGroup --name $_name --query "healthCheckPath" --output tsv | grep -q . && echo "ENABLED" || echo "DISABLED")
        # _alwaysOn=$(az webapp config show --subscription $_subscriptionId --resource-group $_resourceGroup --name $_name --query "alwaysOn" --output tsv | grep -q "^true$" && echo "ENABLED" || echo "DISABLED")
        # _minTlsVersion=$(az webapp config show --subscription $_subscriptionId --resource-group $_resourceGroup --name $_name --query "minTlsVersion" --output tsv)
        # _ftpsState=$(az webapp config show --subscription $_subscriptionId --resource-group $_resourceGroup --name $_name --query "ftpsState" --output tsv)

        #!/bin/bash

        # Fetch all required properties in a single API call
        config_json=$(az webapp config show --subscription "$_subscriptionId" --resource-group "$_resourceGroup" --name "$_name" --query "{autoHealEnabled:autoHealEnabled, healthCheckPath:healthCheckPath, alwaysOn:alwaysOn, minTlsVersion:minTlsVersion, ftpsState:ftpsState}" --output json)

        _autoHealEnabled=$(echo "$config_json" | jq -r '.autoHealEnabled' | grep -q "true" && echo "ENABLED" || echo "DISABLED")
        _healthCheckPath=$(echo "$config_json" | jq -r '.healthCheckPath // empty' | grep -q . && echo "ENABLED" || echo "DISABLED")
        _alwaysOn=$(echo "$config_json" | jq -r '.alwaysOn' | grep -q "^true$" && echo "ENABLED" || echo "DISABLED")
        _minTlsVersion=$(echo "$config_json" | jq -r '.minTlsVersion')
        _ftpsState=$(echo "$config_json" | jq -r '.ftpsState')

        # Color formatting based on conditions
        if [[ "$_autoHealEnabled" == "ENABLED" ]]; then
            autoHealColor="<span style='color: #90EE90; font-weight: bold;'> $tick $_autoHealEnabled </span>"
        else
            autoHealColor="<span style='color: #FFD700;font-weight: bold;'> $critical_warning $_autoHealEnabled</span>"
        fi

        if [[ "$_healthCheckPath" == "ENABLED" ]]; then
            healthCheckColor="<span style='color: #90EE90; font-weight: bold;'> $tick $_healthCheckPath</span>"
        else
            healthCheckColor="<span style='color: #FF4C4C;font-weight: bold;'> $urgent_warning $_healthCheckPath</span>"
        fi

        if [[ "$_alwaysOn" == "ENABLED" ]]; then
            alwaysOnColor="<span style='color: #90EE90; font-weight: bold;'> $tick $_alwaysOn</span>"
        else
            alwaysOnColor="<span style='color: #FF4C4C;font-weight: bold;'> $critical_warning $_alwaysOn</span>"
        fi

        if echo "$_minTlsVersion" | grep -qE '^(1\.[2-9]|[2-9]\.[0-9])'; then
            _minTlsVersionStatus="$_minTlsVersion Secure"
        else
            _minTlsVersionStatus="$_minTlsVersion UNSAFE"
        fi

        if [[ "$_minTlsVersionStatus" =~ "Secure" ]]; then
            minTlsVersionColor="<span style='color: #90EE90; font-weight: bold;'> $tick $_minTlsVersionStatus</span>"
        else
            minTlsVersionColor="<span style='color: #FF4C4C;font-weight: bold;'> $urgent_warning $_minTlsVersionStatus</span>"
        fi

        # FTPS State check
        shopt -s nocasematch
        if [[ "$_ftpsState" =~ "FtpsOnly" ]]; then
            ftpStateColor="<span style='color: #FFD700;font-weight: bold;' title='This represents the FTPS state. Recommended setting: FTPS only or Disabled'> $tick $_ftpsState ( RECOMMENDED )</span>"

            # tooltip="<a href=\"https://learn.microsoft.com/en-us/azure/app-service/deploy-ftp?tabs=portal#enforce-ftps\" target=\"_blank\">\
            #         This represents the FTPS state. Recommended setting: FTPS only. If not using FTPs to deploy DISABLE it. \
            #         Click for more info.</a>"
            # ftpStateColor="<span style='color: #FFD700; font-weight: bold;' title=\"$tooltip\">$_ftpsState ( RECOMMENDED )</span>"

        elif

            [[ "$_ftpsState" =~ "AllAllowed" ]]
        then
            ftpStateColor="<span style='color: #FF4C4C;font-weight: bold; 'title='This represents the FTPS state. Recommended setting: FTPS only or Disabled'> $critical_warning $_ftpsState ( UNSAFE )</span>"
        else
            ftpStateColor="<span style='color: #90EE90; font-weight: bold; 'title='This represents the FTPS state. Recommended setting: FTPS only or Disabled'> $tick $_ftpsState ( RECOMMENDED )</span>"

            # ftpStateColor="<span style='color: #FFD700; font-weight: bold;'>$_ftpsState ( RECOMMENDED )</span> \
            # <span style='cursor: pointer; color: #FFD700;' onclick='document.getElementById(\"tooltip\").style.display = \"block\";'>?</span> \
            # <div id='tooltip' style='display: none; position: absolute; background-color: #f5f5f5; border: 1px solid #FFD700; padding: 10px; border-radius: 4px; color: black; width: 250px;'>
            # <a href=\"https://learn.microsoft.com/en-us/azure/app-service/deploy-ftp?tabs=portal#enforce-ftps\" target=\"_blank\" style='color: #000000; text-decoration: none;'>
            #     This represents the FTPS state. Recommended setting: FTPS only. Click for more info.
            # </a>
            # </div>"

        fi
        shopt -u nocasematch
        # Append to the HTML table
        config_reccommendation_table_output

    done

    # wrap the table
    echo "</tbody></table>" >>$html_output
}

# Function to generate App Service Plan Recommendations
generate_app_service_plan_recommendations() {

    # prepare the html recommendation table to fill the information
    generate_app_service_plan_recommendations_table

    # Fetch app service plans list
    app_service_plans=$(az appservice plan list --subscription $_subscriptionId --query "[].{Name:name, ResourceGroup:resourceGroup, ZoneRedundant:zoneRedundant}" --output tsv)

    # Track if we should display the recommendation for zero-app service plans
    _diplayAppServicePlanRecommendations_cost=0

    while IFS=$'\t' read -r name resource_group zoneEnabled; do
        webapp_count=$(az webapp list --subscription $_subscriptionId --query "[?appServicePlanId=='/subscriptions/$_subscriptionId/resourceGroups/$resource_group/providers/Microsoft.Web/serverfarms/$name'] | length(@)" -o tsv)
        az webapp list --subscription c5efbe49-8037-4fd2-881f-daf1e40b94ac --query "[?appServicePlanId=='/subscriptions/c5efbe49-8037-4fd2-881f-daf1e40b94ac/resourceGroups/PowerBIRG/providers/Microsoft.Web/serverfarms/ASP-PowerBIRG-ab69'] | length(@)"

        webapp_info=$(az appservice plan show --name $name --subscription $_subscriptionId --resource-group $resource_group --query "{tier:sku.tier, size:sku.name, workers:sku.capacity}" --output json)

        webapp_worker=$(echo "$webapp_info" | jq -r '.workers')
        webapp_size=$(echo "$webapp_info" | jq -r '.size')
        webapp_tier=$(echo "$webapp_info" | jq -r '.tier')

        # Determine the recommended number of apps based on the plan size
        if [[ "$webapp_size" =~ ^(B1|S1|P1v2|I1v1|P0v3|P1)$ ]]; then
            recommended_apps="8"
            if [ "$webapp_count" -gt 8 ]; then
                webapp_count="<span style='color: #FF4C4C;font-weight: bold;'> $webapp_count ( Beyond Recommended Limit )</span>"
            fi
        elif [[ "$webapp_size" =~ ^(B2|S2|P2v2|I2v1|P2)$ ]]; then
            recommended_apps="16"
            if [ "$webapp_count" -gt 16 ]; then
                webapp_count="<span style='color: #FF4C4C;font-weight: bold;'> $webapp_count ( Beyond Recommended limit )</span>"
            fi
        elif [[ "$webapp_size" =~ ^(B3|S3|P3v2|I3v1|P3)$ ]]; then
            recommended_apps="32"
            if [ "$webapp_count" -gt 32 ]; then
                webapp_count="<span style='color: #FF4C4C;font-weight: bold;'> $webapp_count ( Beyond Recommended limit )</span>"
            fi
        elif [[ "$webapp_size" =~ ^(P1v3|I1v2)$ ]]; then
            recommended_apps="16"
            if [ "$webapp_count" -gt 16 ]; then
                webapp_count="<span style='color: #FF4C4C;font-weight: bold;'> $webapp_count ( Beyond Recommended limit )</span>"
            fi
        elif [[ "$webapp_size" =~ ^(P2v3|I2v2)$ ]]; then
            recommended_apps="32"
            if [ "$webapp_count" -gt 32 ]; then
                webapp_count="<span style='color: #FF4C4C;font-weight: bold;'> $webapp_count ( Beyond Recommended limit )</span>"
            fi
        elif [[ "$webapp_size" =~ ^(P3v3|I3v2)$ ]]; then
            recommended_apps="64"
            if [ "$webapp_count" -gt 64 ]; then
                webapp_count="<span style='color: #FF4C4C;font-weight: bold;'> $webapp_count ( Beyond Recommended limit )</span>"
            fi
        elif [[ "$webapp_size" =~ ^(EP1|Y1)$ ]]; then
            recommended_apps="N/A"
        elif [[ "$webapp_size" =~ ^(Y1)$ ]]; then
            recommended_apps="N/A"
            webapp_count="N/A"
        fi

        # Zone redundancy
        shopt -s nocasematch
        if [[ "$zoneEnabled" =~ ^true$ ]]; then
            zone_Enabled="<span style='color: #90EE90; font-weight: bold;'>$zoneEnabled</span>"
        else
            zone_Enabled="<span style='color: #FFD700;font-weight: bold;'>$zoneEnabled</span>"
        fi
        shopt -u nocasematch

        # Density recommendation section if no apps in service plan
        if [ "$webapp_count" -eq 0 ]; then
            if [[ "$webapp_size" =~ ^(Y1)$ ]]; then
                webapp_count="N/A"
            else
                webapp_count="<span style='color: #FF4C4C;font-weight: bold;'>Server farm: $webapp_count ( EMPTY PLAN - Review and Delete )</span>"
            fi
        fi

        # Density recommendation section if no apps in service plan
        if [ "$webapp_worker" -eq 1 ]; then

            if [[ "$webapp_size" =~ ^(B1|B2|B3|D1|F1)$ ]]; then
                webapp_worker="<span style='color: #90EE90;'>$webapp_worker</span>"
            else
                webapp_worker="<span style='color: #FF4C4C;font-weight: bold;'> $webapp_worker ( PROD ENV - Recommended >= 2 Instances ) </span>"
            fi
        else
            webapp_worker="<span style='color: #90EE90;'>$webapp_worker</span>"
        fi

        if [[ "$webapp_size" =~ ^(B1|B2|B3|D1|F1)$ ]]; then
            webapp_tier="<span style='color: #FF4C4C;font-weight: bold;'> $webapp_tier ( DEV/TEST SKU )</span>"
        else
            webapp_tier="<span style='color: #90EE90;'> $webapp_tier ( PROD SKU )</span>"
        fi

        # Output the information to the HTML table
        generate_app_service_plan_recommendations_table_output

    done <<<"$app_service_plans"

    #wrap the table
    echo "</tbody></table>" >>$html_output
}

generate_summary() {
    summary_table
    # Get the count of App Services
    app_service_count=$(az webapp list --subscription $_subscriptionId --query "length([])" --output tsv)
    # Get the count of App Service Plans
    app_service_plan_count=$(az appservice plan list --subscription $_subscriptionId --query "length([])" --output tsv)
    summary_table_output

    #wrap the table
    echo "</tbody></table>" >>$html_output

}

# ====================================================================================
# Region: Prepare HTML and plug the html with the CLI responses.
#====================================================================================

# Define color codes for formatting
BOLD=$(tput bold)
RESET=$(tput sgr0)
RED='\033[0;31m'
BRIGHTRED='\e[91m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BORDER="\e[47m\e[30m"
color_enabled="\e[32m"
color_disabled="\e[93;1m"
color_reset="\e[0m"

green_i="\e[32m"
red_i="\e[31m"
yellow_i="\e[33m"
reset="\e[0m"

# Symbols
# tick=" ( ✔ ) "
# recomm=""
# cross="❌"
# urgent_warning=" ( 🚨 ) "
# critical_warning=" (❗)"

tick=""
recomm=""
cross=""
urgent_warning=""
critical_warning=""

initialize_html() {
    cat <<EOF >$html_output
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure App Service Recommendations</title>
    <style>
        body { 
            font-family: 'Verdana', sans-serif; 
            font-size: 12px; 
            margin: 0; 
            padding: 20px; 
            background-color: #1E2A38; 
            color: #E0E0E0; 
        }
        h2 { 
            text-align: center; 
            color: #FFFFFF; 
            font-size: 20px; 
            font-weight: bold; 
        }
        h3 { 
            color: #A0C4FF; 
            font-size: 14px; 
            font-weight: bold; 
            text-align: left; 
        }
        p { 
            font-size: 12px; 
            color: #B0B0B0; 
            line-height: 1.5; 
        }
        table { 
            width: 80%; 
            border-collapse: collapse; 
            margin: 20px auto; 
            font-size: 12px; 
        }
        th, td { 
            padding: 8px; 
            text-align: left; 
            border: 1px solid #5A5A5A; 
        }
        th { 
            background-color: #334D66; 
            color: white; 
            text-align: center; 
            font-size: 13px; 
        }
        tr:nth-child(even) { 
            background-color: #293C4E; 
        }
        a { 
            color: #69B0E2; 
            text-decoration: underline; 
            font-weight: bold; 
        }
        a:hover { 
            color: #FFFFFF; 
        }
    </style>
</head>
<body>
    <h2>Azure App Service Configuration Recommendations</h2>
EOF
}

config_reccommendation_table() {

    cat <<EOF >>$html_output
<table>
    <thead>
        <tr>
            <th>APP SERVICE NAME</th>
            <th>AUTO HEAL</th>
            <th>HEALTH CHECK</th>
            <th>ALWAYS ON</th>
            <th>TLS Secure?</th>
            <th>FTPs State</th>
        </tr>
    </thead>
    <tbody>
EOF
}

summary_table() {
    cat <<EOF >>$html_output
<div style="display: flex; justify-content: center; gap: 20px;">

    <table style="width: 30%; border-collapse: collapse; text-align: left;">
        <thead>
            <tr>
                <th style="width: 50%;">Parameter</th>
                <th style="width: 50%;">Value</th>
            </tr>
        </thead>
        <tbody>
EOF
}

# summary_table_output() {
#     cat <<EOF >>$html_output
#         <tr>
#             <td><b>SUBSCRIPTION ID</b></td>
#             <td>$_subscriptionId</td>
#         </tr>
#         <tr>
#             <td><b>APP SERVICE PLAN COUNT</b></td>
#             <td>$app_service_plan_count</td>
#         </tr>
#         <tr>
#             <td><b>APP SERVICE COUNT</b></td>
#             <td>$app_service_count</td>
#         </tr>
#         </tbody></table>
# EOF
# }

# user_information() {
#     cat <<EOF >>$html_output
#     <table style="width: 30%; border-collapse: collapse; text-align: center;">
#         <tbody>
#             <tr>
#                 <td style="padding: 15px; font-weight: bold;">Single Cell Table Content</td>
#             </tr>
#         </tbody>
#     </table>
# EOF
# }

# legends_meaning() {
#     cat <<EOF >>$html_output
#     <table style="width: 30%; border-collapse: collapse; text-align: left;">
#         <thead>
#             <tr>
#                 <th style="width: 50%;">Category</th>
#                 <th style="width: 50%;">Details</th>
#             </tr>
#         </thead>
#         <tbody>
#             <tr>
#                 <td><b>Example Row</b></td>
#                 <td>Example Content</td>
#             </tr>
#         </tbody>
#     </table>

# </div> <!-- Closing div for flex row -->
# EOF
# }

summary_table() {

    cat <<EOF >>$html_output
<table>
    <thead>
        <tr>
            <th>SUBSCRIPTION ID</th>
            <th>APP SERVICE PLAN COUNT</th>
            <th>APP SERVICE COUNT</th>
        </tr>
    </thead>
    <tbody>
EOF
}

summary_table_output() {
    cat <<EOF >>$html_output
<tr>
    <td>$_subscriptionId</td>
    <td>$app_service_count</td>
    <td>$app_service_plan_count</td>
   </tr>
EOF

}

config_reccommendation_table_output() {
    cat <<EOF >>$html_output
<tr>
    <td>$_name</td>
    <td>$autoHealColor</td>
    <td>$healthCheckColor</td>
    <td>$alwaysOnColor</td>
    <td>$minTlsVersionColor</td>
    <td>$ftpStateColor</td>
</tr>
EOF

}

# Finalize the HTML structure and footer
finalize_html() {
    echo "</body></html>" >>$html_output
}

generate_app_service_plan_recommendations_table() {
    cat <<EOF >>$html_output
<table>
    <thead>
        <tr>
            <th>APP SERVICE PLAN</th>
            <th>SIZE</th>
            <th>TIER</th>
            <th>INSTANCE COUNT</th>
            <th>RECOMMENDED APPS COUNT</th>
            <th>CURRENT APPS COUNT</th>
            <th>Zone Enabled</th>
        </tr>
    </thead>
    <tbody>
EOF

}

generate_app_service_plan_recommendations_table_output() {
    cat <<EOF >>$html_output
<tr>
    <td>${name}</td>
    <td>${webapp_size}</td>
    <td>${webapp_tier}</td>
    <td>${webapp_worker}</td>
    <td>${recommended_apps}</td>
    <td>${webapp_count}</td>
    <td>${zone_Enabled}</td>
</tr>
EOF
}

generate_best_practices_reference() {
    cat <<EOF >>$html_output
<h2> Best Practices References</h2>
<table>
    <thead>
        <tr>
            <th>Category</th>
            <th>Description</th>
            <th>Reference</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>Auto Heal</td>
            <td>Auto Heal allows your app to automatically restart when it encounters performance or availability issues. 
                You can configure rules based on request count, memory usage, HTTP status codes, and more to trigger an automatic recovery.<br><br>
                This ensures high availability by proactively addressing failures before they impact users.
            </td>
            <td><a href="https://azure.github.io/AppService/2018/09/10/Announcing-the-New-Auto-Healing-Experience-in-App-Service-Diagnostics.html" target="_blank">Learn More</a></td>
        </tr>
        <tr>
            <td>Health Check</td>
            <td>Health Check continuously monitors your app's status by pinging a specific endpoint. If an instance is unresponsive, 
                Azure App Service automatically removes it from the load balancer rotation and replaces it if needed.<br><br>
                Implementing a health check helps ensure that only healthy instances serve user requests, reducing downtime.
            </td>
            <td><a href="https://learn.microsoft.com/en-us/azure/app-service/monitor-instances-health-check" target="_blank">Learn More</a></td>
        </tr>
        <tr>
            <td>Always On</td>
            <td>When Always On is enabled, your application remains active at all times, preventing it from going idle. 
                This eliminates cold start delays and ensures faster response times for incoming requests.<br><br>
                Always On is recommended for production apps that require consistent performance and immediate availability.
            </td>
            <td><a href="https://learn.microsoft.com/en-us/azure/app-service/configure-common" target="_blank">Learn More</a></td>
        </tr>
        <tr>
            <td>Density Check</td>
            <td>Density Check helps you optimize resource allocation by analyzing the number of applications running within an App Service Plan. 
                Running too many apps on a single plan can lead to performance degradation.<br><br>
                Regularly reviewing density ensures a balance between cost and performance, helping you allocate resources efficiently.
            </td>
            <td><a href="https://azure.github.io/AppService/2019/05/21/App-Service-Plan-Density-Check.html" target="_blank">Learn More</a></td>
        </tr>
    </tbody>
</table>
EOF
}

# ====================================================================================
# Region: Main Execution Flow and function calls
#====================================================================================
#!/bin/bash

# # Define Colors for Output
# GREEN="\033[1;32m"
# YELLOW="\033[1;93m"
# CYAN="\033[1;36m"
# RESET="\033[0m"

# # Function to execute a stage and suppress unwanted output
# run_stage() {
#     local stage_name="$1"
#     shift
#     local command_to_run="$@"

#     echo -e "${CYAN}▶ $stage_name...${RESET}"
    
#     # Run the command and suppress unwanted output
#     eval "$command_to_run" >/dev/null 2>&1

#     # Check if the command was successful
#     if [ $? -eq 0 ]; then
#         echo -e "${GREEN}✔ $stage_name completed!${RESET}\n"
#     else
#         echo -e "${YELLOW}⚠ Warning: $stage_name encountered an issue!${RESET}\n"
#     fi
# }

# # Run each stage in order
# run_stage "Initializing HTML" initialize_html
# run_stage "Generating Summary" generate_summary
# run_stage "Generating App Service Recommendations" generate_App_Services_Recommendations
# run_stage "Generating App Service Plan Recommendations" generate_app_service_plan_recommendations
# run_stage "Finalizing HTML" finalize_html
# run_stage "Generating Best Practices References" generate_best_practices_reference

# # Completion message
# echo -e "${YELLOW}🎉 Report generated successfully!${RESET}"



# Define Colors for Output
GREEN="\033[1;32m"
YELLOW="\033[1;93m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Function to execute a stage with a spinner animation
run_stage() {
    local stage_name="$1"
    shift
    local command_to_run="$@"

    echo -ne "${CYAN}▶ $stage_name... ${RESET}"

    # Run the command in the background
    eval "$command_to_run" >/dev/null 2>&1 & 
    local pid=$!

    # Spinner animation while the command runs
    local spin_chars=("⠋" "⠙" "⠚" "⠛" "⠓" "⠒" "⠂")
    local spin_index=0

    while ps -p $pid &>/dev/null; do
        echo -ne "\r${CYAN}▶ $stage_name... ${spin_chars[$spin_index]}${RESET} "
        spin_index=$(( (spin_index + 1) % ${#spin_chars[@]} ))
        sleep 0.2  # Controls animation speed
    done

    wait $pid  # Ensure the process completes

    # Print completion message (overwrite previous line)
    echo -e "\r${GREEN}✔ $stage_name completed!${RESET}   "
}

# Run each stage in order
run_stage "Initializing HTML" initialize_html
run_stage "Generating Summary" generate_summary
run_stage "Generating App Service Recommendations" generate_App_Services_Recommendations
run_stage "Generating App Service Plan Recommendations" generate_app_service_plan_recommendations
run_stage "Finalizing HTML" finalize_html
run_stage "Generating Best Practices References" generate_best_practices_reference

# Completion message
echo -e "\n${YELLOW}🎉 Report generated successfully!${RESET}, $html_output"

