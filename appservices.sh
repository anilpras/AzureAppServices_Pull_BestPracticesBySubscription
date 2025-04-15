#!/bin/bash

# Ensure a subscription ID is passed
if [ -z "$1" ]; then
    echo "Usage: $0 <Enter Subscription_Id>"
    exit 1
fi

# Assigning the subscription ID from the first argument
_subscriptionId="$1"

if [ -z "$2" ]; then
    echo "ResourceUtilization argument is required (either 0 or 1)."
    exit 1
fi

_resourceUtilizationDetailsRequired="$2"

# Validate the second argument (should be 0 or 1)
if [[ "$_resourceUtilizationDetailsRequired" != "0" && "$_resourceUtilizationDetailsRequired" != "1" ]]; then
    echo "Error: The second argument must be either 0 or 1."
    exit 1
fi

#If FileName has passed
if [ -z "$3" ]; then
    # HTML output file
    html_output="AppServicesRecommdentionaBeta.html"
else
    html_output="$3"
fi

# Dark Theme
error_red_color='#FF4C4C'
warning_orage_color='#FFD700'
all_good_green_color='#90EE90'

#Light Theme
# error_red_color="#8B0000"
# warning_orage_color='#FF8C00'
# all_good_green_color='#228B22'


# Function to generate the App Services Configuration Table
generate_App_Services_Recommendations() {

    # Generate the HTML Table & Cell.
    config_reccommendation_table "APP SERVICE NAME" "RESOURCE GROUP" "LOCATION" "KIND?" "AUTO HEAL?" "HEALTH CHECK?" "ALWAYS ON?" "TLS Secure?" "FTPs State?"

    # Fetch web apps list
    local _webApps=$(az resource list --subscription $_subscriptionId --resource-type "Microsoft.Web/sites" --query "[].{CreateTime:createdTime, Name:name, Location:location, Kind:kind, ResourceGroup:resourceGroup} | sort_by(@, &Name)" --output jsonc)

    for item in $(echo "$_webApps" | jq -r '.[] | @base64'); do
        _jq() {
            echo ${item} | base64 --decode | jq -r "${1}"
        }

        # Extract the relevant fields using jq
        local _createTimeUnformated=$(_jq '.CreateTime' | cut -d '+' -f1)
        local _createTime=$(date -d "$_createTimeUnformated" +"%Y-%m-%dT%H:%M")
        local _name=$(_jq '.Name')
        local _location=$(_jq '.Location')
        local _kind=$(_jq '.Kind')
        local _resourceGroup=$(_jq '.ResourceGroup')

        # Fetch all required properties in a single API call
        local config_json=$(az webapp show --subscription "$_subscriptionId" --resource-group "$_resourceGroup" --name "$_name" --query "{autoHealEnabled:siteConfig.autoHealEnabled, healthCheckPath:siteConfig.healthCheckPath, alwaysOn:siteConfig.alwaysOn, minTlsVersion:siteConfig.minTlsVersion, ftpsState:siteConfig.ftpsState}" --output json)

        local _autoHealEnabled=$(echo "$config_json" | jq -r '.autoHealEnabled' | grep -q "true" && echo "ENABLED" || echo "DISABLED")
        local _healthCheckPath=$(echo "$config_json" | jq -r '.healthCheckPath // empty' | grep -q . && echo "ENABLED" || echo "DISABLED")
        local _alwaysOn=$(echo "$config_json" | jq -r '.alwaysOn' | grep -q "^true$" && echo "ENABLED" || echo "DISABLED")
        local _minTlsVersion=$(echo "$config_json" | jq -r '.minTlsVersion')
        local _ftpsState=$(echo "$config_json" | jq -r '.ftpsState')

        local _autoHealWithColor
        local _healthCheckWithColor
        local _alwaysOnWithColor
        local _minTlsVersionStatus
        local _minTLSVersionWithColor
        local _ftpsStateWithColor

        # AutoHeal Check
        if [[ "$_autoHealEnabled" == "ENABLED" ]]; then
            _autoHealWithColor="<span style='color: $all_good_green_color; font-weight: bold;'> $tick $_autoHealEnabled </span>"
        else
            _autoHealWithColor="<span style='color: $warning_orage_color;font-weight: bold;'> $critical_warning $_autoHealEnabled</span>"
        fi

        # Health Check
        if [[ "$_healthCheckPath" == "ENABLED" ]]; then
            _healthCheckWithColor="<span style='color: $all_good_green_color; font-weight: bold;'> $tick $_healthCheckPath</span>"
        else
            _healthCheckWithColor="<span style='color: $error_red_color;font-weight: bold;'> $urgent_warning $_healthCheckPath</span>"
        fi

        # Always On Check
        if [[ "$_alwaysOn" == "ENABLED" ]]; then
            _alwaysOnWithColor="<span style='color: $all_good_green_color; font-weight: bold;'> $tick $_alwaysOn</span>"
        else
            _alwaysOnWithColor="<span style='color: $error_red_color;font-weight: bold;'> $critical_warning $_alwaysOn</span>"
        fi

        # TLS version check
        if echo "$_minTlsVersion" | grep -qE '^(1\.[2-9]|[2-9]\.[0-9])'; then
            _minTlsVersionStatus="$_minTlsVersion Secure"
        else
            _minTlsVersionStatus="$_minTlsVersion UNSAFE"
        fi

        if [[ "$_minTlsVersionStatus" =~ "Secure" ]]; then
            _minTLSVersionWithColor="<span style='color: $all_good_green_color; font-weight: bold;'> $tick $_minTlsVersionStatus</span>"
        else
            _minTLSVersionWithColor="<span style='color: $error_red_color;font-weight: bold;'> $urgent_warning $_minTlsVersionStatus</span>"
        fi

        # FTPS State check
        shopt -s nocasematch
        if [[ "$_ftpsState" =~ "FtpsOnly" ]]; then
            _ftpsStateWithColor="<span style='color: $warning_orage_color;font-weight: bold;' title='This represents the FTPS state. Recommended setting: FTPS only or Disabled'> $tick $_ftpsState ( RECOMMENDED )</span>"
        elif
            [[ "$_ftpsState" =~ "AllAllowed" ]]
        then
            _ftpsStateWithColor="<span style='color: $error_red_color;font-weight: bold; 'title='This represents the FTPS state. Recommended setting: FTPS only or Disabled'> $critical_warning $_ftpsState ( UNSAFE )</span>"
        else
            _ftpsStateWithColor="<span style='color: $all_good_green_color; font-weight: bold; 'title='This represents the FTPS state. Recommended setting: FTPS only or Disabled'> $tick $_ftpsState ( RECOMMENDED )</span>"

        fi

        # Recommendation Table - Fill the Table
        shopt -u nocasematch
        config_reccommendation_table_output "$_name" "$_resourceGroup" "$_location" "$_kind" "$_autoHealWithColor" "$_healthCheckWithColor" "$_alwaysOnWithColor" "$_minTLSVersionWithColor" "$_ftpsStateWithColor"

    done

    # wrap the table
    echo "</tbody></table>" >>$html_output
}


