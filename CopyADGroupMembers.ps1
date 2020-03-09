﻿#requires -modules ActiveDirectory
<#
.SYNOPSIS
  Copy AD group members from one AD group to another AD group in the same domain
.DESCRIPTION
  This script provides a GUI to quickly copy AD group members to another existing group in the same domain. Multi-domain forests are supported, the script will query for the AD domain.
.PARAMETER <Parameter_Name>
    None
.INPUTS
  AD Domain, Source AD group, Destination AD Group
.OUTPUTS
  None
.NOTES
  Version:        1.0
  Author:         Bart Jacobs - @Cloudsparkle
  Creation Date:  09/03/2020
  Purpose/Change: Copy AD Group members to another group
  
.EXAMPLE
  None
#>

#Initialize variables
$SelectedDomain = ""
$SourceGroup = ""
$DestinationGroup = ""

Add-Type -AssemblyName PresentationFramework

$ADForestInfo = Get-ADForest
$SelectedDomain = $ADForestInfo.Domains | Out-GridView -passthru -Title "Select AD Domain"

if ($SelectedDomain -eq $null)
{
[System.Windows.MessageBox]::Show("AD Domain not selected","Error","OK","Error")
exit
}

$dc = Get-ADDomainController -DomainName $SelectedDomain -Discover -NextClosestSite
$ADGroupList = Get-ADGroup -filter * -Server $SelectedDomain | sort name | select Name
$SourceGroup = $ADGroupList | Out-GridView -PassThru -Title "Select the AD Group Name who's members needs to be copied" 
$DestinationGroup = $ADGroupList | Out-GridView -PassThru -Title "Select the AD Group Name that needs to be populated" 

if ($SourceGroup -eq $null)
{
[System.Windows.MessageBox]::Show("Source group not selected","Error","OK","Error")
exit 1
}

if ($DestinationGroup -eq $null)
{
[System.Windows.MessageBox]::Show("Destination group not selected","Error","OK","Error")
exit 1
}

if ($SourceGroup -eq $DestinationGroup)
{
[System.Windows.MessageBox]::Show("Source and Destination groups can not be the same","Error","OK","Error")
exit 1
}

$member = Get-ADGroupMember -Identity $SourceGroup.Name -Server $dc.HostName[0]

Try 
{
Add-ADGroupMember -Identity $DestinationGroup.name -Members $member -Server $dc.HostName[0]
$message = "Members of AD Group " + $SourceGroup.name + "have been copied to AD Group " + $DestinationGroup.Name
[System.Windows.MessageBox]::Show($message,"Finished","OK","Asterisk")
}
Catch
{
[System.Windows.MessageBox]::Show("AD Group membership copy failed","Error","OK","Error")
}