$workingDir = 'SCRUBBED_PATH'

# get all servers
$AllServers = Get-DnsServerResourceRecord SCRUBBED
#$AllServers += Get-DnsServerResourceRecord -ComputerName SCRUBBED
$PVEServers = ($AllServers | where { $_.HostName -match 'SCRUBBED_NAME_AND_DOMAIN'}
$PVEServers.Count

Import-Module PoshRsJob

$PVEServers | Start-RSJob -Name { $_ } -Throttle 20 -ScriptBlock {
    try {
        $Target = $_
        $PrmDbConnPath = ('\\'+'SCRUBBED_PATH')
        $ReServerUrl = Get-Content $PrmDbConnPath | where {$_ -match 'SCRUBBED_PATH'} | sort -Unique

        # return result object to PoshRsJob
        [pscustomobject]@{
            ComputerName = $Target
            ReServerUrl = $ReServerUrl
            Error = ''
        }
    }
    catch {
        # return result object to PoshRsJob with Error
        [pscustomobject]@{
            ComputerName = $Target
            ReServerUrl = $ReServerUrl
            Error = ($_ | Out-String)
        }
    }
    finally {
        $PrmDbConnPath,$ReServerUrl = $null
    }
}

# dump all output into an array object
$Found = Get-RSJob | Wait-RSJob | Receive-RSJob
# cleanup rsjobs so you can re-run with new output
Get-RSJob | Remove-RSJob -Force

# Get count of errors
($Found | where {$_.Error -ne ''}).count


($Found | where {$_.ReServerUrl -and $_.Error -eq ''}).count

($Found | where {$_.ReServerUrl -and $_.Error -eq ''}).ReServerUrl | sort -Unique

#Import-Module $myhelperpath
#Get-Occurance ($Found | where {$_.ReServerUrl -and $_.Error -eq ''}).ReServerUrl

($Found | where {$_.ReServerUrl -match 'SCRUBBED_DOMAIN_NAME' -and $_.Error -eq ''}).count

($Found | where {$_.ReServerUrl -match 'SCRUBBED_DOMAIN_NAME' -and $_.Error -eq ''}) | ConvertTo-Csv -NoTypeInformation | Out-File ($workingDir+'\SCRUBBED') -Force
