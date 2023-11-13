#requires -modules ActiveDirectory
<#
.SYNOPSIS
  Copy AD group members from one AD group to other AD group(s) in the same domain
.DESCRIPTION
  This script provides a GUI to quickly copy AD group members to other existing group(s) in the same domain. Multi-domain forests are supported, the script will query for the AD domain.
.PARAMETER <Parameter_Name>
    None
.INPUTS
  AD Domain, Source AD group, Destination AD Group
.OUTPUTS
  None
.NOTES
  Version:        2.0
  Author:         Bart Jacobs - @Cloudsparkle
  Creation Date:  20/02/23
  Purpose/Change: Copy AD Group members to other group(s)

.EXAMPLE
  None
#>

#Initialize variables
$SelectedDomain = ""
$SourceGroup = ""
$DestinationGroup = ""

Add-Type -AssemblyName PresentationFramework

#Get the AD DomainName
$ADForestInfo = Get-ADForest
$SelectedDomain = $ADForestInfo.Domains | Out-GridView -Title "Select AD Domain" -OutputMode Single

#Check for a valid DomainName
if ($SelectedDomain -eq $null)
  {
    $msgBoxInput = [System.Windows.MessageBox]::Show("AD Domain not selected","Error","OK","Error")
    switch  ($msgBoxInput)
    {
      "OK"
      {
        Exit 1
      }
    }
  }

#Find the right AD Domain Controller
$dc = Get-ADDomainController -DomainName $SelectedDomain -Discover
$dc = $dc.HostName

#Get all groups from selected and select source and destination groups
$ADGroupList = Get-ADGroup -filter * -Server $dc[0] | sort-object name | select-object Name
if ($null -eq $ADGroupList)
{
  $msgBoxInput = [System.Windows.MessageBox]::Show("Error getting AD groups","Error","OK","Error")
  switch  ($msgBoxInput)
  {
    "OK"
    {
      Exit 1
    }
  }
}

$SourceGroup = $ADGroupList | Out-GridView -Title "Select the SOURCE AD Group" -OutputMode Single
if ($null -eq $SourceGroup)
{
  $msgBoxInput = [System.Windows.MessageBox]::Show("Source group not selected","Error","OK","Error")
  switch  ($msgBoxInput)
  {
    "OK"
    {
      Exit 1
    }
  }
}
else
{
  $SourceGroupName = $SourceGroup.name
}

$DestinationGroups = $ADGroupList | Out-GridView -Title "Select the DESTINATION AD Group(s)" -OutputMode Multiple

if ($null -eq $DestinationGroups)
{
  $msgBoxInput = [System.Windows.MessageBox]::Show("Destination group(s) not selected","Error","OK","Error")
  switch  ($msgBoxInput)
  {
    "OK"
    {
      Exit 1
    }
  }
}

#Fetch all members from selecte source group
$member = Get-ADGroupMember -Identity $SourceGroup.Name -Server $dc[0]
if ($null -eq $member)
{
  $msgBoxInput = [System.Windows.MessageBox]::Show("Error getting members of $SourceGroupName, exiting...","Error","OK","Error")
  switch  ($msgBoxInput)
  {
    "OK"
    {
      Exit 1
    }
  }
}

foreach ($DestinationGroup in $DestinationGroups)
{
  if ($SourceGroup -eq $DestinationGroup)
  {
    #Write-Host "SOURCE AD Group also selected as DESTINATION, skipping..." -ForegroundColor Red
    Continue
  }

  #Try to populate the selected destination group with members
  Try
  {
    Add-ADGroupMember -Identity $DestinationGroup.name -Members $member -Server $dc[0]
    $message = "Members of AD Group " + $SourceGroup.name + " have been copied to AD Group " + $DestinationGroup.Name
    $msgBoxInput = [System.Windows.MessageBox]::Show($message,"Finished","OK","Asterisk")
    switch  ($msgBoxInput)
    {
      "OK"
      {
        Exit 1
      }
    }
  }
  Catch
  {
    $msgBoxInput = [System.Windows.MessageBox]::Show("AD Group membership copy failed","Error","OK","Error")
    switch  ($msgBoxInput)
    {
      "OK"
      {
        Exit 1
      }
    }
  }
}