# Function to generate App Service Plan Recommendations
generate_app_service_plan_recommendations() {

    # prepare the html recommendation table to fill the information

    generate_app_service_plan_recommendations_table \
    "APP SERVICE PLAN" "SIZE" "TIER" "INSTANCE COUNT" \
    "RECOMMENDED APPS COUNT" "CURRENT APPS COUNT" "Zone Enabled" "CPU & Memory"

    # Fetch app service plans list
    local _app_Service_Plan=$(az appservice plan list --subscription $_subscriptionId --query "[].{Name:name, ResourceGroup:resourceGroup, ZoneRedundant:zoneRedundant}" --output tsv)

    # Track if we should display the recommendation for zero-app service plans
    local _diplayAppServicePlanRecommendations_cost=0

    local _iCount=0
    while IFS=$'\t' read -r name resource_group zoneEnabled; do
        local webapp_count=$(az webapp list --subscription $_subscriptionId --query "[?appServicePlanId=='/subscriptions/$_subscriptionId/resourceGroups/$resource_group/providers/Microsoft.Web/serverfarms/$name'] | length(@)" -o tsv)
        local webapp_info=$(az appservice plan show --name $name --subscription $_subscriptionId --resource-group $resource_group --query "{tier:sku.tier, size:sku.name, workers:sku.capacity}" --output json)

        local webapp_worker=$(echo "$webapp_info" | jq -r '.workers')
        local webapp_size=$(echo "$webapp_info" | jq -r '.size')
        local webapp_tier=$(echo "$webapp_info" | jq -r '.tier')
        local _zoneEnabledColor
        local _graphCPUMemory

        # Determine the recommended number of apps based on the plan size
        if [[ "$webapp_size" =~ ^(B1|S1|P1v2|I1v1|P0v3|P1)$ ]]; then
            recommended_apps="8"
            if [ "$webapp_count" -gt 8 ]; then
                webapp_count="<span style='color: $error_red_color;font-weight: bold;'> $webapp_count ( Beyond Recommended Limit )</span>"
            fi
        elif [[ "$webapp_size" =~ ^(B2|S2|P2v2|I2v1|P2)$ ]]; then
            recommended_apps="16"
            if [ "$webapp_count" -gt 16 ]; then
                webapp_count="<span style='color: $error_red_color;font-weight: bold;'> $webapp_count ( Beyond Recommended limit )</span>"
            fi
        elif [[ "$webapp_size" =~ ^(B3|S3|P3v2|I3v1|P3)$ ]]; then
            recommended_apps="32"
            if [ "$webapp_count" -gt 32 ]; then
                webapp_count="<span style='color: $error_red_color;font-weight: bold;'> $webapp_count ( Beyond Recommended limit )</span>"
            fi
        elif [[ "$webapp_size" =~ ^(P1v3|I1v2)$ ]]; then
            recommended_apps="16"
            if [ "$webapp_count" -gt 16 ]; then
                webapp_count="<span style='color: $error_red_color;font-weight: bold;'> $webapp_count ( Beyond Recommended limit )</span>"
            fi
        elif [[ "$webapp_size" =~ ^(P2v3|I2v2)$ ]]; then
            recommended_apps="32"
            if [ "$webapp_count" -gt 32 ]; then
                webapp_count="<span style='color: $error_red_color;font-weight: bold;'> $webapp_count ( Beyond Recommended limit )</span>"
            fi
        elif [[ "$webapp_size" =~ ^(P3v3|I3v2)$ ]]; then
            recommended_apps="64"
            if [ "$webapp_count" -gt 64 ]; then
                webapp_count="<span style='color: $error_red_color;font-weight: bold;'> $webapp_count ( Beyond Recommended limit )</span>"
            fi
        elif [[ "$webapp_size" =~ ^(EP1|EP2|EP3|Y1)$ ]]; then
            recommended_apps="N/A"
        elif [[ "$webapp_size" =~ ^(Y1)$ ]]; then
            recommended_apps="N/A"
            webapp_count="N/A"
        fi

        # Zone redundancy
        shopt -s nocasematch
        if [[ "$zoneEnabled" =~ ^true$ ]]; then
            _zoneEnabledColor="<span style='color: $all_good_green_color; font-weight: bold;'>$zoneEnabled</span>"
        else
            _zoneEnabledColor="<span style='color: $warning_orage_color;font-weight: bold;'>$zoneEnabled</span>"
        fi
        shopt -u nocasematch

        # Density recommendation section if no apps in service plan
        if [ "$webapp_count" -eq 0 ]; then
            if [[ "$webapp_size" =~ ^(EP1|EP2|EP3|Y1)$ ]]; then
                webapp_count="N/A"
            else
                webapp_count="<span style='color: $error_red_color;font-weight: bold;'>Server farm: $webapp_count ( EMPTY PLAN - Review and Delete )</span>"
            fi
        fi

        # Density recommendation section if no apps in service plan
        if [ "$webapp_worker" -eq 1 ]; then

            if [[ "$webapp_size" =~ ^(B1|B2|B3|D1|F1)$ ]]; then
                webapp_worker="<span style='color: $all_good_green_color;'>$webapp_worker</span>"
            else
                webapp_worker="<span style='color: $error_red_color;font-weight: bold;'> $webapp_worker ( PROD ENV - Recommended >= 2 Instances ) </span>"
            fi
        else
            webapp_worker="<span style='color: $all_good_green_color;'>$webapp_worker</span>"
        fi

        if [[ "$webapp_size" =~ ^(B1|B2|B3|D1|F1)$ ]]; then
            webapp_tier="<span style='color: $error_red_color;font-weight: bold;'> $webapp_tier ( DEV/TEST SKU )</span>"
        else
            webapp_tier="<span style='color: $all_good_green_color;'> $webapp_tier ( PROD SKU )</span>"
        fi

        ## Calling App Service Plan CPU and Memory Details
        if [[ "$_resourceUtilizationDetailsRequired" -eq 1 ]]; then
            _iCount=$((_iCount + 1))
            _graphCPUMemory=$(generate_resource_utilization_graph "$name" "$resource_group" "$_subscriptionId" "$_iCount")
        else
            _graphCPUMemory="Resource Utilization Skipped."
        fi

        generate_app_service_plan_recommendations_table_output \
        "$name" "$webapp_size" "$webapp_tier" "$webapp_worker" \
        "$recommended_apps" "$webapp_count" "$_zoneEnabledColor" "$_graphCPUMemory"

    done <<<"$_app_Service_Plan"

    #wrap the table
    echo "</tbody></table>" >>$html_output
}

