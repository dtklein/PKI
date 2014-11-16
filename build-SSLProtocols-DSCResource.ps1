$Ensure = New-xDscResourceProperty -Name 'Ensure' -Type 'String' -Attribute Write -ValidateSet "Enabled","Disabled" -Description "Ensure specified protocol is enabled or disabled" ;
$SSLVersion = New-xDscResourceProperty -Name 'SSLVersion' -Type 'String' -Attribute Key -ValidateSet "SSLv2","SSLv3","TLSv10","TLSv11","TLSv12" -Description "Specify the version of the SSL/TLS protocol that will be subject to policy" ;
$SSLUse = New-xDscResourceProperty -Name 'SSLUse' -Type 'String' -Attribute Write -ValidateSet "Client","Server","Both" -Description "Specify whether the policy applies to use of the protocol as a client, as a server or in both roles" ;

New-xDscResource -Name SSLVersion -Property $SSLVersion, $Ensure, $SSLUse -Path 'C:\Users\David\code\ciphers.DSC' -ModuleName "SSLVersion" 