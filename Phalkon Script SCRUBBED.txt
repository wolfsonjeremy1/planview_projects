##########################################################################
##########################################################################
############ FOR FIRST TIME READERS FOR SAMPLE PURPOSES, THIS ############
############ IS A SCRIPT WRITTEN IN POWERSHELL FOR AUTOMATING ############
############ DEPLOYMENTS OF SOFTWARE PACKAGES CALLED PHALKON, ############
############ SCRUBBED OF SENSITIVE ORGANIZATION INFORMATION.  ############
############ WRITTEN BY JEREMY WOLFSON, 2022-2023, PLANVIEW.  ############
##########################################################################
##########################################################################




function Install-Phalkon {
    Param(
        [Parameter(Mandatory = $True)]
        [string[]]$CustomerThreeLetterServerID,
        [Parameter(Mandatory = $True)]
        [string[]]$Environment,
        [Parameter()]
        [switch]$US_Domain,
        [Parameter()]
        [switch]$LN_Domain,
        [Parameter(Mandatory = $False)]
        [switch]$UninstallPhalkon)



#Domain to be searched
if ($US_Domain) {$Domainserver = 'AD Server US Domain Template'}
if ($LN_Domain) {$Domainserver = 'AD Server EU Domain Template'}




#Arrays for old COLO's naming convention
if ($US_Domain) {$server = 'US_Server_Name_Template'}
if ($LN_Domain) {$server = 'EU_Server_Name_Template'}
$appshort = 'app*'
$webshort = 'web*'
$pveshort = 'pve*'
$sqlshort = 'sql*'
$app = $server + $CustomerThreeLetterServerID + $appshort
$web = $server + $CustomerThreeLetterServerID + $webshort
$pve = $server + $CustomerThreeLetterServerID + $pveshort
$sql = $server + $CustomerThreeLetterServerID + $sqlshort



#Arrays for new COLO's and LN naming convention
if ($US_Domain) {$NewServer = 'server_name_template_first_letters_US_Domain'}
if ($LN_Domain) {$NewServer = 'server_name_template_first_letters_EU_Domain'}
$NewApp = $NewServer + $CustomerThreeLetterServerID + $appshort
$NewWeb = $NewServer + $CustomerThreeLetterServerID + $webshort
$NewPve = $NewServer + $CustomerThreeLetterServerID + $pveshort
$NewSql = $NewServer + $CustomerThreeLetterServerID + $sqlshort



#Arrays for domain specific json info
if ($US_Domain) {
$header = '[PhalkonDSC]'
$iishostpre = 'US\ushost'
$iishostpostfull = 'TemplateName|Network Service|System'
$iishostpostshort = 'TemplateName'
$dbowner = 'db_owner_template'
$password = 'db_owner_template_password'
$domainlong = '.TemplateName.planview.TemplateName'
$optional = '[Optional]'
}
if ($LN_Domain) {
$header = '[PhalkonDSC]'
$iishostpre = 'eu\TemplateName'
$iishostpostfull = 'TemplateName|Network Service|System'
$iishostpostshort = 'TemplateName'
$dbowner = 'db_owner_template'
$password = 'db_owner_template_password'
$domainlong = '.TemplateName.planview.TemplateName'
$optional = '[Optional]'
}



#preconfigured json to pass to phalkon
$JsonPreConfigured = $JsonPreConfigured + "$header" + "`r`n"
$JsonPreConfigured = $JsonPreConfigured + "user_accounts= "  + """$iishostpre$CustomerThreeLetterServerID$iishostpostfull""" + "`r`n"
$JsonPreConfigured = $JsonPreConfigured + "phalkon_db_owner= "  + """$dbowner""" + "`r`n"
$JsonPreConfigured = $JsonPreConfigured + "use_database_login_windows_acct= "  + """true""" + "`r`n"
$JsonPreConfigured = $JsonPreConfigured + "phalkon_db_account= "  + """TemplatePassword""" + "`r`n"
$JsonPreConfigured = $JsonPreConfigured + "phalkon_db_password= "  + """TemplatePassword""" + "`r`n"
$JsonPreConfigured = $JsonPreConfigured + "phalkon_web_app_iis_user_account= "  + """$iishostpre$CustomerThreeLetterServerID$iishostpostshort""" + "`r`n"
$JsonPreConfigured = $JsonPreConfigured + "phalkon_web_app_iis_user_encrypted_password= "  + """$password""" + "`r`n"
if ($UninstallPhalkon) {$JsonPreConfigured = $JsonPreConfigured + "force_uninstall= "  + """true""" + "`r`n"}



#Phalkon Package Path
$PackagesPath = '\\scripthost\Modules\Phalkon\Packages'



write-host "
===================================================================================================================================================================================================
Creating the active directory queries for helping create the target group for the install.........
===================================================================================================================================================================================================
"



#PREPROD app and web servers, production sql server isn't necessary as Phalkon uses sandbox SQL servers for resource utilzation and to not impeade on production SQL servers: 
$GETPREPRODAPP = Get-ADComputer -Filter "name -like ""$app""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=preprod,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPREPRODWEB = Get-ADComputer -Filter "name -like ""$web""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=preprod,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPREPRODPVE = Get-ADComputer -Filter "name -like ""$pve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=preprod,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPREPRODAPP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=preprod,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPREPRODWEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=preprod,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPREPRODPVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=preprod,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
#PRESANDBOX app web sql server list
$GETPRESANDBOXAPP = Get-ADComputer -Filter "name -like ""$app""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRESANDBOXWEB = Get-ADComputer -Filter "name -like ""$web""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRESANDBOXPVE = Get-ADComputer -Filter "name -like ""$pve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name           
$GETPRESANDBOXSQL = Get-ADComputer -Filter "name -like ""$sql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name 
$GETNEWPRESANDBOXAPP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOXWEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOXPVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOXSQL = Get-ADComputer -Filter "name -like ""$NewSql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
#PRESANDBOX1 app web sql server list
$GETPRESANDBOX1APP = Get-ADComputer -Filter "name -like ""$app""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRESANDBOX1WEB = Get-ADComputer -Filter "name -like ""$web""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRESANDBOX1PVE = Get-ADComputer -Filter "name -like ""$pve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name           
$GETPRESANDBOX1SQL = Get-ADComputer -Filter "name -like ""$sql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name 
$GETNEWPRESANDBOX1APP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX1WEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX1PVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX1SQL = Get-ADComputer -Filter "name -like ""$NewSql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
#PRESANDBOX2 app web sql server list
$GETPRESANDBOX2APP = Get-ADComputer -Filter "name -like ""$app""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRESANDBOX2WEB = Get-ADComputer -Filter "name -like ""$web""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRESANDBOX2PVE = Get-ADComputer -Filter "name -like ""$pve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name           
$GETPRESANDBOX2SQL = Get-ADComputer -Filter "name -like ""$sql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name 
$GETNEWPRESANDBOX2APP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX2WEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX2PVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX2SQL = Get-ADComputer -Filter "name -like ""$NewSql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
#PRESANDBOX3 app web sql server list
$GETPRESANDBOX3APP = Get-ADComputer -Filter "name -like ""$app""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRESANDBOX3WEB = Get-ADComputer -Filter "name -like ""$web""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRESANDBOX3PVE = Get-ADComputer -Filter "name -like ""$pve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name           
$GETPRESANDBOX3SQL = Get-ADComputer -Filter "name -like ""$sql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name 
$GETNEWPRESANDBOX3APP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX3WEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX3PVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX3SQL = Get-ADComputer -Filter "name -like ""$NewSql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
#PRESANDBOX4 app web sql server list
$GETPRESANDBOX4APP = Get-ADComputer -Filter "name -like ""$app""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRESANDBOX4WEB = Get-ADComputer -Filter "name -like ""$web""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRESANDBOX4PVE = Get-ADComputer -Filter "name -like ""$pve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name           
$GETPRESANDBOX4SQL = Get-ADComputer -Filter "name -like ""$sql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name 
$GETNEWPRESANDBOX4APP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX4WEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX4PVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX4SQL = Get-ADComputer -Filter "name -like ""$NewSql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
#PRESANDBOX5 app web sql server list
$GETPRESANDBOX5APP = Get-ADComputer -Filter "name -like ""$app""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRESANDBOX5WEB = Get-ADComputer -Filter "name -like ""$web""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRESANDBOX5PVE = Get-ADComputer -Filter "name -like ""$pve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name           
$GETPRESANDBOX5SQL = Get-ADComputer -Filter "name -like ""$sql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name 
$GETNEWPRESANDBOX5APP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX5WEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX5PVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX5SQL = Get-ADComputer -Filter "name -like ""$NewSql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
#PRESANDBOX6 app web sql server list
$GETPRESANDBOX6APP = Get-ADComputer -Filter "name -like ""$app""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRESANDBOX6WEB = Get-ADComputer -Filter "name -like ""$web""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRESANDBOX6PVE = Get-ADComputer -Filter "name -like ""$pve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name           
$GETPRESANDBOX6SQL = Get-ADComputer -Filter "name -like ""$sql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name 
$GETNEWPRESANDBOX6APP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX6WEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX6PVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRESANDBOX6SQL = Get-ADComputer -Filter "name -like ""$NewSql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=PreSandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
#PROD app and web servers, production sql server isn't necessary as Phalkon uses sandbox SQL servers for resource utilzation and to not impeade on production SQL servers: 
$GETPRODAPP = Get-ADComputer -Filter "name -like ""$app""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=production,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRODWEB = Get-ADComputer -Filter "name -like ""$web""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=production,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETPRODPVE = Get-ADComputer -Filter "name -like ""$pve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=production,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRODAPP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=production,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRODWEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=production,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWPRODPVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver  | where { $_.DistinguishedName -like '*OU=production,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
#SANDBOX app web sql server list
$GETSANDBOXAPP = Get-ADComputer -Filter "name -like ""$app""" -Server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETSANDBOXWEB = Get-ADComputer -Filter "name -like ""$web""" -Server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETSANDBOXPVE = Get-ADComputer -Filter "name -like ""$pve""" -Server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name           
$GETSANDBOXSQL = Get-ADComputer -Filter "name -like ""$sql""" -Server $Domainserver  | where { $_.DistinguishedName -like '*OU=Sandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name 
$GETNEWSANDBOXAPP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver  | where { $_.DistinguishedName -like '*OU=Sandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOXWEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver  | where { $_.DistinguishedName -like '*OU=Sandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOXPVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver  | where { $_.DistinguishedName -like '*OU=Sandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOXSQL = Get-ADComputer -Filter "name -like ""$NewSql""" -server $Domainserver  | where { $_.DistinguishedName -like '*OU=Sandbox,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name     
#SANDBOX1 app web sql server list for MULTIPLE SANDBOX ENVIRONMENT customers 
$GETSANDBOX1APP = Get-ADComputer -Filter "name -like ""$app""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETSANDBOX1WEB = Get-ADComputer -Filter "name -like ""$web""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETSANDBOX1PVE = Get-ADComputer -Filter "name -like ""$pve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name          
$GETSANDBOX1SQL = Get-ADComputer -Filter "name -like ""$sql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX1APP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX1WEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX1PVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX1SQL = Get-ADComputer -Filter "name -like ""$NewSql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox1,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name 
#SANDBOX2 app web sql server list for MULTIPLE SANDBOX ENVIRONMENT customers           
$GETSANDBOX2APP = Get-ADComputer -Filter "name -like ""$app""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name          
$GETSANDBOX2WEB = Get-ADComputer -Filter "name -like ""$web""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name 
$GETSANDBOX2PVE = Get-ADComputer -Filter "name -like ""$pve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name                    
$GETSANDBOX2SQL = Get-ADComputer -Filter "name -like ""$sql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name 
$GETNEWSANDBOX2APP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name  
$GETNEWSANDBOX2WEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name 
$GETNEWSANDBOX2PVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name 
$GETNEWSANDBOX2SQL = Get-ADComputer -Filter "name -like ""$NewSql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox2,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name 
#SANDBOX3 app web sql server list for MULTIPLE SANDBOX ENVIRONMENT customers          
$GETSANDBOX3APP = Get-ADComputer -Filter "name -like ""$app""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name             
$GETSANDBOX3WEB = Get-ADComputer -Filter "name -like ""$web""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETSANDBOX3PVE = Get-ADComputer -Filter "name -like ""$pve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name            
$GETSANDBOX3SQL = Get-ADComputer -Filter "name -like ""$sql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX3APP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX3WEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX3PVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX3SQL = Get-ADComputer -Filter "name -like ""$NewSql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox3,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name     
#SANDBOX4 app web sql server list for MULTIPLE SANDBOX ENVIRONMENT customers          
$GETSANDBOX4APP = Get-ADComputer -Filter "name -like ""$app""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name             
$GETSANDBOX4WEB = Get-ADComputer -Filter "name -like ""$web""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETSANDBOX4PVE = Get-ADComputer -Filter "name -like ""$pve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name            
$GETSANDBOX4SQL = Get-ADComputer -Filter "name -like ""$sql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX4APP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX4WEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX4PVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX4SQL = Get-ADComputer -Filter "name -like ""$NewSql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox4,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name      
#SANDBOX5 app web sql server list for MULTIPLE SANDBOX ENVIRONMENT customers          
$GETSANDBOX5APP = Get-ADComputer -Filter "name -like ""$app""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name             
$GETSANDBOX5WEB = Get-ADComputer -Filter "name -like ""$web""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETSANDBOX5PVE = Get-ADComputer -Filter "name -like ""$pve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name            
$GETSANDBOX5SQL = Get-ADComputer -Filter "name -like ""$sql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX5APP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX5WEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX5PVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX5SQL = Get-ADComputer -Filter "name -like ""$NewSql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox5,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name    
#SANDBOX6 app web sql server list for MULTIPLE SANDBOX ENVIRONMENT customers          
$GETSANDBOX6APP = Get-ADComputer -Filter "name -like ""$app""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name             
$GETSANDBOX6WEB = Get-ADComputer -Filter "name -like ""$web""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETSANDBOX6PVE = Get-ADComputer -Filter "name -like ""$pve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name            
$GETSANDBOX6SQL = Get-ADComputer -Filter "name -like ""$sql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX6APP = Get-ADComputer -Filter "name -like ""$NewApp""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX6WEB = Get-ADComputer -Filter "name -like ""$NewWeb""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX6PVE = Get-ADComputer -Filter "name -like ""$NewPve""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name
$GETNEWSANDBOX6SQL = Get-ADComputer -Filter "name -like ""$NewSql""" -server $Domainserver | where { $_.DistinguishedName -like '*OU=Sandbox6,*' -and ($_.DistinguishedName -ne '*OU=ZZZZ: Decommission Servers*') -and ($_.DistinguishedName -ne '*OU=ZZZZ: Retire Servers*') } | Select-Object -ExpandProperty Name 



write-host "
===================================================================================================================================================================================================
Creating the target group for execution.........
===================================================================================================================================================================================================
"



if ($Environment -eq 'preprod' -or $Environment -eq 'pre-prod' -or $Environment -eq 'pre-production' -or $Environment -eq 'preproduction') {
Write-Host 'PreProduction Environments Will utilize the presandbox SQL server for resource utilization, to not impeade on PreProduction SQL servers.'
start-sleep -Seconds 4
$JsonPreConfiguredPREPROD = $JsonPreConfigured
if ($Environment -eq 'preprod' -or $Environment -eq 'pre-prod' -or $Environment -eq 'pre-production' -or $Environment -eq 'preproduction') {$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "phalkon_db_name= " + """phalkon_preprod""" + "`r`n"}
if ($Environment -eq 'preprod' -or $Environment -eq 'pre-prod' -or $Environment -eq 'pre-production' -or $Environment -eq 'preproduction') {if ($GETPRESANDBOXSQL -ne $null)  {$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "phalkon_db_server= " + """$GETPRESANDBOXSQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'preprod' -or $Environment -eq 'pre-prod' -or $Environment -eq 'pre-production' -or $Environment -eq 'preproduction') {if ($GETNEWPRESANDBOXSQL -ne $null)  {$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "phalkon_db_server= " + """$GETNEWPRESANDBOXSQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'preprod' -or $Environment -eq 'pre-prod' -or $Environment -eq 'pre-production' -or $Environment -eq 'preproduction') {if ($GETPRESANDBOX1SQL -ne $null)  {$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "phalkon_db_server= " + """$GETPRESANDBOX1SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'preprod' -or $Environment -eq 'pre-prod' -or $Environment -eq 'pre-production' -or $Environment -eq 'preproduction') {if ($GETNEWPRESANDBOX1SQL -ne $null)  {$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "phalkon_db_server= " + """$GETNEWPRESANDBOX1SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'preprod' -or $Environment -eq 'pre-prod' -or $Environment -eq 'pre-production' -or $Environment -eq 'preproduction') {if ($GETPRESANDBOXSQL -ne $null) {$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_preprod""" + "`r`n"}} 
if ($Environment -eq 'preprod' -or $Environment -eq 'pre-prod' -or $Environment -eq 'pre-production' -or $Environment -eq 'preproduction') {if ($GETNEWPRESANDBOXSQL -ne $null) {$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_preprod""" + "`r`n"}} 
if ($Environment -eq 'preprod' -or $Environment -eq 'pre-prod' -or $Environment -eq 'pre-production' -or $Environment -eq 'preproduction') {if ($GETPRESANDBOX1SQL -ne $null) {$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_preprod""" + "`r`n"}} 
if ($Environment -eq 'preprod' -or $Environment -eq 'pre-prod' -or $Environment -eq 'pre-production' -or $Environment -eq 'preproduction') {if ($GETNEWPRESANDBOX1SQL -ne $null) {$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_preprod""" + "`r`n"}} 
if ($GETPREPRODAPP -ne $null) {$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "app_server_name= " + """$GETPREPRODAPP""" + "`r`n"}
if ($GETPREPRODAPP -eq $null) {}
if ($GETPREPRODPVE -ne $null) {$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "app_server_name= " + """$GETPREPRODPVE""" + "`r`n"}
if ($GETPREPRODPVE -eq $null) {}
if ($GETNEWPREPRODAPP -ne $null) {$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "app_server_name= " + """$GETNEWPREPRODAPP""" + "`r`n"}
if ($GETNEWPREPRODAPP -eq $null) {}
if ($GETNEWPREPRODPVE -ne $null) {$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "app_server_name= " + """$GETNEWPREPRODPVE""" + "`r`n"}
if ($GETNEWPREPRODPVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "force_uninstall= " + """true""" + "`r`n"}
$PRESANDBOXSQLCOUNT = $GETPRESANDBOXSQL + $GETNEWPRESANDBOXSQL + $GETPRESANDBOX1SQL + $GETNEWPRESANDBOX1SQL
if ($PRESANDBOXSQLCOUNT.count -gt 1) {$JsonPreConfiguredPREPROD = $null}
if ($PRESANDBOXSQLCOUNT.count -lt 1) {$JsonPreConfiguredPREPROD = $null}
$PREPRODAPPCOUNT = $GETPREPRODAPP + $GETPREPRODPVE + $GETNEWPREPRODAPP + $GETNEWPREPRODPVE
if ($PREPRODAPPCOUNT.count -gt 1) {$JsonPreConfiguredPREPROD = $null}
if ($PREPRODAPPCOUNT.count -lt 1) {$JsonPreConfiguredPREPROD = $null}
if ($Environment -eq 'preprod' -or $Environment -eq 'pre-prod' -or $Environment -eq 'pre-production' -or $Environment -eq 'preproduction') {If ($PREPRODAPPCOUNT -ne $null) {If ($PRESANDBOXSQLCOUNT -ne $null) {$TargetGroup = $GETPREPRODAPP, $GETPREPRODWEB, $GETPREPRODPVE, $GETPRESANDBOXSQL, $GETNEWPREPRODAPP, $GETNEWPREPRODWEB, $GETNEWPREPRODPVE, $GETNEWPRESANDBOXSQL, $GETPRESANDBOX1SQL, $GETNEWPRESANDBOX1SQL}}}
if ($PRESANDBOXSQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRESANDBOXSQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
if ($PRESANDBOXSQLCOUNT -ne $null) {if ($PRESANDBOXSQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup"}}
if ($PREPRODAPPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PREPRODAPPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
if ($PREPRODAPPCOUNT -ne $null) {if ($PREPRODAPPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup"}}
$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "$optional" + "`r`n"
$JsonPreConfiguredPREPROD = $JsonPreConfiguredPREPROD + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($PRESANDBOXSQLCOUNT.count -gt 1 -or $PRESANDBOXSQLCOUNT.count -lt 1) { $JsonPreConfiguredPREPROD = $null }
$JsonConfigured = $JsonPreConfiguredPREPROD
$JsonConfigured
}

elseif ($Environment -eq 'presb' -or $Environment -eq 'pre-sb' -or $Environment -eq 'pre-sandbox' -or $Environment -eq 'presandbox') {
Write-host 'If no environment is found, please try adding a 1 at the end of Sandbox in the environment specified, i.e. PreSB1 or PreSandbox1. This is most likely due to the customer having multiple PreSandbox environments.'
start-sleep -Seconds 4
$JsonPreConfiguredPRESB = $JsonPreConfigured
if ($Environment -eq 'presb' -or $Environment -eq 'pre-sb' -or $Environment -eq 'pre-sandbox' -or $Environment -eq 'presandbox') {$JsonPreConfiguredPRESB = $JsonPreConfiguredPRESB + "phalkon_db_name= " + """phalkon_presb""" + "`r`n"}
if ($Environment -eq 'presb' -or $Environment -eq 'pre-sb' -or $Environment -eq 'pre-sandbox' -or $Environment -eq 'presandbox') {if ($GETPRESANDBOXSQL -ne $null) {$JsonPreConfiguredPRESB = $JsonPreConfiguredPRESB + "phalkon_db_server= " + """$GETPRESANDBOXSQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'presb' -or $Environment -eq 'pre-sb' -or $Environment -eq 'pre-sandbox' -or $Environment -eq 'presandbox') {if ($GETNEWPRESANDBOXSQL -ne $null) {$JsonPreConfiguredPRESB = $JsonPreConfiguredPRESB + "phalkon_db_server= " + """$GETNEWPRESANDBOXSQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'presb' -or $Environment -eq 'pre-sb' -or $Environment -eq 'pre-sandbox' -or $Environment -eq 'presandbox') {if ($GETPRESANDBOXSQL -ne $null) {$JsonPreConfiguredPRESB = $JsonPreConfiguredPRESB + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_presb""" + "`r`n"}} 
if ($Environment -eq 'presb' -or $Environment -eq 'pre-sb' -or $Environment -eq 'pre-sandbox' -or $Environment -eq 'presandbox') {if ($GETNEWPRESANDBOXSQL -ne $null) {$JsonPreConfiguredPRESB= $JsonPreConfiguredPRESB + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_presb""" + "`r`n"}} 
if ($GETPRESANDBOXAPP -ne $null) {$JsonPreConfiguredPRESB = $JsonPreConfiguredPRESB + "app_server_name= " + """$GETPRESANDBOXAPP""" + "`r`n"}
if ($GETPRESANDBOXAPP -eq $null) {}
if ($GETPRESANDBOXPVE -ne $null) {$JsonPreConfiguredPRESB = $JsonPreConfiguredPRESB + "app_server_name= " + """$GETPRESANDBOXPVE""" + "`r`n"}
if ($GETPRESANDBOXPVE -eq $null) {}
if ($GETNEWPRESANDBOXAPP -ne $null) {$JsonPreConfiguredPRESB = $JsonPreConfiguredPRESB + "app_server_name= " + """$GETNEWPRESANDBOXAPP""" + "`r`n"}
if ($GETNEWPRESANDBOXAPP -eq $null) {}
if ($GETNEWPRESANDBOXPVE -ne $null) {$JsonPreConfiguredPRESB = $JsonPreConfiguredPRESB1 + "app_server_name= " + """$GETNEWPRESANDBOXPVE""" + "`r`n"}
if ($GETNEWPRESANDBOXPVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredPRESB = $JsonPreConfiguredPRESB + "force_uninstall= " + """true""" + "`r`n"}
$PRESANDBOXSQLCOUNT = $GETPRESANDBOXSQL + $GETNEWPRESANDBOXSQL
if ($PRESANDBOXSQLCOUNT.count -gt 1) {$JsonPreConfiguredSB = $null}
if ($PRESANDBOXSQLCOUNT.count -lt 1) {$JsonPreConfiguredSB = $null}
$PRESANDBOXAPPCOUNT = $GETPRESANDBOXAPP + $GETPRESANDBOXPVE + $GETNEWPRESANDBOXAPP + $GETNEWPRESANDBOXPVE
if ($PRESANDBOXAPPCOUNT.count -gt 1) {$JsonPreConfiguredSB = $null} 
if ($PRESANDBOXAPPCOUNT.count -lt 1) {$JsonPreConfiguredSB = $null}
if ($Environment -eq 'presb' -or $Environment -eq 'pre-sb' -or $Environment -eq 'pre-sandbox' -or $Environment -eq 'presandbox') {If ($PRESANDBOXAPPCOUNT -ne $null) {If ($PRESANDBOXSQLCOUNT -ne $null) {$TargetGroup = $GETPRESANDBOXAPP, $GETPRESANDBOXWEB, $GETPRESANDBOXPVE, $GETPRESANDBOXSQL, $GETNEWPRESANDBOXAPP, $GETNEWPRESANDBOXWEB, $GETNEWPRESANDBOXPVE, $GETNEWPRESANDBOXSQL}}}
if ($PRESANDBOXSQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRESANDBOXSQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($PRESANDBOXSQLCOUNT -ne $null) {if ($PRESANDBOXSQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
if ($PRESANDBOXAPPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRESANDBOXAPPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($PRESANDBOXAPPCOUNT -ne $null) {if ($PRESANDBOXAPPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
$JsonPreConfiguredPRESB = $JsonPreConfiguredPRESB + "$optional" + "`r`n"
$JsonPreConfiguredPRESB = $JsonPreConfiguredPRESB + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($PRESANDBOXSQLCOUNT.count -gt 1 -or $PRESANDBOXSQLCOUNT.count -lt 1) { $JsonPreConfiguredPRESB = $null }
$JsonConfigured = $JsonPreConfiguredPRESB
$JsonConfigured
}

elseif ($Environment -eq 'presb1' -or $Environment -eq 'pre-sb1' -or $Environment -eq 'pre-sandbox1' -or $Environment -eq 'presandbox1') {
Write-Host 'The PreSandbox environment search may not come back with any results, please narrow down your search by removing the number code, i.e. PreSB or Presandbox, rather than PreSB1 or PreSandbox1.'
start-sleep -Seconds 4
$JsonPreConfiguredPRESB1 = $JsonPreConfigured
if ($Environment -eq 'presb1' -or $Environment -eq 'pre-sb1' -or $Environment -eq 'pre-sandbox1' -or $Environment -eq 'presandbox1') {$JsonPreConfiguredPRESB1 = $JsonPreConfiguredPRESB1 + "phalkon_db_name= " + """phalkon_presb1""" + "`r`n"}
if ($Environment -eq 'presb1' -or $Environment -eq 'pre-sb1' -or $Environment -eq 'pre-sandbox1' -or $Environment -eq 'presandbox1') {if ($GETPRESANDBOX1SQL -ne $null) {$JsonPreConfiguredPRESB1 = $JsonPreConfiguredPRESB1 + "phalkon_db_server= " + """$GETPRESANDBOX1SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'presb1' -or $Environment -eq 'pre-sb1' -or $Environment -eq 'pre-sandbox1' -or $Environment -eq 'presandbox1') {if ($GETNEWPRESANDBOX1SQL -ne $null) {$JsonPreConfiguredPRESB1 = $JsonPreConfiguredPRESB1 + "phalkon_db_server= " + """$GETNEWPRESANDBOX1SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'presb1' -or $Environment -eq 'pre-sb1' -or $Environment -eq 'pre-sandbox1' -or $Environment -eq 'presandbox1') {if ($GETPRESANDBOX1SQL -ne $null) {$JsonPreConfiguredPRESB1 = $JsonPreConfiguredPRESB1 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_presb1""" + "`r`n"}} 
if ($Environment -eq 'presb1' -or $Environment -eq 'pre-sb1' -or $Environment -eq 'pre-sandbox1' -or $Environment -eq 'presandbox1') {if ($GETNEWPRESANDBOX1SQL -ne $null) {$JsonPreConfiguredPRESB1 = $JsonPreConfiguredPRESB1 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_presb1""" + "`r`n"}} 
if ($GETPRESANDBOX1APP -ne $null) {$JsonPreConfiguredPRESB1 = $JsonPreConfiguredPRESB1 + "app_server_name= " + """$GETPRESANDBOX1APP""" + "`r`n"}
if ($GETPRESANDBOX1APP -eq $null) {}
if ($GETPRESANDBOX1PVE -ne $null) {$JsonPreConfiguredPRESB1 = $JsonPreConfiguredPRESB1 + "app_server_name= " + """$GETPRESANDBOX1PVE""" + "`r`n"}
if ($GETPRESANDBOX1PVE -eq $null) {}
if ($GETNEWPRESANDBOX1APP -ne $null) {$JsonPreConfiguredPRESB1 = $JsonPreConfiguredPRESB1 + "app_server_name= " + """$GETNEWPRESANDBOX1APP""" + "`r`n"}
if ($GETNEWPRESANDBOX1APP -eq $null) {}
if ($GETNEWPRESANDBOX1PVE -ne $null) {$JsonPreConfiguredPRESB1 = $JsonPreConfiguredPRESB1 + "app_server_name= " + """$GETNEWPRESANDBOX1PVE""" + "`r`n"}
if ($GETNEWPRESANDBOX1PVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredPRESB1 = $JsonPreConfiguredPRESB1 + "force_uninstall= " + """true""" + "`r`n"}
$PRESANDBOX1SQLCOUNT = $GETPRESANDBOX1SQL + $GETNEWPRESANDBOX1SQL
if ($PRESANDBOX1SQLCOUNT.count -gt 1) {$JsonPreConfiguredPRESB1 = $null}
if ($PRESANDBOX1SQLCOUNT.count -lt 1) {$JsonPreConfiguredPRESB1 = $null}
$PRESANDBOX1APPCOUNT = $GETPRESANDBOX1APP + $GETPRESANDBOX1PVE + $GETNEWPRESANDBOX1APP + $GETNEWPRESANDBOX1PVE
if ($PRESANDBOX1APPCOUNT.count -gt 1) {$JsonPreConfiguredPRESB1 = $null} 
if ($PRESANDBOX1APPCOUNT.count -lt 1) {$JsonPreConfiguredPRESB1 = $null}
if ($Environment -eq 'presb1' -or $Environment -eq 'pre-sb1' -or $Environment -eq 'pre-sandbox1' -or $Environment -eq 'presandbox1') {If ($PRESANDBOX1APPCOUNT -ne $null) {If ($PRESANDBOX1SQLCOUNT -ne $null) {$TargetGroup = $GETPRESANDBOX1APP, $GETPRESANDBOX1WEB, $GETPRESANDBOX1PVE, $GETPRESANDBOX1SQL, $GETNEWPRESANDBOX1APP, $GETNEWPRESANDBOX1WEB, $GETNEWPRESANDBOX1PVE, $GETNEWPRESANDBOX1SQL}}}
if ($PRESANDBOX1SQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRESANDBOX1SQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($PRESANDBOX1SQLCOUNT -ne $null) {if ($PRESANDBOX1SQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
if ($PRESANDBOX1APPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRESANDBOX1APPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($PRESANDBOX1APPCOUNT -ne $null) {if ($PRESANDBOX1APPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
$JsonPreConfiguredPRESB1 = $JsonPreConfiguredPRESB1 + "$optional" + "`r`n"
$JsonPreConfiguredPRESB1 = $JsonPreConfiguredPRESB1 + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($PRESANDBOX1SQLCOUNT.count -gt 1 -or $PRESANDBOX1SQLCOUNT.count -lt 1) { $JsonPreConfiguredPRESB1 = $null }
$JsonConfigured = $JsonPreConfiguredPRESB1
$JsonConfigured
}

elseif ($Environment -eq 'presb2' -or $Environment -eq 'pre-sb2' -or $Environment -eq 'pre-sandbox2' -or $Environment -eq 'presandbox2') {
Write-Host 'Beginning search of servers within the customers PreSandbox2 environment.'
start-sleep -Seconds 4
$JsonPreConfiguredPRESB2 = $JsonPreConfigured
if ($Environment -eq 'presb2' -or $Environment -eq 'pre-sb2' -or $Environment -eq 'pre-sandbox2' -or $Environment -eq 'presandbox2') {$JsonPreConfiguredPRESB2 = $JsonPreConfiguredPRESB2 + "phalkon_db_name= " + """phalkon_presb2""" + "`r`n"}
if ($Environment -eq 'presb2' -or $Environment -eq 'pre-sb2' -or $Environment -eq 'pre-sandbox2' -or $Environment -eq 'presandbox2') {if ($GETPRESANDBOX2SQL -ne $null) {$JsonPreConfiguredPRESB2 = $JsonPreConfiguredPRESB2 + "phalkon_db_server= " + """$GETPRESANDBOX2SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'presb2' -or $Environment -eq 'pre-sb2' -or $Environment -eq 'pre-sandbox2' -or $Environment -eq 'presandbox2') {if ($GETNEWPRESANDBOX2SQL -ne $null) {$JsonPreConfiguredPRESB2 = $JsonPreConfiguredPRESB2 + "phalkon_db_server= " + """$GETNEWPRESANDBOX2SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'presb2' -or $Environment -eq 'pre-sb2' -or $Environment -eq 'pre-sandbox2' -or $Environment -eq 'presandbox2') {if ($GETPRESANDBOX2SQL -ne $null) {$JsonPreConfiguredPRESB2 = $JsonPreConfiguredPRESB2 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_presb2""" + "`r`n"}} 
if ($Environment -eq 'presb2' -or $Environment -eq 'pre-sb2' -or $Environment -eq 'pre-sandbox2' -or $Environment -eq 'presandbox2') {if ($GETNEWPRESANDBOX2SQL -ne $null) {$JsonPreConfiguredPRESB2 = $JsonPreConfiguredPRESB2 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_presb2""" + "`r`n"}} 
if ($GETPRESANDBOX2APP -ne $null) {$JsonPreConfiguredPRESB2 = $JsonPreConfiguredPRESB2 + "app_server_name= " + """$GETPRESANDBOX2APP""" + "`r`n"}
if ($GETPRESANDBOX2APP -eq $null) {}
if ($GETPRESANDBOX2PVE -ne $null) {$JsonPreConfiguredPRESB2 = $JsonPreConfiguredPRESB2 + "app_server_name= " + """$GETPRESANDBOX2PVE""" + "`r`n"}
if ($GETPRESANDBOX2PVE -eq $null) {}
if ($GETNEWPRESANDBOX2APP -ne $null) {$JsonPreConfiguredPRESB2 = $JsonPreConfiguredPRESB2 + "app_server_name= " + """$GETNEWPRESANDBOX2APP""" + "`r`n"}
if ($GETNEWPRESANDBOX2APP -eq $null) {}
if ($GETNEWPRESANDBOX2PVE -ne $null) {$JsonPreConfiguredPRESB2 = $JsonPreConfiguredPRESB2 + "app_server_name= " + """$GETNEWPRESANDBOX2PVE""" + "`r`n"}
if ($GETNEWPRESANDBOX2PVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredPRESB2 = $JsonPreConfiguredPRESB2 + "force_uninstall= " + """true""" + "`r`n"}
$PRESANDBOX2SQLCOUNT = $GETPRESANDBOX2SQL + $GETNEWPRESANDBOX2SQL
if ($PRESANDBOX2SQLCOUNT.count -gt 1) {$JsonPreConfiguredPRESB2 = $null}
if ($PRESANDBOX2SQLCOUNT.count -lt 1) {$JsonPreConfiguredPRESB2 = $null}
$PRESANDBOX2APPCOUNT = $GETPRESANDBOX2APP + $GETPRESANDBOX2PVE + $GETNEWPRESANDBOX2APP + $GETNEWPRESANDBOX2PVE
if ($PRESANDBOX2APPCOUNT.count -gt 1) {$JsonPreConfiguredPRESB2 = $null} 
if ($PRESANDBOX2APPCOUNT.count -lt 1) {$JsonPreConfiguredPRESB2 = $null}
if ($Environment -eq 'presb2' -or $Environment -eq 'pre-sb2' -or $Environment -eq 'pre-sandbox2' -or $Environment -eq 'presandbox2') {If ($PRESANDBOX2APPCOUNT -ne $null) {If ($PRESANDBOX2SQLCOUNT -ne $null) {$TargetGroup = $GETPRESANDBOX2APP, $GETPRESANDBOX2WEB, $GETPRESANDBOX2PVE, $GETPRESANDBOX2SQL, $GETNEWPRESANDBOX2APP, $GETNEWPRESANDBOX2WEB, $GETNEWPRESANDBOX2PVE, $GETNEWPRESANDBOX2SQL}}}
if ($PRESANDBOX2SQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRESANDBOX2SQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($PRESANDBOX2SQLCOUNT -ne $null) {if ($PRESANDBOX2SQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
if ($PRESANDBOX2APPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRESANDBOX2APPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($PRESANDBOX2APPCOUNT -ne $null) {if ($PRESANDBOX2APPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
$JsonPreConfiguredPRESB2 = $JsonPreConfiguredPRESB2 + "$optional" + "`r`n"
$JsonPreConfiguredPRESB2 = $JsonPreConfiguredPRESB2 + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($PRESANDBOX2SQLCOUNT.count -gt 1 -or $PRESANDBOX2SQLCOUNT.count -lt 1) { $JsonPreConfiguredPRESB2 = $null }
$JsonConfigured = $JsonPreConfiguredPRESB2
$JsonConfigured
}

elseif ($Environment -eq 'presb3' -or $Environment -eq 'pre-sb3' -or $Environment -eq 'pre-sandbox3' -or $Environment -eq 'presandbox3') {
Write-Host 'Beginning search of servers within the customers PreSandbox3 environment.'
start-sleep -Seconds 4
$JsonPreConfiguredPRESB3 = $JsonPreConfigured
if ($Environment -eq 'presb3' -or $Environment -eq 'pre-sb3' -or $Environment -eq 'pre-sandbox3' -or $Environment -eq 'presandbox3') {$JsonPreConfiguredPRESB3 = $JsonPreConfiguredPRESB3 + "phalkon_db_name= " + """phalkon_presb3""" + "`r`n"}
if ($Environment -eq 'presb3' -or $Environment -eq 'pre-sb3' -or $Environment -eq 'pre-sandbox3' -or $Environment -eq 'presandbox3') {if ($GETPRESANDBOX3SQL -ne $null) {$JsonPreConfiguredPRESB3 = $JsonPreConfiguredPRESB3 + "phalkon_db_server= " + """$GETPRESANDBOX3SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'presb3' -or $Environment -eq 'pre-sb3' -or $Environment -eq 'pre-sandbox3' -or $Environment -eq 'presandbox3') {if ($GETNEWPRESANDBOX3SQL -ne $null) {$JsonPreConfiguredPRESB3 = $JsonPreConfiguredPRESB3 + "phalkon_db_server= " + """$GETNEWPRESANDBOX3SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'presb3' -or $Environment -eq 'pre-sb3' -or $Environment -eq 'pre-sandbox3' -or $Environment -eq 'presandbox3') {if ($GETPRESANDBOX3SQL -ne $null) {$JsonPreConfiguredPRESB3 = $JsonPreConfiguredPRESB3 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_presb3""" + "`r`n"}} 
if ($Environment -eq 'presb3' -or $Environment -eq 'pre-sb3' -or $Environment -eq 'pre-sandbox3' -or $Environment -eq 'presandbox3') {if ($GETNEWPRESANDBOX3SQL -ne $null) {$JsonPreConfiguredPRESB3 = $JsonPreConfiguredPRESB3 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_presb3""" + "`r`n"}} 
if ($GETPRESANDBOX3APP -ne $null) {$JsonPreConfiguredPRESB3 = $JsonPreConfiguredPRESB3 + "app_server_name= " + """$GETPRESANDBOX3APP""" + "`r`n"}
if ($GETPRESANDBOX3APP -eq $null) {}
if ($GETPRESANDBOX3PVE -ne $null) {$JsonPreConfiguredPRESB3 = $JsonPreConfiguredPRESB3 + "app_server_name= " + """$GETPRESANDBOX3PVE""" + "`r`n"}
if ($GETPRESANDBOX3PVE -eq $null) {}
if ($GETNEWPRESANDBOX3APP -ne $null) {$JsonPreConfiguredPRESB3 = $JsonPreConfiguredPRESB3 + "app_server_name= " + """$GETNEWPRESANDBOX3APP""" + "`r`n"}
if ($GETNEWPRESANDBOX3APP -eq $null) {}
if ($GETNEWPRESANDBOX3PVE -ne $null) {$JsonPreConfiguredPRESB3 = $JsonPreConfiguredPRESB3 + "app_server_name= " + """$GETNEWPRESANDBOX3PVE""" + "`r`n"}
if ($GETNEWPRESANDBOX3PVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredPRESB3 = $JsonPreConfiguredPRESB3 + "force_uninstall= " + """true""" + "`r`n"}
$PRESANDBOX3SQLCOUNT = $GETPRESANDBOX3SQL + $GETNEWPRESANDBOX3SQL
if ($PRESANDBOX3SQLCOUNT.count -gt 1) {$JsonPreConfiguredPRESB3 = $null}
if ($PRESANDBOX3SQLCOUNT.count -lt 1) {$JsonPreConfiguredPRESB3 = $null}
$PRESANDBOX3APPCOUNT = $GETPRESANDBOX3APP + $GETPRESANDBOX3PVE + $GETNEWPRESANDBOX3APP + $GETNEWPRESANDBOX3PVE
if ($PRESANDBOX3APPCOUNT.count -gt 1) {$JsonPreConfiguredPRESB3 = $null} 
if ($PRESANDBOX3APPCOUNT.count -lt 1) {$JsonPreConfiguredPRESB3 = $null}
if ($Environment -eq 'presb3' -or $Environment -eq 'pre-sb3' -or $Environment -eq 'pre-sandbox3' -or $Environment -eq 'presandbox3') {If ($PRESANDBOX3APPCOUNT -ne $null) {If ($PRESANDBOX3SQLCOUNT -ne $null) {$TargetGroup = $GETPRESANDBOX3APP, $GETPRESANDBOX3WEB, $GETPRESANDBOX3PVE, $GETPRESANDBOX3SQL, $GETNEWPRESANDBOX3APP, $GETNEWPRESANDBOX3WEB, $GETNEWPRESANDBOX3PVE, $GETNEWPRESANDBOX3SQL}}}
if ($PRESANDBOX3SQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRESANDBOX3SQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($PRESANDBOX3SQLCOUNT -ne $null) {if ($PRESANDBOX3SQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
if ($PRESANDBOX3APPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRESANDBOX3APPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($PRESANDBOX3APPCOUNT -ne $null) {if ($PRESANDBOX3APPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
$JsonPreConfiguredPRESB3 = $JsonPreConfiguredPRESB3 + "$optional" + "`r`n"
$JsonPreConfiguredPRESB3 = $JsonPreConfiguredPRESB3 + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($PRESANDBOX3SQLCOUNT.count -gt 1 -or $PRESANDBOX3SQLCOUNT.count -lt 1) { $JsonPreConfiguredPRESB3 = $null }
$JsonConfigured = $JsonPreConfiguredPRESB3
$JsonConfigured
}

elseif ($Environment -eq 'presb4' -or $Environment -eq 'pre-sb4' -or $Environment -eq 'pre-sandbox4' -or $Environment -eq 'presandbox4') {
Write-Host 'Beginning search of servers within the customers PreSandbox4 environment.'
start-sleep -Seconds 4
$JsonPreConfiguredPRESB4 = $JsonPreConfigured
if ($Environment -eq 'presb4' -or $Environment -eq 'pre-sb4' -or $Environment -eq 'pre-sandbox4' -or $Environment -eq 'presandbox4') {$JsonPreConfiguredPRESB4 = $JsonPreConfiguredPRESB4 + "phalkon_db_name= " + """phalkon_presb4""" + "`r`n"}
if ($Environment -eq 'presb4' -or $Environment -eq 'pre-sb4' -or $Environment -eq 'pre-sandbox4' -or $Environment -eq 'presandbox4') {if ($GETPRESANDBOX4SQL -ne $null) {$JsonPreConfiguredPRESB4 = $JsonPreConfiguredPRESB4 + "phalkon_db_server= " + """$GETPRESANDBOX4SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'presb4' -or $Environment -eq 'pre-sb4' -or $Environment -eq 'pre-sandbox4' -or $Environment -eq 'presandbox4') {if ($GETNEWPRESANDBOX4SQL -ne $null) {$JsonPreConfiguredPRESB4 = $JsonPreConfiguredPRESB4 + "phalkon_db_server= " + """$GETNEWPRESANDBOX4SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'presb4' -or $Environment -eq 'pre-sb4' -or $Environment -eq 'pre-sandbox4' -or $Environment -eq 'presandbox4') {if ($GETPRESANDBOX4SQL -ne $null) {$JsonPreConfiguredPRESB4 = $JsonPreConfiguredPRESB4 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_presb4""" + "`r`n"}} 
if ($Environment -eq 'presb4' -or $Environment -eq 'pre-sb4' -or $Environment -eq 'pre-sandbox4' -or $Environment -eq 'presandbox4') {if ($GETNEWPRESANDBOX4SQL -ne $null) {$JsonPreConfiguredPRESB4 = $JsonPreConfiguredPRESB4 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_presb4""" + "`r`n"}} 
if ($GETPRESANDBOX4APP -ne $null) {$JsonPreConfiguredPRESB4 = $JsonPreConfiguredPRESB4 + "app_server_name= " + """$GETPRESANDBOX4APP""" + "`r`n"}
if ($GETPRESANDBOX4APP -eq $null) {}
if ($GETPRESANDBOX4PVE -ne $null) {$JsonPreConfiguredPRESB4 = $JsonPreConfiguredPRESB4 + "app_server_name= " + """$GETPRESANDBOX4PVE""" + "`r`n"}
if ($GETPRESANDBOX4PVE -eq $null) {}
if ($GETNEWPRESANDBOX4APP -ne $null) {$JsonPreConfiguredPRESB4 = $JsonPreConfiguredPRESB4 + "app_server_name= " + """$GETNEWPRESANDBOX4APP""" + "`r`n"}
if ($GETNEWPRESANDBOX4APP -eq $null) {}
if ($GETNEWPRESANDBOX4PVE -ne $null) {$JsonPreConfiguredPRESB4 = $JsonPreConfiguredPRESB4 + "app_server_name= " + """$GETNEWPRESANDBOX4PVE""" + "`r`n"}
if ($GETNEWPRESANDBOX4PVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredPRESB4 = $JsonPreConfiguredPRESB4 + "force_uninstall= " + """true""" + "`r`n"}
$PRESANDBOX4SQLCOUNT = $GETPRESANDBOX4SQL + $GETNEWPRESANDBOX4SQL
if ($PRESANDBOX4SQLCOUNT.count -gt 1) {$JsonPreConfiguredPRESB4 = $null}
if ($PRESANDBOX4SQLCOUNT.count -lt 1) {$JsonPreConfiguredPRESB4 = $null}
$PRESANDBOX4APPCOUNT = $GETPRESANDBOX4APP + $GETPRESANDBOX4PVE + $GETNEWPRESANDBOX4APP + $GETNEWPRESANDBOX4PVE
if ($PRESANDBOX4APPCOUNT.count -gt 1) {$JsonPreConfiguredPRESB4 = $null} 
if ($PRESANDBOX4APPCOUNT.count -lt 1) {$JsonPreConfiguredPRESB4 = $null}
if ($Environment -eq 'presb4' -or $Environment -eq 'pre-sb4' -or $Environment -eq 'pre-sandbox4' -or $Environment -eq 'presandbox4') {If ($PRESANDBOX4APPCOUNT -ne $null) {If ($PRESANDBOX4SQLCOUNT -ne $null) {$TargetGroup = $GETPRESANDBOX4APP, $GETPRESANDBOX4WEB, $GETPRESANDBOX4PVE, $GETPRESANDBOX4SQL, $GETNEWPRESANDBOX4APP, $GETNEWPRESANDBOX4WEB, $GETNEWPRESANDBOX4PVE, $GETNEWPRESANDBOX4SQL}}}
if ($PRESANDBOX4SQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRESANDBOX4SQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($PRESANDBOX4SQLCOUNT -ne $null) {if ($PRESANDBOX4SQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
if ($PRESANDBOX4APPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRESANDBOX4APPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($PRESANDBOX4APPCOUNT -ne $null) {if ($PRESANDBOX4APPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
$JsonPreConfiguredPRESB4 = $JsonPreConfiguredPRESB4 + "$optional" + "`r`n"
$JsonPreConfiguredPRESB4 = $JsonPreConfiguredPRESB4 + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($PRESANDBOX4SQLCOUNT.count -gt 1 -or $PRESANDBOX4SQLCOUNT.count -lt 1) { $JsonPreConfiguredPRESB4 = $null }
$JsonConfigured = $JsonPreConfiguredPRESB4
$JsonConfigured
}

elseif ($Environment -eq 'presb5' -or $Environment -eq 'pre-sb5' -or $Environment -eq 'pre-sandbox5' -or $Environment -eq 'presandbox5') {
Write-Host 'Beginning search of servers within the customers PreSandbox5 environment.'
start-sleep -Seconds 4
$JsonPreConfiguredPRESB5 = $JsonPreConfigured
if ($Environment -eq 'presb5' -or $Environment -eq 'pre-sb5' -or $Environment -eq 'pre-sandbox5' -or $Environment -eq 'presandbox5') {$JsonPreConfiguredPRESB5 = $JsonPreConfiguredPRESB5 + "phalkon_db_name= " + """phalkon_presb5""" + "`r`n"}
if ($Environment -eq 'presb5' -or $Environment -eq 'pre-sb5' -or $Environment -eq 'pre-sandbox5' -or $Environment -eq 'presandbox5') {if ($GETPRESANDBOX5SQL -ne $null) {$JsonPreConfiguredPRESB5 = $JsonPreConfiguredPRESB5 + "phalkon_db_server= " + """$GETPRESANDBOX5SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'presb5' -or $Environment -eq 'pre-sb5' -or $Environment -eq 'pre-sandbox5' -or $Environment -eq 'presandbox5') {if ($GETNEWPRESANDBOX5SQL -ne $null) {$JsonPreConfiguredPRESB5 = $JsonPreConfiguredPRESB5 + "phalkon_db_server= " + """$GETNEWPRESANDBOX5SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'presb5' -or $Environment -eq 'pre-sb5' -or $Environment -eq 'pre-sandbox5' -or $Environment -eq 'presandbox5') {if ($GETPRESANDBOX5SQL -ne $null) {$JsonPreConfiguredPRESB5 = $JsonPreConfiguredPRESB5 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_presb5""" + "`r`n"}} 
if ($Environment -eq 'presb5' -or $Environment -eq 'pre-sb5' -or $Environment -eq 'pre-sandbox5' -or $Environment -eq 'presandbox5') {if ($GETNEWPRESANDBOX5SQL -ne $null) {$JsonPreConfiguredPRESB5 = $JsonPreConfiguredPRESB5 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_presb5""" + "`r`n"}} 
if ($GETPRESANDBOX5APP -ne $null) {$JsonPreConfiguredPRESB5 = $JsonPreConfiguredPRESB5 + "app_server_name= " + """$GETPRESANDBOX5APP""" + "`r`n"}
if ($GETPRESANDBOX5APP -eq $null) {}
if ($GETPRESANDBOX5PVE -ne $null) {$JsonPreConfiguredPRESB5 = $JsonPreConfiguredPRESB5 + "app_server_name= " + """$GETPRESANDBOX5PVE""" + "`r`n"}
if ($GETPRESANDBOX5PVE -eq $null) {}
if ($GETNEWPRESANDBOX5APP -ne $null) {$JsonPreConfiguredPRESB5 = $JsonPreConfiguredPRESB5 + "app_server_name= " + """$GETNEWPRESANDBOX5APP""" + "`r`n"}
if ($GETNEWPRESANDBOX5APP -eq $null) {}
if ($GETNEWPRESANDBOX5PVE -ne $null) {$JsonPreConfiguredPRESB5 = $JsonPreConfiguredPRESB5 + "app_server_name= " + """$GETNEWPRESANDBOX5PVE""" + "`r`n"}
if ($GETNEWPRESANDBOX5PVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredPRESB5 = $JsonPreConfiguredPRESB5 + "force_uninstall= " + """true""" + "`r`n"}
$PRESANDBOX5SQLCOUNT = $GETPRESANDBOX5SQL + $GETNEWPRESANDBOX5SQL
if ($PRESANDBOX5SQLCOUNT.count -gt 1) {$JsonPreConfiguredPRESB5 = $null}
if ($PRESANDBOX5SQLCOUNT.count -lt 1) {$JsonPreConfiguredPRESB5 = $null}
$PRESANDBOX5APPCOUNT = $GETPRESANDBOX5APP + $GETPRESANDBOX5PVE + $GETNEWPRESANDBOX5APP + $GETNEWPRESANDBOX5PVE
if ($PRESANDBOX5APPCOUNT.count -gt 1) {$JsonPreConfiguredPRESB5 = $null} 
if ($PRESANDBOX5APPCOUNT.count -lt 1) {$JsonPreConfiguredPRESB5 = $null}
if ($Environment -eq 'presb5' -or $Environment -eq 'pre-sb5' -or $Environment -eq 'pre-sandbox5' -or $Environment -eq 'presandbox5') {If ($PRESANDBOX5APPCOUNT -ne $null) {If ($PRESANDBOX5SQLCOUNT -ne $null) {$TargetGroup = $GETPRESANDBOX5APP, $GETPRESANDBOX5WEB, $GETPRESANDBOX5PVE, $GETPRESANDBOX5SQL, $GETNEWPRESANDBOX5APP, $GETNEWPRESANDBOX5WEB, $GETNEWPRESANDBOX5PVE, $GETNEWPRESANDBOX5SQL}}}
if ($PRESANDBOX5SQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRESANDBOX5SQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($PRESANDBOX5SQLCOUNT -ne $null) {if ($PRESANDBOX5SQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
if ($PRESANDBOX5APPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRESANDBOX5APPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($PRESANDBOX5APPCOUNT -ne $null) {if ($PRESANDBOX5APPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
$JsonPreConfiguredPRESB5 = $JsonPreConfiguredPRESB5 + "$optional" + "`r`n"
$JsonPreConfiguredPRESB5 = $JsonPreConfiguredPRESB5 + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($PRESANDBOX5SQLCOUNT.count -gt 1 -or $PRESANDBOX5SQLCOUNT.count -lt 1) { $JsonPreConfiguredPRESB5 = $null }
$JsonConfigured = $JsonPreConfiguredPRESB5
$JsonConfigured
}

elseif ($Environment -eq 'presb6' -or $Environment -eq 'pre-sb6' -or $Environment -eq 'pre-sandbox6' -or $Environment -eq 'presandbox6') {
Write-Host 'Beginning search of servers within the customers PreSandbox6 environment.'
start-sleep -Seconds 4
$JsonPreConfiguredPRESB6 = $JsonPreConfigured
if ($Environment -eq 'presb6' -or $Environment -eq 'pre-sb6' -or $Environment -eq 'pre-sandbox6' -or $Environment -eq 'presandbox6') {$JsonPreConfiguredPRESB6 = $JsonPreConfiguredPRESB6 + "phalkon_db_name= " + """phalkon_presb6""" + "`r`n"}
if ($Environment -eq 'presb6' -or $Environment -eq 'pre-sb6' -or $Environment -eq 'pre-sandbox6' -or $Environment -eq 'presandbox6') {if ($GETPRESANDBOX6SQL -ne $null) {$JsonPreConfiguredPRESB6 = $JsonPreConfiguredPRESB6 + "phalkon_db_server= " + """$GETPRESANDBOX6SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'presb6' -or $Environment -eq 'pre-sb6' -or $Environment -eq 'pre-sandbox6' -or $Environment -eq 'presandbox6') {if ($GETNEWPRESANDBOX6SQL -ne $null) {$JsonPreConfiguredPRESB6 = $JsonPreConfiguredPRESB6 + "phalkon_db_server= " + """$GETNEWPRESANDBOX6SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'presb6' -or $Environment -eq 'pre-sb6' -or $Environment -eq 'pre-sandbox6' -or $Environment -eq 'presandbox6') {if ($GETPRESANDBOX6SQL -ne $null) {$JsonPreConfiguredPRESB6 = $JsonPreConfiguredPRESB6 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_presb6""" + "`r`n"}} 
if ($Environment -eq 'presb6' -or $Environment -eq 'pre-sb6' -or $Environment -eq 'pre-sandbox6' -or $Environment -eq 'presandbox6') {if ($GETNEWPRESANDBOX6SQL -ne $null) {$JsonPreConfiguredPRESB6 = $JsonPreConfiguredPRESB6 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_presb6""" + "`r`n"}} 
if ($GETPRESANDBOX6APP -ne $null) {$JsonPreConfiguredPRESB6 = $JsonPreConfiguredPRESB6 + "app_server_name= " + """$GETPRESANDBOX6APP""" + "`r`n"}
if ($GETPRESANDBOX6APP -eq $null) {}
if ($GETPRESANDBOX6PVE -ne $null) {$JsonPreConfiguredPRESB6 = $JsonPreConfiguredPRESB6 + "app_server_name= " + """$GETPRESANDBOX6PVE""" + "`r`n"}
if ($GETPRESANDBOX6PVE -eq $null) {}
if ($GETNEWPRESANDBOX6APP -ne $null) {$JsonPreConfiguredPRESB6 = $JsonPreConfiguredPRESB6 + "app_server_name= " + """$GETNEWPRESANDBOX6APP""" + "`r`n"}
if ($GETNEWPRESANDBOX6APP -eq $null) {}
if ($GETNEWPRESANDBOX6PVE -ne $null) {$JsonPreConfiguredPRESB6 = $JsonPreConfiguredPRESB6 + "app_server_name= " + """$GETNEWPRESANDBOX6PVE""" + "`r`n"}
if ($GETNEWPRESANDBOX6PVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredPRESB6 = $JsonPreConfiguredPRESB6 + "force_uninstall= " + """true""" + "`r`n"}
if ($Environment -eq 'presb6' -or $Environment -eq 'pre-sb6' -or $Environment -eq 'pre-sandbox6' -or $Environment -eq 'presandbox6') {$TargetGroup = $GETPRESANDBOX6APP, $GETPRESANDBOX6WEB, $GETPRESANDBOX6PVE, $GETPRESANDBOX6SQL, $GETNEWPRESANDBOX6APP, $GETNEWPRESANDBOX6WEB, $GETNEWPRESANDBOX6PVE, $GETNEWPRESANDBOX6SQL}
$PRESANDBOX6SQLCOUNT = $GETPRESANDBOX6SQL + $GETNEWPRESANDBOX6SQL
if ($PRESANDBOX6SQLCOUNT.count -gt 1) {$JsonPreConfiguredPRESB6 = $null}
if ($PRESANDBOX6SQLCOUNT.count -lt 1) {$JsonPreConfiguredPRESB6 = $null}
$PRESANDBOX6APPCOUNT = $GETPRESANDBOX6APP + $GETPRESANDBOX6PVE + $GETNEWPRESANDBOX6APP + $GETNEWPRESANDBOX6PVE
if ($PRESANDBOX6APPCOUNT.count -gt 1) {$JsonPreConfiguredPRESB6 = $null} 
if ($PRESANDBOX6APPCOUNT.count -lt 1) {$JsonPreConfiguredPRESB6 = $null}
if ($Environment -eq 'presb6' -or $Environment -eq 'pre-sb6' -or $Environment -eq 'pre-sandbox6' -or $Environment -eq 'presandbox6') {If ($PRESANDBOX6APPCOUNT -ne $null) {If ($PRESANDBOX6SQLCOUNT -ne $null) {$TargetGroup = $GETPRESANDBOX6APP, $GETPRESANDBOX6WEB, $GETPRESANDBOX6PVE, $GETPRESANDBOX6SQL, $GETNEWPRESANDBOX6APP, $GETNEWPRESANDBOX6WEB, $GETNEWPRESANDBOX6PVE, $GETNEWPRESANDBOX6SQL}}}
if ($PRESANDBOX6SQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRESANDBOX6SQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($PRESANDBOX6SQLCOUNT -ne $null) {if ($PRESANDBOX6SQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
if ($PRESANDBOX6APPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRESANDBOX6APPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($PRESANDBOX6APPCOUNT -ne $null) {if ($PRESANDBOX6APPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
$JsonPreConfiguredPRESB6 = $JsonPreConfiguredPRESB6 + "$optional" + "`r`n"
$JsonPreConfiguredPRESB6 = $JsonPreConfiguredPRESB6 + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($PRESANDBOX6SQLCOUNT.count -gt 1 -or $PRESANDBOX6SQLCOUNT.count -lt 1) { $JsonPreConfiguredPRESB6 = $null }
$JsonConfigured = $JsonPreConfiguredPRESB6
$JsonConfigured
}

elseif ($Environment -eq 'production' -or $Environment -eq 'prod') {
Write-Host 'Production sql server is NOT used as Phalkon uses sandbox SQL servers for resource utilzation, to not impeade on production SQL servers.'
start-sleep -Seconds 4
$JsonPreConfiguredPROD = $JsonPreConfigured
if ($Environment -eq 'production' -or $Environment -eq 'prod') {$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "phalkon_db_name= " + """phalkon_prod""" + "`r`n"}
if ($Environment -eq 'production' -or $Environment -eq 'prod') {if ($GETSANDBOXSQL -ne $null)  {$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "phalkon_db_server= " + """$GETSANDBOXSQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'production' -or $Environment -eq 'prod') {if ($GETNEWSANDBOXSQL -ne $null)  {$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "phalkon_db_server= " + """$GETNEWSANDBOXSQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'production' -or $Environment -eq 'prod') {if ($GETSANDBOX1SQL -ne $null)  {$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "phalkon_db_server= " + """$GETSANDBOX1SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'production' -or $Environment -eq 'prod') {if ($GETNEWSANDBOX1SQL -ne $null)  {$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "phalkon_db_server= " + """$GETNEWSANDBOX1SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'production' -or $Environment -eq 'prod') {if ($GETSANDBOXSQL -ne $null) {$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_prod""" + "`r`n"}} 
if ($Environment -eq 'production' -or $Environment -eq 'prod') {if ($GETNEWSANDBOXSQL -ne $null) {$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_prod""" + "`r`n"}} 
if ($Environment -eq 'production' -or $Environment -eq 'prod') {if ($GETSANDBOX1SQL -ne $null) {$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_prod""" + "`r`n"}} 
if ($Environment -eq 'production' -or $Environment -eq 'prod') {if ($GETNEWSANDBOX1SQL -ne $null) {$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_prod""" + "`r`n"}} 
if ($GETPRODAPP -ne $null) {$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "app_server_name= " + """$GETPRODAPP""" + "`r`n"}
if ($GETPRODAPP -eq $null) {}
if ($GETPRODPVE -ne $null) {$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "app_server_name= " + """$GETPRODPVE""" + "`r`n"}
if ($GETPRODPVE -eq $null) {}
if ($GETNEWPRODAPP -ne $null) {$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "app_server_name= " + """$GETNEWPRODAPP""" + "`r`n"}
if ($GETNEWPRODAPP -eq $null) {}
if ($GETNEWPRODPVE -ne $null) {$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "app_server_name= " + """$GETNEWPRODPVE""" + "`r`n"}
if ($GETNEWPRODPVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "force_uninstall= " + """true""" + "`r`n"}
$SANDBOXSQLCOUNT = $GETSANDBOXSQL + $GETNEWSANDBOXSQL + $GETSANDBOX1SQL + $GETNEWSANDBOX1SQL
if ($SANDBOXSQLCOUNT.count -gt 1) {$JsonPreConfiguredPROD = $null}
if ($SANDBOXSQLCOUNT.count -lt 1) {$JsonPreConfiguredPROD = $null}
$PRODAPPCOUNT = $GETPRODAPP + $GETPRODPVE + $GETNEWPRODAPP + $GETNEWPRODPVE
if ($PRODAPPCOUNT.count -gt 1) {$JsonPreConfiguredPROD = $null}
if ($PRODAPPCOUNT.count -lt 1) {$JsonPreConfiguredPROD = $null}
if ($Environment -eq 'production' -or $Environment -eq 'prod') {If ($PRODAPPCOUNT -ne $null) {If ($SANDBOXSQLCOUNT -ne $null) {$TargetGroup = $GETPRODAPP, $GETPRODWEB, $GETPRODPVE, $GETSANDBOXSQL, $GETNEWPRODAPP, $GETNEWPRODWEB, $GETNEWPRODPVE, $GETNEWSANDBOXSQL, $GETSANDBOX1SQL, $GETNEWSANDBOX1SQL}}}
if ($SANDBOXSQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $SANDBOXSQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
if ($SANDBOXSQLCOUNT -ne $null) {if ($SANDBOXSQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
if ($PRODAPPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $PRODAPPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
if ($PRODAPPCOUNT -ne $null) {if ($PRODAPPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "$optional" + "`r`n"
$JsonPreConfiguredPROD = $JsonPreConfiguredPROD + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($SANDBOXSQLCOUNT.count -gt 1 -or $SANDBOXSQLCOUNT.count -lt 1) { $JsonPreConfiguredPROD = $null }
$JsonConfigured = $JsonPreConfiguredPROD
$JsonConfigured
}

elseif ($Environment -eq 'sandbox' -or $Environment -eq 'sb') {
Write-Host 'If no environment is found, please try adding a 1 at the end of sandbox in the environment specified, i.e. sb1 or sandbox1. This is most likely due to the customer having multiple sandbox environments.'
start-sleep -Seconds 4
$JsonPreConfiguredSB = $JsonPreConfigured
if ($Environment -eq 'sandbox' -or $Environment -eq 'sb') {$JsonPreConfiguredSB = $JsonPreConfiguredSB + "phalkon_db_name= " + """phalkon_sb""" + "`r`n"}
if ($Environment -eq 'sandbox' -or $Environment -eq 'sb') {if ($GETSANDBOXSQL -ne $null) {$JsonPreConfiguredSB = $JsonPreConfiguredSB + "phalkon_db_server= " + """$GETSANDBOXSQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'sandbox' -or $Environment -eq 'sb') {if ($GETNEWSANDBOXSQL -ne $null) {$JsonPreConfiguredSB = $JsonPreConfiguredSB + "phalkon_db_server= " + """$GETNEWSANDBOXSQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'sandbox' -or $Environment -eq 'sb') {if ($GETSANDBOXSQL -ne $null) {$JsonPreConfiguredSB = $JsonPreConfiguredSB + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_sb""" + "`r`n"}} 
if ($Environment -eq 'sandbox' -or $Environment -eq 'sb') {if ($GETNEWSANDBOXSQL -ne $null) {$JsonPreConfiguredSB = $JsonPreConfiguredSB + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_sb""" + "`r`n"}} 
if ($GETSANDBOXAPP -ne $null) {$JsonPreConfiguredSB = $JsonPreConfiguredSB + "app_server_name= " + """$GETSANDBOXAPP""" + "`r`n"}
if ($GETSANDBOXAPP -eq $null) {}
if ($GETSANDBOXPVE -ne $null) {$JsonPreConfiguredSB = $JsonPreConfiguredSB + "app_server_name= " + """$GETSANDBOXPVE""" + "`r`n"}
if ($GETSANDBOXPVE -eq $null) {}
if ($GETNEWSANDBOXAPP -ne $null) {$JsonPreConfiguredSB = $JsonPreConfiguredSB + "app_server_name= " + """$GETNEWSANDBOXAPP""" + "`r`n"}
if ($GETNEWSANDBOXAPP -eq $null) {}
if ($GETNEWSANDBOXPVE -ne $null) {$JsonPreConfiguredSB = $JsonPreConfiguredSB + "app_server_name= " + """$GETNEWSANDBOXPVE""" + "`r`n"}
if ($GETNEWSANDBOXPVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredSB = $JsonPreConfiguredSB + "force_uninstall= " + """true""" + "`r`n"}
$SANDBOXSQLCOUNT = $GETSANDBOXSQL + $GETNEWSANDBOXSQL
if ($SANDBOXSQLCOUNT.count -gt 1) {$JsonPreConfiguredSB = $null}
if ($SANDBOXSQLCOUNT.count -lt 1) {$JsonPreConfiguredSB = $null}
$SANDBOXAPPCOUNT = $GETSANDBOXAPP + $GETSANDBOXPVE + $GETNEWSANDBOXAPP + $GETNEWSANDBOXPVE
if ($SANDBOXAPPCOUNT.count -gt 1) {$JsonPreConfiguredSB = $null} 
if ($SANDBOXAPPCOUNT.count -lt 1) {$JsonPreConfiguredSB = $null}
if ($Environment -eq 'sandbox' -or $Environment -eq 'sb') {If ($SANDBOXAPPCOUNT -ne $null) {If ($SANDBOXSQLCOUNT -ne $null) {$TargetGroup = $GETSANDBOXAPP, $GETSANDBOXWEB, $GETSANDBOXPVE, $GETSANDBOXSQL, $GETNEWSANDBOXAPP, $GETNEWSANDBOXWEB, $GETNEWSANDBOXPVE, $GETNEWSANDBOXSQL}}}
if ($SANDBOXSQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $SANDBOXSQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
if ($SANDBOXSQLCOUNT -ne $null) {if ($SANDBOXSQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
if ($SANDBOXAPPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $SANDBOXAPPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
if ($SANDBOXAPPCOUNT -ne $null) {if ($SANDBOXAPPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
$JsonPreConfiguredSB = $JsonPreConfiguredSB + "$optional" + "`r`n"
$JsonPreConfiguredSB = $JsonPreConfiguredSB + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($SANDBOXSQLCOUNT.count -gt 1 -or $SANDBOXSQLCOUNT.count -lt 1) { $JsonPreConfiguredSB = $null }
$JsonConfigured = $JsonPreConfiguredSB
$JsonConfigured
}

elseif ($Environment -eq 'sandbox1' -or $Environment -eq 'sb1') {
Write-Host 'If no environment is found, please try REMOVING the 1 at the end of sandbox in the environment specified, i.e. sb or sandbox, instead of sb1 or sandbox1. This is most likely due to the customer having only 1 sandbox environment.'
start-sleep -Seconds 4
$JsonPreConfiguredSB1 = $JsonPreConfigured +  + $JsonPRESB1
if ($Environment -eq 'sandbox1' -or $Environment -eq 'sb1') {$JsonPreConfiguredSB1 = $JsonPreConfiguredSB1 + "phalkon_db_name= " + """phalkon_sb1""" + "`r`n"}
if ($Environment -eq 'sandbox1' -or $Environment -eq 'sb1') {if ($GETSANDBOX1SQL -ne $null) {$JsonPreConfiguredSB1 = $JsonPreConfiguredSB1 + "phalkon_db_server= " + """$GETSANDBOX1SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'sandbox1' -or $Environment -eq 'sb1') {if ($GETNEWSANDBOX1SQL -ne $null) {$JsonPreConfiguredSB1 = $JsonPreConfiguredSB1 + "phalkon_db_server= " + """$GETNEWSANDBOX1SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'sandbox1' -or $Environment -eq 'sb1') {if ($GETSANDBOX1SQL -ne $null) {$JsonPreConfiguredSB1 = $JsonPreConfiguredSB1 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_sb1""" + "`r`n"}} 
if ($Environment -eq 'sandbox1' -or $Environment -eq 'sb1') {if ($GETNEWSANDBOX1SQL -ne $null) {$JsonPreConfiguredSB1 = $JsonPreConfiguredSB1 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_sb1""" + "`r`n"}} 
if ($GETSANDBOX1APP -ne $null) {$JsonPreConfiguredSB1 = $JsonPreConfiguredSB1 + "app_server_name= " + """$GETSANDBOX1APP""" + "`r`n"}
if ($GETSANDBOX1APP -eq $null) {}
if ($GETSANDBOX1PVE -ne $null) {$JsonPreConfiguredSB1 = $JsonPreConfiguredSB1 + "app_server_name= " + """$GETSANDBOX1PVE""" + "`r`n"}
if ($GETSANDBOX1PVE -eq $null) {}
if ($GETNEWSANDBOX1APP -ne $null) {$JsonPreConfiguredSB1 = $JsonPreConfiguredSB1 + "app_server_name= " + """$GETNEWSANDBOX1APP""" + "`r`n"}
if ($GETNEWSANDBOX1APP -eq $null) {}
if ($GETNEWSANDBOX1PVE -ne $null) {$JsonPreConfiguredSB1 = $JsonPreConfiguredSB1 + "app_server_name= " + """$GETNEWSANDBOX1PVE""" + "`r`n"}
if ($GETNEWSANDBOX1PVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredSB1 = $JsonPreConfiguredSB1 + "force_uninstall= " + """true""" + "`r`n"}
$SANDBOX1SQLCOUNT = $GETSANDBOX1SQL + $GETNEWSANDBOX1SQL
if ($SANDBOX1SQLCOUNT.count -gt 1) {$JsonPreConfiguredSB1 = $null}
if ($SANDBOX1SQLCOUNT.count -lt 1) {$JsonPreConfiguredSB1 = $null}
$SANDBOX1APPCOUNT = $GETSANDBOX1APP + $GETSANDBOX1PVE + $GETNEWSANDBOX1APP + $GETNEWSANDBOX1PVE
if ($SANDBOX1APPCOUNT.count -gt 1) {$JsonPreConfiguredSB1 = $null} 
if ($SANDBOX1APPCOUNT.count -lt 1) {$JsonPreConfiguredSB1 = $null}
if ($Environment -eq 'sandbox1' -or $Environment -eq 'sb1') {If ($SANDBOX1APPCOUNT -ne $null) {If ($SANDBOX1SQLCOUNT -ne $null) {$TargetGroup = $GETSANDBOX1APP, $GETSANDBOX1WEB, $GETSANDBOX1PVE, $GETSANDBOX1SQL, $GETNEWSANDBOX1APP, $GETNEWSANDBOX1WEB, $GETNEWSANDBOX1PVE, $GETNEWSANDBOX1SQL}}}
if ($SANDBOX1SQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $SANDBOX1SQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($SANDBOX1SQLCOUNT -ne $null) {if ($SANDBOX1SQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
if ($SANDBOX1APPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $SANDBOX1APPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($SANDBOX1APPCOUNT -ne $null) {if ($SANDBOX1APPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
$JsonPreConfiguredSB1 = $JsonPreConfiguredSB1 + "$optional" + "`r`n"
$JsonPreConfiguredSB1 = $JsonPreConfiguredSB1 + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($SANDBOX1SQLCOUNT.count -gt 1 -or $SANDBOX1SQLCOUNT.count -lt 1) { $JsonPreConfiguredSB1 = $null }
$JsonConfigured = $JsonPreConfiguredSB1
$JsonConfigured
}

elseif ($Environment -eq 'sandbox2' -or $Environment -eq 'sb2') {
Write-Host 'Beginning search of servers within the customers sandbox2 environment.'
start-sleep -Seconds 4
$JsonPreConfiguredSB2 = $JsonPreConfigured
if ($Environment -eq 'sandbox2' -or $Environment -eq 'sb2') {$JsonPreConfiguredSB2 = $JsonPreConfiguredSB2 + "phalkon_db_name= "  + """phalkon_sb2""" + "`r`n"}
if ($Environment -eq 'sandbox2' -or $Environment -eq 'sb2') {if ($GETSANDBOX2SQL -ne $null) {$JsonPreConfiguredSB2 = $JsonPreConfiguredSB2 + "phalkon_db_server= "  + """$GETSANDBOX2SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'sandbox2' -or $Environment -eq 'sb2') {if ($GETNEWSANDBOX2SQL -ne $null) {$JsonPreConfiguredSB2 = $JsonPreConfiguredSB2 + "phalkon_db_server= "  + """$GETNEWSANDBOX2SQL$domainlong""" + "`r`n"}} 
if ($Environment -eq 'sandbox2' -or $Environment -eq 'sb2') {if ($GETSANDBOX2SQL -ne $null) {$JsonPreConfiguredSB2 = $JsonPreConfiguredSB2 + "phalkon_db_group_name= "  + """$CustomerThreeLetterServerID`_sb2""" + "`r`n"}}
if ($Environment -eq 'sandbox2' -or $Environment -eq 'sb2') {if ($GETNEWSANDBOX2SQL -ne $null) {$JsonPreConfiguredSB2 = $JsonPreConfiguredSB2 + "phalkon_db_group_name= "  + """$CustomerThreeLetterServerID`_sb2""" + "`r`n"}}
if ($GETSANDBOX2APP -ne $null) {$JsonPreConfiguredSB2 = $JsonPreConfiguredSB2 + "app_server_name= "  + """$GETSANDBOX2APP""" + "`r`n"}
if ($GETSANDBOX2APP -eq $null) {}
if ($GETSANDBOX2PVE -ne $null) {$JsonPreConfiguredSB2 = $JsonPreConfiguredSB2 + "app_server_name= "  + """$GETSANDBOX2PVE""" + "`r`n"}
if ($GETSANDBOX2PVE -eq $null) {}
if ($GETNEWSANDBOX2APP -ne $null) {$JsonPreConfiguredSB2 = $JsonPreConfiguredSB2 + "app_server_name= "  + """$GETNEWSANDBOX2APP""" + "`r`n"}
if ($GETNEWSANDBOX2APP -eq $null) {}
if ($GETNEWSANDBOX2PVE -ne $null) {$JsonPreConfiguredSB2 = $JsonPreConfiguredSB2 + "app_server_name= "  + """$GETNEWSANDBOX2PVE""" + "`r`n"}
if ($GETNEWSANDBOX2PVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredSB2 = $JsonPreConfiguredSB2 + "force_uninstall= "  + """true""" + "`r`n"}
$SANDBOX2SQLCOUNT = $GETSANDBOX2SQL + $GETNEWSANDBOX2SQL
if ($SANDBOX2SQLCOUNT.count -gt 1) {$JsonPreConfiguredSB2 = $null}
if ($SANDBOX2SQLCOUNT.count -lt 1) {$JsonPreConfiguredSB2 = $null}
$SANDBOX2APPCOUNT = $GETSANDBOX2APP + $GETSANDBOX2PVE + $GETNEWSANDBOX2APP + $GETNEWSANDBOX2PVE
if ($SANDBOX2APPCOUNT.count -gt 1) {$JsonPreConfiguredSB2 = $null} 
if ($SANDBOX2APPCOUNT.count -lt 1) {$JsonPreConfiguredSB2 = $null}
if ($Environment -eq 'sandbox2' -or $Environment -eq 'sb2') {If ($SANDBOX2APPCOUNT -ne $null) {If ($SANDBOX2SQLCOUNT -ne $null) {$TargetGroup = $GETSANDBOX2APP, $GETSANDBOX2WEB, $GETSANDBOX2PVE, $GETSANDBOX2SQL, $GETNEWSANDBOX2APP, $GETNEWSANDBOX2WEB, $GETNEWSANDBOX2PVE, $GETNEWSANDBOX2SQL}}}
if ($SANDBOX2SQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $SANDBOX2SQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($SANDBOX2SQLCOUNT -ne $null) {if ($SANDBOX2SQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
if ($SANDBOX2APPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $SANDBOX2APPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($SANDBOX2APPCOUNT -ne $null) {if ($SANDBOX2APPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
$JsonPreConfiguredSB2 = $JsonPreConfiguredSB2 + "$optional" + "`r`n"
$JsonPreConfiguredSB2 = $JsonPreConfiguredSB2 + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($SANDBOX2SQLCOUNT.count -gt 1 -or $SANDBOX2SQLCOUNT.count -lt 1) { $JsonPreConfiguredSB2 = $null }
$JsonConfigured = $JsonPreConfiguredSB2
$JsonConfigured
}

elseif ($Environment -eq 'sandbox3' -or $Environment -eq 'sb3') {
Write-Host 'Beginning search of servers within the customers sandbox3 environment.'
start-sleep -Seconds 4
$JsonPreConfiguredSB3 = $JsonPreConfigured
if ($Environment -eq 'sandbox3' -or $Environment -eq 'sb3') {$JsonPreConfiguredSB3 = $JsonPreConfiguredSB3 + "phalkon_db_name= " + """phalkon_sb3""" + "`r`n"}
if ($Environment -eq 'sandbox3' -or $Environment -eq 'sb3') {if ($GETSANDBOX3SQL -ne $null) {$JsonPreConfiguredSB3 = $JsonPreConfiguredSB3 + "phalkon_db_server= " + """$GETSANDBOX3SQL$domainlong""" + "`r`n"}}  
if ($Environment -eq 'sandbox3' -or $Environment -eq 'sb3') {if ($GETNEWSANDBOX3SQL -ne $null) {$JsonPreConfiguredSB3 = $JsonPreConfiguredSB3 + "phalkon_db_server= " + """$GETNEWSANDBOX3SQL$domainlong""" + "`r`n"}}  
if ($Environment -eq 'sandbox3' -or $Environment -eq 'sb3') {if ($GETSANDBOX3SQL -ne $null) {$JsonPreConfiguredSB3 = $JsonPreConfiguredSB3 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_sb3""" + "`r`n"}} 
if ($Environment -eq 'sandbox3' -or $Environment -eq 'sb3') {if ($GETNEWSANDBOX3SQL -ne $null) {$JsonPreConfiguredSB3 = $JsonPreConfiguredSB3 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_sb3""" + "`r`n"}} 
if ($GETSANDBOX3APP -ne $null) {$JsonPreConfiguredSB3 = $JsonPreConfiguredSB3 + "app_server_name= " + """$GETSANDBOX3APP""" + "`r`n"}
if ($GETSANDBOX3APP -eq $null) {}
if ($GETSANDBOX3PVE -ne $null) {$JsonPreConfiguredSB3 = $JsonPreConfiguredSB3 + "app_server_name= " + """$GETSANDBOX3PVE""" + "`r`n"}
if ($GETSANDBOX3PVE -eq $null) {}
if ($GETNEWSANDBOX3APP -ne $null) {$JsonPreConfiguredSB3 = $JsonPreConfiguredSB3 + "app_server_name= " + """$GETNEWSANDBOX3APP""" + "`r`n"}
if ($GETNEWSANDBOX3APP -eq $null) {}
if ($GETNEWSANDBOX3PVE -ne $null) {$JsonPreConfiguredSB3 = $JsonPreConfiguredSB3 + "app_server_name= " + """$GETNEWSANDBOX3PVE""" + "`r`n"}
if ($GETNEWSANDBOX3PVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredSB3 = $JsonPreConfiguredSB3 + "force_uninstall= " + """true""" + "`r`n"}
$SANDBOX3SQLCOUNT = $GETSANDBOX3SQL + $GETNEWSANDBOX3SQL
if ($SANDBOX3SQLCOUNT.count -gt 1) {$JsonPreConfiguredSB3 = $null}
if ($SANDBOX3SQLCOUNT.count -lt 1) {$JsonPreConfiguredSB3 = $null}
$SANDBOX3APPCOUNT = $GETSANDBOX3APP + $GETSANDBOX3PVE + $GETNEWSANDBOX3APP + $GETNEWSANDBOX3PVE
if ($SANDBOX3APPCOUNT.count -gt 1) {$JsonPreConfiguredSB3 = $null} 
if ($SANDBOX3APPCOUNT.count -lt 1) {$JsonPreConfiguredSB3 = $null}
if ($Environment -eq 'sandbox3' -or $Environment -eq 'sb3') {If ($SANDBOX3APPCOUNT -ne $null) {If ($SANDBOX3SQLCOUNT -ne $null) {$TargetGroup = $GETSANDBOX3APP, $GETSANDBOX3WEB, $GETSANDBOX3PVE, $GETSANDBOX3SQL, $GETNEWSANDBOX3APP, $GETNEWSANDBOX3WEB, $GETNEWSANDBOX3PVE, $GETNEWSANDBOX3SQL}}}
if ($SANDBOX3SQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $SANDBOX3SQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($SANDBOX3SQLCOUNT -ne $null) {if ($SANDBOX3SQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
if ($SANDBOX3APPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $SANDBOX3APPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($SANDBOX3APPCOUNT -ne $null) {if ($SANDBOX3APPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
$JsonPreConfiguredSB3 = $JsonPreConfiguredSB3 + "$optional" + "`r`n"
$JsonPreConfiguredSB3 = $JsonPreConfiguredSB3 + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($SANDBOX3SQLCOUNT.count -gt 1 -or $SANDBOX3SQLCOUNT.count -lt 1) { $JsonPreConfiguredSB3 = $null }
$JsonConfigured = $JsonPreConfiguredSB3
$JsonConfigured
}
#
elseif ($Environment -eq 'sandbox4' -or $Environment -eq 'sb4') {
Write-Host 'Beginning search of servers within the customers sandbox4 environment.'
start-sleep -Seconds 4
$JsonPreConfiguredSB4 = $JsonPreConfigured
if ($Environment -eq 'sandbox4' -or $Environment -eq 'sb4') {$JsonPreConfiguredSB4 = $JsonPreConfiguredSB4 + "phalkon_db_name= " + """phalkon_sb4""" + "`r`n"}
if ($Environment -eq 'sandbox4' -or $Environment -eq 'sb4') {if ($GETSANDBOX4SQL -ne $null) {$JsonPreConfiguredSB4 = $JsonPreConfiguredSB4 + "phalkon_db_server= " + """$GETSANDBOX4SQL$domainlong""" + "`r`n"}}  
if ($Environment -eq 'sandbox4' -or $Environment -eq 'sb4') {if ($GETNEWSANDBOX4SQL -ne $null) {$JsonPreConfiguredSB4 = $JsonPreConfiguredSB4 + "phalkon_db_server= " + """$GETNEWSANDBOX4SQL$domainlong""" + "`r`n"}}  
if ($Environment -eq 'sandbox4' -or $Environment -eq 'sb4') {if ($GETSANDBOX4SQL -ne $null) {$JsonPreConfiguredSB4 = $JsonPreConfiguredSB4 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_sb4""" + "`r`n"}} 
if ($Environment -eq 'sandbox4' -or $Environment -eq 'sb4') {if ($GETNEWSANDBOX4SQL -ne $null) {$JsonPreConfiguredSB4 = $JsonPreConfiguredSB4 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_sb4""" + "`r`n"}} 
if ($GETSANDBOX4APP -ne $null) {$JsonPreConfiguredSB4 = $JsonPreConfiguredSB4 + "app_server_name= " + """$GETSANDBOX4APP""" + "`r`n"}
if ($GETSANDBOX4APP -eq $null) {}
if ($GETSANDBOX4PVE -ne $null) {$JsonPreConfiguredSB4 = $JsonPreConfiguredSB4 + "app_server_name= " + """$GETSANDBOX4PVE""" + "`r`n"}
if ($GETSANDBOX4PVE -eq $null) {}
if ($GETNEWSANDBOX4APP -ne $null) {$JsonPreConfiguredSB4 = $JsonPreConfiguredSB4 + "app_server_name= " + """$GETNEWSANDBOX4APP""" + "`r`n"}
if ($GETNEWSANDBOX4APP -eq $null) {}
if ($GETNEWSANDBOX4PVE -ne $null) {$JsonPreConfiguredSB4 = $JsonPreConfiguredSB4 + "app_server_name= " + """$GETNEWSANDBOX4PVE""" + "`r`n"}
if ($GETNEWSANDBOX4PVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredSB4 = $JsonPreConfiguredSB4 + "force_uninstall= " + """true""" + "`r`n"}
$SANDBOX4SQLCOUNT = $GETSANDBOX4SQL + $GETNEWSANDBOX4SQL
if ($SANDBOX4SQLCOUNT.count -gt 1) {$JsonPreConfiguredSB4 = $null}
if ($SANDBOX4SQLCOUNT.count -lt 1) {$JsonPreConfiguredSB4 = $null}
$SANDBOX4APPCOUNT = $GETSANDBOX4APP + $GETSANDBOX4PVE + $GETNEWSANDBOX4APP + $GETNEWSANDBOX4PVE
if ($SANDBOX4APPCOUNT.count -gt 1) {$JsonPreConfiguredSB4 = $null} 
if ($SANDBOX4APPCOUNT.count -lt 1) {$JsonPreConfiguredSB4 = $null}
if ($Environment -eq 'sandbox4' -or $Environment -eq 'sb4') {If ($SANDBOX4APPCOUNT -ne $null) {If ($SANDBOX4SQLCOUNT -ne $null) {$TargetGroup = $GETSANDBOX4APP, $GETSANDBOX4WEB, $GETSANDBOX4PVE, $GETSANDBOX4SQL, $GETNEWSANDBOX4APP, $GETNEWSANDBOX4WEB, $GETNEWSANDBOX4PVE, $GETNEWSANDBOX4SQL}}}
if ($SANDBOX4SQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $SANDBOX4SQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($SANDBOX4SQLCOUNT -ne $null) {if ($SANDBOX4SQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
if ($SANDBOX4APPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $SANDBOX4APPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($SANDBOX4APPCOUNT -ne $null) {if ($SANDBOX4APPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
$JsonPreConfiguredSB4 = $JsonPreConfiguredSB4 + "$optional" + "`r`n"
$JsonPreConfiguredSB4 = $JsonPreConfiguredSB4 + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($SANDBOX4SQLCOUNT.count -gt 1 -or $SANDBOX4SQLCOUNT.count -lt 1) { $JsonPreConfiguredSB4 = $null }
$JsonConfigured = $JsonPreConfiguredSB4
$JsonConfigured
}

elseif ($Environment -eq 'sandbox5' -or $Environment -eq 'sb5') {
Write-Host 'Beginning search of servers within the customers sandbox5 environment.'
start-sleep -Seconds 4
$JsonPreConfiguredSB5 = $JsonPreConfigured
if ($Environment -eq 'sandbox5' -or $Environment -eq 'sb5') {$JsonPreConfiguredSB5 = $JsonPreConfiguredSB5 + "phalkon_db_name= " + """phalkon_sb5""" + "`r`n"}
if ($Environment -eq 'sandbox5' -or $Environment -eq 'sb5') {if ($GETSANDBOX5SQL -ne $null) {$JsonPreConfiguredSB5 = $JsonPreConfiguredSB5 + "phalkon_db_server= " + """$GETSANDBOX5SQL$domainlong""" + "`r`n"}}  
if ($Environment -eq 'sandbox5' -or $Environment -eq 'sb5') {if ($GETNEWSANDBOX5SQL -ne $null) {$JsonPreConfiguredSB5 = $JsonPreConfiguredSB5 + "phalkon_db_server= " + """$GETNEWSANDBOX5SQL$domainlong""" + "`r`n"}}  
if ($Environment -eq 'sandbox5' -or $Environment -eq 'sb5') {if ($GETSANDBOX5SQL -ne $null) {$JsonPreConfiguredSB5 = $JsonPreConfiguredSB5 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_sb5""" + "`r`n"}} 
if ($Environment -eq 'sandbox5' -or $Environment -eq 'sb5') {if ($GETNEWSANDBOX5SQL -ne $null) {$JsonPreConfiguredSB5 = $JsonPreConfiguredSB5 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_sb5""" + "`r`n"}} 
if ($GETSANDBOX5APP -ne $null) {$JsonPreConfiguredSB5 = $JsonPreConfiguredSB5 + "app_server_name= " + """$GETSANDBOX5APP""" + "`r`n"}
if ($GETSANDBOX5APP -eq $null) {}
if ($GETSANDBOX5PVE -ne $null) {$JsonPreConfiguredSB5 = $JsonPreConfiguredSB5 + "app_server_name= " + """$GETSANDBOX5PVE""" + "`r`n"}
if ($GETSANDBOX5PVE -eq $null) {}
if ($GETNEWSANDBOX5APP -ne $null) {$JsonPreConfiguredSB5 = $JsonPreConfiguredSB5 + "app_server_name= " + """$GETNEWSANDBOX5APP""" + "`r`n"}
if ($GETNEWSANDBOX5APP -eq $null) {}
if ($GETNEWSANDBOX5PVE -ne $null) {$JsonPreConfiguredSB5 = $JsonPreConfiguredSB5 + "app_server_name= " + """$GETNEWSANDBOX5PVE""" + "`r`n"}
if ($GETNEWSANDBOX5PVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredSB5 = $JsonPreConfiguredSB5 + "force_uninstall= " + """true""" + "`r`n"}
$SANDBOX5SQLCOUNT = $GETSANDBOX5SQL + $GETNEWSANDBOX5SQL
if ($SANDBOX5SQLCOUNT.count -gt 1) {$JsonPreConfiguredSB5 = $null}
if ($SANDBOX5SQLCOUNT.count -lt 1) {$JsonPreConfiguredSB5 = $null}
$SANDBOX5APPCOUNT = $GETSANDBOX5APP + $GETSANDBOX5PVE + $GETNEWSANDBOX5APP + $GETNEWSANDBOX5PVE
if ($SANDBOX5APPCOUNT.count -gt 1) {$JsonPreConfiguredSB5 = $null} 
if ($SANDBOX5APPCOUNT.count -lt 1) {$JsonPreConfiguredSB5 = $null}
if ($Environment -eq 'sandbox5' -or $Environment -eq 'sb5') {If ($SANDBOX5APPCOUNT -ne $null) {If ($SANDBOX5SQLCOUNT -ne $null) {$TargetGroup = $GETSANDBOX5APP, $GETSANDBOX5WEB, $GETSANDBOX5PVE, $GETSANDBOX5SQL, $GETNEWSANDBOX5APP, $GETNEWSANDBOX5WEB, $GETNEWSANDBOX5PVE, $GETNEWSANDBOX5SQL}}}
if ($SANDBOX5SQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $SANDBOX5SQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($SANDBOX5SQLCOUNT -ne $null) {if ($SANDBOX5SQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
if ($SANDBOX5APPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $SANDBOX5APPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($SANDBOX5APPCOUNT -ne $null) {if ($SANDBOX5APPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
$JsonPreConfiguredSB5 = $JsonPreConfiguredSB5 + "$optional" + "`r`n"
$JsonPreConfiguredSB5 = $JsonPreConfiguredSB5 + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($SANDBOX5SQLCOUNT.count -gt 1 -or $SANDBOX5SQLCOUNT.count -lt 1) { $JsonPreConfiguredSB5 = $null }
$JsonConfigured = $JsonPreConfiguredSB5
$JsonConfigured
}

elseif ($Environment -eq 'sandbox6' -or $Environment -eq 'sb6') {
Write-Host 'Beginning search of servers within the customers sandbox6 environment.'
start-sleep -Seconds 4
$JsonPreConfiguredSB6 = $JsonPreConfigured
if ($Environment -eq 'sandbox6' -or $Environment -eq 'sb6') {$JsonPreConfiguredSB6 = $JsonPreConfiguredSB6 + "phalkon_db_name= " + """phalkon_sb6""" + "`r`n"}
if ($Environment -eq 'sandbox6' -or $Environment -eq 'sb6') {if ($GETSANDBOX6SQL -ne $null) {$JsonPreConfiguredSB6 = $JsonPreConfiguredSB6 + "phalkon_db_server= " + """$GETSANDBOX6SQL$domainlong""" + "`r`n"}}  
if ($Environment -eq 'sandbox6' -or $Environment -eq 'sb6') {if ($GETNEWSANDBOX6SQL -ne $null) {$JsonPreConfiguredSB6 = $JsonPreConfiguredSB6 + "phalkon_db_server= " + """$GETNEWSANDBOX6SQL$domainlong""" + "`r`n"}}  
if ($Environment -eq 'sandbox6' -or $Environment -eq 'sb6') {if ($GETSANDBOX6SQL -ne $null) {$JsonPreConfiguredSB6 = $JsonPreConfiguredSB6 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_sb6""" + "`r`n"}} 
if ($Environment -eq 'sandbox6' -or $Environment -eq 'sb6') {if ($GETNEWSANDBOX6SQL -ne $null) {$JsonPreConfiguredSB6 = $JsonPreConfiguredSB6 + "phalkon_db_group_name= " + """$CustomerThreeLetterServerID`_sb6""" + "`r`n"}} 
if ($GETSANDBOX6APP -ne $null) {$JsonPreConfiguredSB6 = $JsonPreConfiguredSB6 + "app_server_name= " + """$GETSANDBOX6APP""" + "`r`n"}
if ($GETSANDBOX6APP -eq $null) {}
if ($GETSANDBOX6PVE -ne $null) {$JsonPreConfiguredSB6 = $JsonPreConfiguredSB6 + "app_server_name= " + """$GETSANDBOX6PVE""" + "`r`n"}
if ($GETSANDBOX6PVE -eq $null) {}
if ($GETNEWSANDBOX6APP -ne $null) {$JsonPreConfiguredSB6 = $JsonPreConfiguredSB6 + "app_server_name= " + """$GETNEWSANDBOX6APP""" + "`r`n"}
if ($GETNEWSANDBOX6APP -eq $null) {}
if ($GETNEWSANDBOX6PVE -ne $null) {$JsonPreConfiguredSB6 = $JsonPreConfiguredSB6 + "app_server_name= " + """$GETNEWSANDBOX6PVE""" + "`r`n"}
if ($GETNEWSANDBOX6PVE -eq $null) {}
if ($UninstallPhalkon -eq 'true' -or $UninstallPhalkon -eq 'yes') {$JsonPreConfiguredSB6 = $JsonPreConfiguredSB6 + "force_uninstall= " + """true""" + "`r`n"}
$SANDBOX6SQLCOUNT = $GETSANDBOX6SQL + $GETNEWSANDBOX6SQL
if ($SANDBOX6SQLCOUNT.count -gt 1) {$JsonPreConfiguredSB6 = $null}
if ($SANDBOX6SQLCOUNT.count -lt 1) {$JsonPreConfiguredSB6 = $null}
$SANDBOX6APPCOUNT = $GETSANDBOX6APP + $GETSANDBOX6PVE + $GETNEWSANDBOX6APP + $GETNEWSANDBOX6PVE
if ($SANDBOX6APPCOUNT.count -gt 1) {$JsonPreConfiguredSB6 = $null} 
if ($SANDBOX6APPCOUNT.count -lt 1) {$JsonPreConfiguredSB6 = $null}
if ($Environment -eq 'sandbox6' -or $Environment -eq 'sb6') {If ($SANDBOX6APPCOUNT -ne $null) {If ($SANDBOX6SQLCOUNT -ne $null) {$TargetGroup = $GETSANDBOX6APP, $GETSANDBOX6WEB, $GETSANDBOX6PVE, $GETSANDBOX6SQL, $GETNEWSANDBOX6APP, $GETNEWSANDBOX6WEB, $GETNEWSANDBOX6PVE, $GETNEWSANDBOX6SQL}}}
if ($SANDBOX6SQLCOUNT.count -gt 1) {Write-Host "There have been too many SQL servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $SANDBOX6SQLCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($SANDBOX6SQLCOUNT -ne $null) {if ($SANDBOX6SQLCOUNT.count -lt 1) {Write-Host "The environments seems to be missing a sandbox SQL server, please review the prod/sandbox environments as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
if ($SANDBOX6APPCOUNT.count -gt 1) {Write-Host "There have been too many APP/PVE servers detected in Active Directory, please delete the old servers and finish the decomission process before moving forward with the Phalkon installation. The servers detected are the following: $SANDBOX6APPCOUNT" -ForegroundColor Red -BackgroundColor Yellow }
If ($SANDBOX6APPCOUNT -ne $null) {if ($SANDBOX6APPCOUNT.count -lt 1) {Write-Host "The environment seems to be missing an App/PVE server, please review the environment as well as Active Directory: $TargetGroup" -ForegroundColor Red -BackgroundColor Yellow }}
$JsonPreConfiguredSB6 = $JsonPreConfiguredSB6 + "$optional" + "`r`n"
$JsonPreConfiguredSB6 = $JsonPreConfiguredSB6 + "sql_connection_timeout_secs= "  + 30 + "`r`n"
if ($SANDBOX6SQLCOUNT.count -gt 1 -or $SANDBOX6SQLCOUNT.count -lt 1) { $JsonPreConfiguredSB6 = $null }
$JsonConfigured = $JsonPreConfiguredSB6
$JsonConfigured
}



foreach ($APP_PVE in $TargetGroup)
  { If ($APP_PVE -like '*APP*' -and $APP_PVE -like '*PVE*') 
    { If ($APP_PVE.$APP_Node_total.count -gt 1 -or $APP_PVE.$APP_Node_total.count -lt 1) 
        { write-host "there is more than or less than 1 APP/PVE server detected, below is the detected APP/PVE servers, please check and correct Active Directory, each OU for prod, sb etc. should only have 1 APP/PVE server per OU: 
        $APP_PVE.$APP_Node_total"  -ForegroundColor Red -BackgroundColor Yellow }
    }
  }






$node1.$app_node1.
$node2.$pve_node2.count
$APP_PVE.$APP_Node_total.COUNT 






foreach ($node in $TargetGroup)
  {If ($node -like '*SQL*')
    {If ($SQLNode.count -gt 1 -or $SQLNode.count -lt 1)
        {write-host "there is more than or less than 1 SQL server detected, below is the detected SQL servers, please check and correct Active Directory, each OU for prod, sb etc. should only have 1 SQL server per OU: 
        $node.$SQLNode"  -ForegroundColor Red -BackgroundColor Yellow}
    }
  }
    
  

If ($SQLNode.count -gt 1 -or $SQLNode.count -lt 1)
        {write-host "The ini has been nullified due to the SQL Server count" -ForegroundColor Red -BackgroundColor Yellow}



If ($SQLNode.count -eq 1)
        {
write-host "
===================================================================================================================================================================================================
Beginning the phalkon database backup step.........
===================================================================================================================================================================================================
"


If ($Environment -eq 'production' -or $Environment -eq 'prod')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
              {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_prod TO DISK = 'F:\SQLBackup\phalkon_prod_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_prod -ErrorAction Ignore } -ErrorAction Ignore
              }
            }
        }
If ($Environment -eq 'sandbox' -or $Environment -eq 'sb')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
                {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_sb TO DISK = 'F:\SQLBackup\phalkon_sb_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_sb -ErrorAction Ignore } -ErrorAction Ignore
                }
            }
        }
If ($Environment -eq 'sandbox1' -or $Environment -eq 'sb1')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
                {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_sb1 TO DISK = 'F:\SQLBackup\phalkon_sb1_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_sb -ErrorAction Ignore } -ErrorAction Ignore
                }
            }
        }
If ($Environment -eq 'sandbox2' -or $Environment -eq 'sb2')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
                {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_sb2 TO DISK = 'F:\SQLBackup\phalkon_sb2_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_sb -ErrorAction Ignore } -ErrorAction Ignore
                }
            }
        }
If ($Environment -eq 'sandbox3' -or $Environment -eq 'sb3')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
                {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_sb3 TO DISK = 'F:\SQLBackup\phalkon_sb3_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_sb -ErrorAction Ignore } -ErrorAction Ignore
                }
            }
        }
If ($Environment -eq 'sandbox4' -or $Environment -eq 'sb4')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
                {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_sb4 TO DISK = 'F:\SQLBackup\phalkon_sb4_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_sb -ErrorAction Ignore } -ErrorAction Ignore
                }
            }
        }
If ($Environment -eq 'sandbox5' -or $Environment -eq 'sb5')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
                {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_sb5 TO DISK = 'F:\SQLBackup\phalkon_sb5_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_sb -ErrorAction Ignore } -ErrorAction Ignore
                }
            }
        }
If ($Environment -eq 'sandbox6' -or $Environment -eq 'sb6')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
                {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_sb6 TO DISK = 'F:\SQLBackup\phalkon_sb6_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_sb -ErrorAction Ignore } -ErrorAction Ignore
                }
            }
        }
If ($Environment -eq 'preprod' -or $Environment -eq 'pre-prod' -or $Environment -eq 'pre-production' -or $Environment -eq 'preproduction')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
                {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_sb TO DISK = 'F:\SQLBackup\phalkon_sb_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_sb -ErrorAction Ignore } -ErrorAction Ignore
                }
            }
        }
If ($Environment -eq 'presb' -or $Environment -eq 'pre-sb' -or $Environment -eq 'pre-sandbox' -or $Environment -eq 'presandbox')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
                {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_presb TO DISK = 'F:\SQLBackup\phalkon_presb_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_sb -ErrorAction Ignore } -ErrorAction Ignore
                }
            }
        }
If ($Environment -eq 'presb1' -or $Environment -eq 'pre-sb1' -or $Environment -eq 'pre-sandbox1' -or $Environment -eq 'presandbox1')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
                {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_presb1 TO DISK = 'F:\SQLBackup\phalkon_presb1_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_sb -ErrorAction Ignore } -ErrorAction Ignore
                }
            }
        }
If ($Environment -eq 'presb2' -or $Environment -eq 'pre-sb2' -or $Environment -eq 'pre-sandbox2' -or $Environment -eq 'presandbox2')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
                {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_presb2 TO DISK = 'F:\SQLBackup\phalkon_presb2_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_sb -ErrorAction Ignore } -ErrorAction Ignore
                }
            }
        }
If ($Environment -eq 'presb3' -or $Environment -eq 'pre-sb3' -or $Environment -eq 'pre-sandbox3' -or $Environment -eq 'presandbox3')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
                {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_presb3 TO DISK = 'F:\SQLBackup\phalkon_presb3_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_sb -ErrorAction Ignore } -ErrorAction Ignore
                }
            }
        }
If ($Environment -eq 'presb4' -or $Environment -eq 'pre-sb4' -or $Environment -eq 'pre-sandbox4' -or $Environment -eq 'presandbox4')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
                {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_presb4 TO DISK = 'F:\SQLBackup\phalkon_presb4_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_sb -ErrorAction Ignore } -ErrorAction Ignore
                }
            }
        }
If ($Environment -eq 'presb5' -or $Environment -eq 'pre-sb5' -or $Environment -eq 'pre-sandbox5' -or $Environment -eq 'presandbox5')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
                {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_presb5 TO DISK = 'F:\SQLBackup\phalkon_presb5_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_sb -ErrorAction Ignore } -ErrorAction Ignore
                }
            }
        }
If ($Environment -eq 'presb6' -or $Environment -eq 'pre-sb6' -or $Environment -eq 'pre-sandbox6' -or $Environment -eq 'presandbox6')
        {foreach ($node in $TargetGroup)
            {if ($node -like '*SQL*')
                {foreach ($SQLnode in $node)
                {Write-Host "About to begin backing up the old Phalkon database on $SQLnode if it can be found for $Environment"}
                Invoke-Command -ComputerName $SQLnode -ScriptBlock { Invoke-Sqlcmd -query "BACKUP DATABASE phalkon_presb6 TO DISK = 'F:\SQLBackup\phalkon_presb6_.bak' WITH FORMAT;
                END
                CLOSE db_cursor
                DEALLOCATE db_cursor" -serverinstance $SQLnode -database phalkon_sb -ErrorAction Ignore } -ErrorAction Ignore
                }
            }
        }
}
    


write-host "
===================================================================================================================================================================================================
Beginning the phalkon install with ini and choco package file transfer.........
===================================================================================================================================================================================================
"




foreach ($node in $TargetGroup)
  {If ($node -like '*WEB*')
    {foreach ($webnode in $node) 
        {Write-Host 
"
===================================================================================================================================================================================================
found web server ""$WEBnode""
===================================================================================================================================================================================================
"
        $WEBNODE1 = $webnode
        if (Test-Path \\$webnode1\c$\Deploy\Phalkon\)
            {Write-Host "The path C:\Deploy\Phalkon exists...."}
            else 
                {New-Item -ItemType Directory -Path \\$WEBNODE1\c$\Deploy\ -Name Phalkon -Force}
        $WEBnodePath = "\\$WEBnode1\c$\Deploy\Phalkon"
        write-host "About to begin copying Phalkon_DSC_Config.ini to $WEBnodePath....."
        start-sleep -Seconds 2
        $JsonConfigured | Out-File -FilePath "$WEBnodePath\Phalkon_DSC_Config.ini"
        write-host "Phalkon_DSC_Config.ini has been copied to $WEBnodePath successfully"
        start-sleep -seconds 2
        write-host "About to copy choco package to $WEBnodePath"
        Start-Sleep -Seconds 2
        Copy-Item -Path "$PackagesPath\Phalkon_DSC.3.0.0.nupkg" -Destination "$WEBnodePath" -Force -ErrorAction SilentlyContinue
        start-sleep -seconds 2
        write-host "Choco package copied successfully!!!!!! Beginning the Choco Phalkon installation....."
        start-sleep -seconds 2
        Write-Host 
"
***********************************************************************************************************
Beginning to run the choco install/uninstall on $WEBNODE1, please watch for errors in the output
***********************************************************************************************************  
"
        Start-Sleep -Seconds 5
        If ($SQLNode.count -eq 1 -and $APP_PVE_Node.count -eq 1)
        {if ($UninstallPhalkon) {invoke-command -ComputerName $WEBNODE1 -ScriptBlock {choco uninstall Phalkon_DSC -s C:\deploy\Phalkon -y --params "/ConfigPath=C:\Deploy\Phalkon\Phalkon_DSC_Config.ini /InstallLocation=C:\Planview\Interfaces\installs" --force } -ErrorAction SilentlyContinue } 
        else {invoke-command -ComputerName $WEBNODE1 -ScriptBlock {choco install Phalkon_DSC -s C:\deploy\Phalkon -y --params "/ConfigPath=C:\Deploy\Phalkon\Phalkon_DSC_Config.ini /InstallLocation=C:\Planview\Interfaces\installs" --force } -ErrorAction SilentlyContinue }
    }
    else {write-host "The install is nullified due to the SQL Server count, please check the previous logs" -ForegroundColor Red -BackgroundColor Yellow }
    }
    }
   elseif ($node -like '*PVE*')
    {foreach ($PVEnode in $node) 
        {Write-Host 
"
===================================================================================================================================================================================================
found pve server ""$PVEnode""
===================================================================================================================================================================================================
"
        $PVENODE1 = $PVEnode + '$Domainserver'
        if (Test-Path \\$PVEnode1\c$\Deploy\Phalkon\)
            {Write-Host "The path C:\Deploy\Phalkon exists, copying files to PVE server"}
            else 
                {New-Item -ItemType Directory -Path \\$PVEnode1\c$\Deploy\ -Name Phalkon -Force}
        $PVEnodePath = "\\$PVEnode1\c$\Deploy\Phalkon"
        write-host "About to begin copying Phalkon_DSC_Config.ini to $PVEnodePath....."
        start-sleep -Seconds 2
        $JsonConfigured | Out-File -FilePath "$PVEnodePath\Phalkon_DSC_Config.ini"
        write-host "Phalkon_DSC_Config.ini has been copied to $PVEnodePath successfully"
        start-sleep -seconds 2
        write-host "About to copy choco package to $PVEnodePath"
        Start-Sleep -Seconds 2
        Copy-Item -Path "$PackagesPath\Phalkon_DSC.3.0.0.nupkg" -Destination "$PVEnodePath" -Force -ErrorAction SilentlyContinue
        start-sleep -seconds 2
        write-host "Choco package copied successfully!!!!!! Beginning the Choco Phalkon installation....."
        start-sleep -seconds 2
        Write-Host 
"
***********************************************************************************************************
Beginning to run the choco install/uninstall actions on $PVENODE1, please watch for errors in the output
***********************************************************************************************************
"
        Start-Sleep -Seconds 5
        If ($SQLNode.count -eq 1 -and $APP_PVE_Node.count -eq 1)
        {if ($UninstallPhalkon) {invoke-command -ComputerName $PVENODE1 -ScriptBlock {choco uninstall Phalkon_DSC -s C:\deploy\Phalkon -y --params "/ConfigPath=C:\deploy\Phalkon\Phalkon_DSC_Config.ini /InstallLocation=C:\Planview\Interfaces\installs" --force } -ErrorAction SilentlyContinue } 
        else {invoke-command -ComputerName $PVENODE1 -ScriptBlock {choco install Phalkon_DSC -s C:\deploy\Phalkon -y --params "/ConfigPath=C:\deploy\Phalkon\Phalkon_DSC_Config.ini /InstallLocation=C:\Planview\Interfaces\installs" --force } -ErrorAction SilentlyContinue }   
    }
    else {write-host "The install is nullified due to the SQL Server count, please check the previous logs" -ForegroundColor Red -BackgroundColor Yellow }
    }
    }
   elseif ($node -like '*APP*')
    {foreach ($APPnode in $node) 
        {Write-Host 
"
===================================================================================================================================================================================================
found app server ""$APPnode""
===================================================================================================================================================================================================
"
        $APPNODE1 = $APPnode + '$Domainserver'
        if (Test-Path \\$APPNODE1\c$\Deploy\Phalkon\)
            {Write-Host "The path C:\Deploy\Phalkon exists, copying files to APP server"}
            else 
                {New-Item -ItemType Directory -Path \\$APPNODE1\c$\Deploy\ -Name Phalkon -Force}
        $APPnodePath = "\\$APPNODE1\c$\Deploy\Phalkon"
        write-host "About to begin copying Phalkon_DSC_Config.ini to $APPnodePath....."
        start-sleep -Seconds 2
        $JsonConfigured | Out-File -FilePath "$APPnodePath\Phalkon_DSC_Config.ini"
        write-host "Phalkon_DSC_Config.ini has been copied to $APPnodePath successfully"
        start-sleep -seconds 2
        write-host "About to copy choco package to $APPnodePath"
        Start-Sleep -Seconds 2
        Copy-Item -Path "$PackagesPath\Phalkon_DSC.3.0.0.nupkg" -Destination "$APPnodePath" -Force -ErrorAction SilentlyContinue
        start-sleep -seconds 2
        write-host "Choco package copied successfully!!!!!! Beginning the Choco Phalkon installation....."
        start-sleep -seconds 2
        Write-Host 
"
***********************************************************************************************************
Beginning to run the choco install/uninstall on $APPNODE1, please watch for errors in the output
***********************************************************************************************************
"
        Start-Sleep -Seconds 5
        If ($SQLNode.count -eq 1 -and $APP_PVE_Node.count -eq 1)
        {if ($UninstallPhalkon) {invoke-command -ComputerName $APPNODE1 -ScriptBlock {choco uninstall Phalkon_DSC -s C:\Deploy\Phalkon -y --params "/ConfigPath=C:\Deploy\Phalkon\Phalkon_DSC_Config.ini /InstallLocation=C:\Planview\Interfaces\installs" --force } -ErrorAction SilentlyContinue } 
         else {invoke-command -ComputerName $APPNODE1 -ScriptBlock {choco install Phalkon_DSC -s C:\Deploy\Phalkon -y --params "/ConfigPath=C:\Deploy\Phalkon\Phalkon_DSC_Config.ini /InstallLocation=C:\Planview\Interfaces\installs" --force } -ErrorAction SilentlyContinue }
    }
    else {write-host "The install is nullified due to the SQL Server count, please check the previous logs" -ForegroundColor Red -BackgroundColor Yellow }
    }
    }
  }
}
