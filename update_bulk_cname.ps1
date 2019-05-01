# Update CNAME record with an input file (c:\temp\cname.txt)
# 08-04-2019 Initial version

# Input file format
# abc.dev.cft.liz.com   93Jd24v.x.incapdns.net  abc.dev.cft   liz.com


Get-Content "c:\temp\cname.txt" | ForEach-Object {
    $data = $_-split('\t')
    $cname="{0}" -f $data[1]
    $dnsname="{0}" -f $data[2]
    $dnszone="{0}" -f $data[3]
    $dnstype = "cname"
    $username = "audomain\automation_user"
    $password = ConvertTo-SecureSting "Secret" -AsPlainText -Force
    $dnsserver = "dnsservername"
    $cred = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $password

    Write-Host "Name is $dnsname, CNAME is $cname and Zonename is $dnszone"

    Try
    {
	Write-Host Current DNS record:
	Invoke-Command -ComputerName $dnsserver -credential $cred -ArgumentList $dnsname,$dnszone -ScriptBlock {(Get-DnsServerResourceRecord -Name "$using:dnsname" -ZoneName "using:dnszone").RecordData.HostNameAlias}
    }
    Catch
    {
	$Exception = $_.exception.Message
	Write-Warning "Current DNS alias record cannot be found. Following error occurred: $Exception"
    }

    Try
    {
	Invoke-Command -ComputerName $dnsserver -credential $cred -ArgumentList $dnsname,$dnszone -ScriptBlock {(Remove-DnsServerResourceRecord -Name "$using:dnsname" -ZoneName "using:dnszone" --RRType CName -Force)}
	Write-Host Old alias $dnsname has been removed
    }
    Catch
    {
	$Exception = $_.exception.Message
	Write-Warning "Change of DNS alias failed. Following error occurred: $Exception"
    }
	
    Try
    {
	Invoke-Command -ComputerName $dnsserver -credential $cred -ArgumentList $dnsname,$cname,$dnszone -ScriptBlock {(Add-DnsServerResourceRecordCName -Name "$using:dnsname" -HostNameAlias "using:cname" -Zonename "using:dnszone" -Computername "$using:dnsserver")}
	Write-Host $dnsname alias $cname has been created
    }
    Catch
    {
	$Exception = $_.exception.Message
	Write-Warning "Add DNS CNAME failed. Following error occurred: $Exception"
    }


    Try
    {
	Write-Host Current DNS record:
	Invoke-Command -ComputerName $dnsserver -credential $cred -ArgumentList $dnsname,$dnszone -ScriptBlock {(Get-DnsServerResourceRecord -Name "$using:dnsname" -ZoneName "using:dnszone").RecordData.HostNameAlias}
    }
    Catch
    {
	$Exception = $_.exception.Message
	Write-Warning "Current DNS alias record cannot be found. Following error occurred: $Exception"
    }
}