generate_summary() {

    # Get the count of App Services and App Service Plan
    local app_service_count=$(az resource list --subscription $_subscriptionId --query "[?type=='Microsoft.Web/sites'] | length(@)" --output tsv)
    local app_service_plan_count=$(az appservice plan list --subscription $_subscriptionId --query "length([])" --output tsv)

    summary_table "SUBSCRIPTION ID" "APP SERVICE PLAN COUNT" "APP SERVICE COUNT"
    summary_table_output "$_subscriptionId" "$app_service_plan_count" "$app_service_count"

    #wrap the table
    echo "</tbody></table>" >>$html_output

}


generate_resource_utilization_graph() {
    local __name="$1"
    local __resource_group="$2"
    local __subscription_id="$3"
    local __canvas_id="$4"

    local __RESOURCE_ID="/subscriptions/$__subscription_id/resourceGroups/$__resource_group/providers/Microsoft.Web/serverfarms/$__name"
    local __START_TIME=$(date -u -d "24 hours ago" +%Y-%m-%dT%H:%M:%SZ)
    local __END_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    local __METRICS_DATA=$(
        az monitor metrics list \
        --resource "$__RESOURCE_ID" \
        --metric "CpuPercentage,MemoryPercentage" \
        --interval PT1M \
        --aggregation Average \
        --start-time "$__START_TIME" \
        --end-time "$__END_TIME" \
        --output json
    )

    local __TIMESTAMPS=$(
        echo "$__METRICS_DATA" | jq -r '
        .value[0].timeseries[0].data[] 
        | select(.average != null) 
        | .timeStamp' | jq -R -s -c 'split("\n")[:-1]'
    )

    local __CPU_VALUES=$(
        echo "$__METRICS_DATA" | jq -r '
        .value[] 
        | select(.name.value == "CpuPercentage") 
        | .timeseries[0].data[] 
        | select(.average != null) 
        | .average' | jq -R -s -c 'split("\n")[:-1] | map(tonumber)'
    )

    local __MEMORY_VALUES=$(
        echo "$__METRICS_DATA" | jq -r '
        .value[] 
        | select(.name.value == "MemoryPercentage") 
        | .timeseries[0].data[] 
        | select(.average != null) 
        | .average' | jq -R -s -c 'split("\n")[:-1] | map(tonumber)'
    )

    cat <<EOF
<canvas id="$__canvas_id" width="378" height="250" style="border:1px solid #ccc;"></canvas>
<script>
  const labels_$__canvas_id = $__TIMESTAMPS;
  const cpuData_$__canvas_id = $__CPU_VALUES;
  const memoryData_$__canvas_id = $__MEMORY_VALUES;

  const chartOptions_$__canvas_id = {
    type: 'line',
    options: {
      responsive: false,
      scales: {
        x: {
          ticks: {
            maxTicksLimit: 10,
            callback: (val, i) => new Date(labels_$__canvas_id[i]).toISOString().slice(11, 16) + ' UTC'
          },
          title: { display: true, text: 'Time (UTC)' }
        },
        y: {
          min: 0, max: 100,
          title: { display: true, text: 'Usage (%)' }
        }
      },
      plugins: { legend: { display: true } }
    }
  };

  new Chart(document.getElementById('$__canvas_id'), {
    ...chartOptions_$__canvas_id,
    data: {
      labels: labels_$__canvas_id,
      datasets: [
        {
          label: 'CPU Usage (%)',
          data: cpuData_$__canvas_id,
          borderColor: 'rgba(255, 99, 132, 1)',
          borderWidth: 1,
          fill: false,
          tension: 0.1
        },
        {
          label: 'Memory Usage (%)',
          data: memoryData_$__canvas_id,
          borderColor: 'rgba(54, 162, 235, 1)',
          borderWidth: 1,
          fill: false,
          tension: 0.1
        }
      ]
    }
  });
</script>
EOF
}

