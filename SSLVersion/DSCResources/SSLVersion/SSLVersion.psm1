## And here my troubles began


function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("SSLv2","SSLv3","TLSv10","TLSv11","TLSv12")]
		[System.String]
		$SSLVersion,

		[parameter(Mandatory = $true)]
        [ValidateSet("Client","Server","Both")]
		[System.String]
		$SSLUse
	)

    $reg_base = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\' ;
    $Version_Mapping=@{
        "SSLv2"   = "SSL 2.0" ;
        "SSLv3"   = "SSL 3.0" ;
        "TLSv10"  = "TLS 1.0" ;
        "TLSv11"  = "TLS 1.1" ;
        "TLSv12"  = "TLS 1.2" ;
    } ;
    $reg_c = $reg_base+$Version_Mapping.{$SSLVersion}+'\Server' ;
    $reg_s = $reg_base+$Version_Mapping.{$SSLVersion}+'\Client' ;

    $c_disabled = 0 ;
    $s_disabled = 0 ;
    $c_enabled  = 0 ;
    $s_enabled  = 0 ;
    $error_msg  = '' ;
    $Ensure     = '' ;

    if($SSLUse -eq 'Client') {
        if(Test-Path -Path $reg_c) {
            if((Get-ItemProperty -Path $reg_c -Name 'DisabledByDefault') -eq 1) {
                ++$c_disabled ;
            } elsif((Get-ItemProperty -Path $reg_c -Name 'DisabledByDefault') -eq 0) {
                ++$c_enabled ;
            }

            if((Get-ItemProperty -Path $reg_c -Name 'Enabled') -eq 0) {
                ++$c_disabled ;
            }  elsif((Get-ItemProperty -Path $reg_c -Name 'Enabled') -eq 1) {
                ++$c_enabled ;
            }
        } else {
                $error_msg=$error_msg+"Please create "+$reg_c+"`r`n" ;
        }
        if($c_disabled -eq 2 -and $c_enabled -eq 0) {
            $Ensure = "Disabled" ;
        } elsif($c_disabled -eq 0 -and $c_enabled -eq 2) {
            $Ensure = "Enabled" ;
        } else {
            $Ensure = "Unknown" ;
        }
        if($error_msg -isnot '') {
            Write-Error($error_msg) ;
        } 
        $returnValue = @{
            "SSLVersion" = $SSLVersion ;
            "SSLUse"     = $SSLUse ;
            "Ensure"     = $Ensure ;
        } ;
        $returnValue ;
    } elsif($SSLUse -eq 'Server') {
        if(Test-Path -Path $reg_s) {
            if((Get-ItemProperty -Path $reg_s -Name 'DisabledByDefault') -eq 1) {
                ++$s_disabled ;
            } elsif((Get-ItemProperty -Path $reg_s -Name 'DisabledByDefault') -eq 0) {
                ++$s_enabled ;
            }

            if((Get-ItemProperty -Path $reg_s -Name 'Enabled') -eq 0) {
                ++$s_disabled ;
            }  elsif((Get-ItemProperty -Path $reg_s -Name 'Enabled') -eq 1) {
                ++$s_enabled ;
            }
        } else {
                $error_msg=$error_msg+"Please create "+$reg_s+"`r`n" ;
        }
        if($s_disabled -eq 2 -and $s_enabled -eq 0) {
            $Ensure = "Disabled" ;
        } elsif($s_disabled -eq 0 -and $s_enabled -eq 2) {
            $Ensure = "Enabled" ;
        } else {
            $Ensure = "Unknown" ;
        }
        if($error_msg -isnot '') {
            Write-Error($error_msg) ;
        } 
        $returnValue = @{
            "SSLVersion" = $SSLVersion ;
            "SSLUse"     = $SSLUse ;
            "Ensure"     = $Ensure ;
        } ;
        $returnValue ;
    } elsif($SSLUse -eq 'Both') {
        Get-TargetResource($SSLVersion,'Client') ;
        Get-TargetResource($SSLVersion,'Server') ;
    } else {
        Write-Error "Invalid SSL Use. Appropriate values are 'Client', 'Server' or 'Both'" ;
    }

}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("SSLv2","SSLv3","TLSv10","TLSv11","TLSv12")]
		[System.String]
		$SSLVersion,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$Ensure,

		[ValidateSet("Client","Server","Both")]
		[System.String]
		$SSLUse
	)

    $PreStatus = Get-TargetResource($SSLVersion,$SSLUse) ;

    $reg_base = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\' ;
    $Version_Mapping=@{
        "SSLv2"   = "SSL 2.0" ;
        "SSLv3"   = "SSL 3.0" ;
        "TLSv10"  = "TLS 1.0" ;
        "TLSv11"  = "TLS 1.1" ;
        "TLSv12"  = "TLS 1.2" ;
    } ;
    $reg_c = $reg_base+$Version_Mapping.{$SSLVersion}+'\Server' ;
    $reg_s = $reg_base+$Version_Mapping.{$SSLVersion}+'\Client' ;

    if($SSLUse -eq 'Client') {
        if(!(Test-Path -Path $reg_c)) {
            New-Item $reg_c -Force | Out-Null ; 
        } 
        if(!(Test-TargetResource($SSLVersion,$Ensure,$SSLUse))) {
            if($Ensure -eq 'Enabled') {
                Write-Debug 'Setting '+$reg_c+'\Enabled to DWord:1'
                New-ItemProperty -path $reg_c -name 'Enabled' -value 1 -PropertyType 'DWord' -Force | Out-Null ;
                Write-Debug 'Setting '+$reg_c+'\DisabledByDefault to DWord:0'
                New-ItemProperty -path $reg_c -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null ;
            } elsif($Ensure -eq 'Disabled') {
                Write-Debug 'Setting '+$reg_c+'\Enabled to DWord:0'
                New-ItemProperty -path $reg_c -name 'Enabled' -value 0 -PropertyType 'DWord' -Force | Out-Null ;
                Write-Debug 'Setting '+$reg_c+'\DisabledByDefault to DWord:1'
                New-ItemProperty -path $reg_c -name 'DisabledByDefault' -value 1 -PropertyType 'DWord' -Force | Out-Null ;
            }
        }
    } elsif($SSLUse -eq 'Server') {
        if(!(Test-Path -Path $reg_s)) {
            New-Item $reg_s -Force | Out-Null ; 
        } 
        if(!(Test-TargetResource($SSLVersion,$Ensure,$SSLUse))) {
            if($Ensure -eq 'Enabled') {
                Write-Debug 'Setting '+$reg_s+'\Enabled to DWord:1'
                New-ItemProperty -path $reg_s -name 'Enabled' -value 1 -PropertyType 'DWord' -Force | Out-Null ;
                Write-Debug 'Setting '+$reg_s+'\DisabledByDefault to DWord:0'
                New-ItemProperty -path $reg_s -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null ;
            } elsif($Ensure -eq 'Disabled') {
                Write-Debug 'Setting '+$reg_s+'\Enabled to DWord:0'
                New-ItemProperty -path $reg_s -name 'Enabled' -value 0 -PropertyType 'DWord' -Force | Out-Null ;
                Write-Debug 'Setting '+$reg_s+'\DisabledByDefault to DWord:1'
                New-ItemProperty -path $reg_s -name 'DisabledByDefault' -value 1 -PropertyType 'DWord' -Force | Out-Null ;
            }
        }
    } elsif($SSLUse -eq 'Both') {
        ## Create keys
        if(!(Test-Path -Path $reg_c)) {
            New-Item $reg_c -Force | Out-Null ; 
        } 
        if(!(Test-Path -Path $reg_s)) {
            New-Item $reg_s -Force | Out-Null ; 
        } 


        ## Create or overwrite mismatched keys
        if($Ensure -eq 'Enabled') {
            Write-Debug 'Setting '+$reg_c+'\Enabled to DWord:1'
            New-ItemProperty -path $reg_c -name 'Enabled' -value 1 -PropertyType 'DWord' -Force | Out-Null ;
            Write-Debug 'Setting '+$reg_c+'\DisabledByDefault to DWord:0'
            New-ItemProperty -path $reg_c -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null ;
            Write-Debug 'Setting '+$reg_s+'\Enabled to DWord:1'
            New-ItemProperty -path $reg_s -name 'Enabled' -value 1 -PropertyType 'DWord' -Force | Out-Null ;
            Write-Debug 'Setting '+$reg_s+'\DisabledByDefault to DWord:0'
            New-ItemProperty -path $reg_s -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null ;
        } elsif($Ensure -eq 'Disabled') {
            Write-Debug 'Setting '+$reg_c+'\Enabled to DWord:0'
            New-ItemProperty -path $reg_c -name 'Enabled' -value 0 -PropertyType 'DWord' -Force | Out-Null ;
            Write-Debug 'Setting '+$reg_c+'\DisabledByDefault to DWord:1'
            New-ItemProperty -path $reg_c -name 'DisabledByDefault' -value 1 -PropertyType 'DWord' -Force | Out-Null ;
            Write-Debug 'Setting '+$reg_s+'\Enabled to DWord:0'
            New-ItemProperty -path $reg_s -name 'Enabled' -value 0 -PropertyType 'DWord' -Force | Out-Null ;
            Write-Debug 'Setting '+$reg_s+'\DisabledByDefault to DWord:1'
            New-ItemProperty -path $reg_s -name 'DisabledByDefault' -value 1 -PropertyType 'DWord' -Force | Out-Null ;
        }
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("SSLv2","SSLv3","TLSv10","TLSv11","TLSv12")]
		[System.String]
		$SSLVersion,

		[ValidateSet("Enabled","Disabled")]
		[System.String]
		$Ensure,

		[ValidateSet("Client","Server","Both")]
		[System.String]
		$SSLUse
	)

    if($SSLUse -eq 'Client' -or $SSLUse -eq 'Server') {
        return(Get-TargetResource($SSLVersion,$SSLUse).{"Ensure"} -eq $Ensure) ;
    }


}


Export-ModuleMember -Function *-TargetResource

