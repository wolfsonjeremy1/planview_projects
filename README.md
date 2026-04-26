# planview_projects
These files include programming in PowerShell for project purposes, supporting customer hosted environments

# Package_deployment_framework SCRUBBED.psm1
Project to deploy software spanning across multiple domains. The framework was meant to cover old and new company standard naming schemes and environment configurations from 2000s - 2020s, i.e. line 261 - 273. The redundant if statement checks of abbreviated naming schemes for environment referencing was implemented, from management's preference, as a form of a safety check to prevent unintentional installations of unintended environments to occur, avoiding service disruptions

# ping_endpoint_gateway_with_logging.ps1
This project was a form of redundancy for demonstrating product service reliability since the customer had specific issues connecting to the product through their ISP

# rs_replacer_scrubbed.ps1
This project was to update all customer environment web services config files to include a new server node in a Microsoft PowerBI report farm. This execution targets a "server_list.txt" list created by additional supporting scripts

# MakeList_scrubbed.ps1
Supporting rs_replacer_scrubbed.txt, this file runs through the domain, checking each servers file configuration and adding their server name to a list to be targeted by rs_replacer_scrubbed.txt