# ====================================Region: Prepare HTML and plug the html with the CLI responses.====================================

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

tick=""
recomm=""
cross=""
urgent_warning=""
critical_warning=""

### This is dark theme

initialize_html() {
    cat <<EOF >$html_output
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure App Service Recommendations</title>
    <script src='https://cdn.jsdelivr.net/npm/chart.js'></script>
    <style>
        body {
            font-family: 'Verdana', sans-serif;
            font-size: 12px;
            margin: 0;
            padding: 20px;
            background-color: #1E2A38;
            color: #E0E0E0;
        }
        canvas {
            width: 378px; height: 250px;
            border: 1px solid #ccc;
            margin-bottom: 40px;
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

### This is light theme

# initialize_html() {
#     cat <<EOF >$html_output
# <html lang="en">
# <head>
#     <meta charset="UTF-8">
#     <meta name="viewport" content="width=device-width, initial-scale=1.0">
#     <title>Azure App Service Recommendations</title>
#     <script src='https://cdn.jsdelivr.net/npm/chart.js'></script>
#     <style>
#         body { 
#             font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
#             font-size: 13px; 
#             margin: 0; 
#             padding: 20px; 
#             background-color: #F8F9FA; 
#             color: #333333; 
#         }
#         canvas {
#             width: 378px; 
#             height: 250px;
#             border: 1px solid #ccc;
#             margin-bottom: 40px;
#             background-color: #ffffff;
#         }
#         h2 { 
#             text-align: center; 
#             color: #004085; 
#             font-size: 22px; 
#             font-weight: bold; 
#         }
#         h3 { 
#             color: #0056b3; 
#             font-size: 16px; 
#             font-weight: bold; 
#             text-align: left; 
#         }
#         p { 
#             font-size: 13px; 
#             color: #555555; 
#             line-height: 1.6; 
#         }
#         table { 
#             width: 90%; 
#             border-collapse: collapse; 
#             margin: 20px auto; 
#             font-size: 13px; 
#             background-color: #ffffff;
#             box-shadow: 0 2px 4px rgba(0,0,0,0.05);
#         }
#         th, td { 
#             padding: 10px; 
#             text-align: left; 
#             border: 1px solid #dee2e6; 
#         }
#         th { 
#             background-color: #e9f1f7; 
#             color: #003366; 
#             font-size: 14px; 
#         }
#         tr:nth-child(even) { 
#             background-color: #f2f6f9; 
#         }
#         a { 
#             color: #007bff; 
#             text-decoration: none; 
#             font-weight: bold; 
#         }
#         a:hover { 
#             color: #0056b3; 
#         }
#     </style>
# </head>
# <body>
#     <h2>Azure App Service Configuration Recommendations</h2>
# EOF
# }

summary_table() {
    local __subscription_id_header="$1"
    local __plan_count_header="$2"
    local __app_count_header="$3"

    cat <<EOF >>$html_output
<table>
    <thead>
        <tr>
            <th>$__subscription_id_header</th>
            <th>$__plan_count_header</th>
            <th>$__app_count_header</th>
        </tr>
    </thead>
    <tbody>
EOF
}

summary_table_output() {
    local __subscription_id="$1"
    local __app_service_plan_count="$2"
    local __app_service_count="$3"

    cat <<EOF >>$html_output
<tr>
    <td>$__subscription_id</td>
    <td>$__app_service_plan_count</td>
    <td>$__app_service_count</td>
</tr>
EOF
}

config_reccommendation_table() {
    local __app_service_name="$1"
    local __resource_group="$2"
    local __location="$3"
    local __kind="$4"
    local __auto_heal="$5"
    local __health_check="$6"
    local __always_on="$7"
    local __tls_secure="$8"
    local __ftps_state="$9"

    cat <<EOF >>$html_output
<table>
    <thead>
        <tr>
            <th>$__app_service_name</th>
            <th>$__resource_group</th>
            <th>$__location</th>
            <th>$__kind</th>
            <th>$__auto_heal</th>
            <th>$__health_check</th>
            <th>$__always_on</th>
            <th>$__tls_secure</th>
            <th>$__ftps_state</th>
        </tr>
    </thead>
    <tbody>
EOF
}

config_reccommendation_table_output() {
    # Assuming you are passing each value in the correct order
    local __name="$1"
    local __resource_group="$2"
    local __location="$3"
    local __kind="$4"
    local __auto_heal_color="$5"
    local __health_check_color="$6"
    local __always_on_color="$7"
    local __min_tls_version_color="$8"
    local __ftp_state_color="$9"

    cat <<EOF >>$html_output
<tr>
    <td>$__name</td>
    <td>$__resource_group</td>
    <td>$__location</td>
    <td>$__kind</td>
    <td>$__auto_heal_color</td>
    <td>$__health_check_color</td>
    <td>$__always_on_color</td>
    <td>$__min_tls_version_color</td>
    <td>$__ftp_state_color</td>
</tr>
EOF
}

# Finalize the HTML structure and footer
finalize_html() {
    echo "</body></html>" >>$html_output
}

generate_app_service_plan_recommendations_table() {
    local __plan_header="$1"
    local __size_header="$2"
    local __tier_header="$3"
    local __instance_count_header="$4"
    local __recommended_apps_header="$5"
    local __current_apps_header="$6"
    local ___zoneEnabledColor_header="$7"
    local __cpu_memory_header="$8"

    cat <<EOF >>$html_output
<table>
    <thead>
        <tr>
            <th>$__plan_header</th>
            <th>$__size_header</th>
            <th>$__tier_header</th>
            <th>$__instance_count_header</th>
            <th>$__recommended_apps_header</th>
            <th>$__current_apps_header</th>
            <th>$___zoneEnabledColor_header</th>
            <th>$__cpu_memory_header</th>
        </tr>
    </thead>
    <tbody>
EOF
}

generate_app_service_plan_recommendations_table_output() {
    local __name="$1"
    local __webapp_size="$2"
    local __webapp_tier="$3"
    local __webapp_worker="$4"
    local __recommended_apps="$5"
    local __webapp_count="$6"
    local ___zoneEnabledColor="$7"
    local __graph_cpu_memory="$8"

    cat <<EOF >>$html_output
<tr>
    <td>${__name}</td>
    <td>${__webapp_size}</td>
    <td>${__webapp_tier}</td>
    <td>${__webapp_worker}</td>
    <td>${__recommended_apps}</td>
    <td>${__webapp_count}</td>
    <td>${___zoneEnabledColor}</td>
    <td>${__graph_cpu_memory}</td>
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

GREEN="\033[1;32m"
YELLOW="\033[1;93m"
CYAN="\033[1;36m"
RESET="\033[0m"

run_stage() {
    local stage_name="$1"
    shift
    local command_to_run="$@"
    echo -ne "${CYAN}▶ $stage_name... ${RESET}"
    eval "$command_to_run" >/dev/null 2>&1 &
    local pid=$!

    local spin_chars=("⠋" "⠙" "⠚" "⠛" "⠓" "⠒" "⠂")
    local spin_index=0

    while ps -p $pid &>/dev/null; do
        echo -ne "\r${CYAN}▶ $stage_name... ${spin_chars[$spin_index]}${spin_chars[$spin_index]}${RESET}    "
        spin_index=$(((spin_index + 1) % ${#spin_chars[@]}))
        sleep 0.1
    done
    wait $pid
    echo -e "\r${GREEN}✔ $stage_name completed!${RESET}   "
}

start_time=$(date +"%Y-%m-%d %H:%M:%S")

run_stage "Initializing HTML" initialize_html
run_stage "Generating Summary" generate_summary
run_stage "Generating App Service Recommendations" generate_App_Services_Recommendations
run_stage "Generating App Service Plan Recommendations" generate_app_service_plan_recommendations
run_stage "Finalizing HTML" finalize_html
run_stage "Generating Best Practices References" generate_best_practices_reference
end_time=$(date +"%Y-%m-%d %H:%M:%S")

start_epoch=$(date -d "$start_time" +%s)
end_epoch=$(date -d "$end_time" +%s)
execution_time=$((end_epoch - start_epoch))
minutes=$((execution_time / 60))
seconds=$((execution_time % 60))

echo "Total report preparation time: $minutes minutes and $seconds seconds"
echo -e "\n${YELLOW}🎉 Report generated successfully! Download file $html_output !! ${RESET}"
