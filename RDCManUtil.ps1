# RDCManUtil.ps1
# By: Thechillman
#
# This is my first stab at Powershell.  It took a lot of googling.  Probably not the most
#  elegant code, but it works :)
# 
# This script is provided "As Is".  Use at your own risk.
#
# The Remote Desktop Connection Manager encrypts the saved password in the *.rdg files.
#  Even if you move the rdg files to another computer, the saved password will not work
#  because the passwords are encrypted with the user profile on the current computer.
#  You will need to retype all of the passwords after you copy the rdg files to a new
#  computer.
#  
# This ps1 utility will assist you in moving/copying your rdg files to a new computer
#  and restore the passwords.  It will decrypt the password in the rdg file and save them
#  into a new rdg.dec file.  You have the option to display the decrypted password in the
#  console during the encryption/decryption process by setting $bDisplayPassword to $true.
# 
# To move or copy the rdg files to another computer;
#   - Set $directoryPath to your RDC Manager Sites Folder on the current computer.
#   - Run this Powershell Script.  A copy of the rdg file will be created with *.rdg.dec
#   - The encrypted password, in the *.rdg.dec file, is replaced with the decrypted
#      passwords.  Keep these files secured.
#
#   - Move the *.rdg.dec files to the RDC Manager Sites Folder of the new computer.
#   - Copy this ps1 script to the new computer.
#   - Set $directoryPath to the RDC Manager Sites Folder of the new computer.
#   - Make sure the RDC Manager Sites Folder of the new computer does not contain any
#      *.rdg files. If *.rdg files exist, it will go into the decrypt mode instead of the
#      encrypt mode, and it will create new *.rdg.dec files instead of *.rdg files.
#   - Run this Powershell Script.  A copy of the *.rdg.dec file will be created with *.rdg
#      with the newly encrypted passwords.
#
# Now, when you launch RDCMan.exe, you should not get any password errors, and should be
#  able to RDP into the servers without having to respecify passwords.
#
# After you're all done, make sure to delete all copies of the *.rdg.dec files because it
#  contains the decrypted passwords.
#


# ========================== CONFIG ME ============================

$directoryPath = "C:\Users\johndoe\Desktop\RDC Manager\Sites"

# =================================================================

$bDisplayPassword = $false # Displays the decrypted password in the console screen



Function ProcessRDCMPass {
    # Initialize defaults for encrypting or decrypting based on the presence of the rdg files
    $fileFilter = "*.rdg"
    $files = Get-ChildItem -Path $directoryPath -Filter $fileFilter -File

    if ($files.Length -gt 0) {
        # Decrypt rdg files
        $bEncrypt = $false
    } else {
        # Encrypt rdg files
        $bEncrypt = $true
        $fileFilter = "*.dec"
        $files = Get-ChildItem -Path $directoryPath -Filter $fileFilter -File
    }

    
    foreach ($file in $files) {
        [Environment]::NewLine
        Write-Host "Opening file: $($file.Name)"
        
        $fileIn = $directoryPath + "\\" + $file
        
        # Set the output file name according to the process
        if ($bEncrypt) {
            $fileOut = $fileIn -replace ".dec", ""
        } else {
            $fileOut=$directoryPath + "\\"+$file + ".dec"
        }
        
        # Read in the contents of the input file
        $lines = Get-Content -Path $fileIn -Encoding utf8
        
        # Create the new output file
        Out-File -FilePath $fileOut -Encoding utf8
        # For each line in the file, look for <password> to obtain the encrypted/decrypted password
        foreach ($line in $lines) {
            # Process each line here
            # If the password is blank, set the tag properly so not to cause error down the line
            $line = $line.Replace("<password></password>", "<password />")
            # Displays the Server name
            if ($line.IndexOf("<displayName>") -ge 0) {
                $sDisplayName = $line -replace "<displayName>", "" -replace "</displayName>", "" -replace " ", "" 
                Write-Host "`r`n    Processing:" $sDisplayName
            }
            # If the server name is not found, display the name
            if ($line.IndexOf("<name>") -ge 8 -and $sDisplayName -eq "") {
                $sName = $line -replace "<name>", "" -replace "</name>", "" -replace " ", "" 
                Write-Host "`r`n    Processing:" $sName
            }
            # Display the user name
            if ($line.IndexOf("<userName>") -ge 0) {
                $sUserName = $line -replace "<userName>", "" -replace "</userName>", "" -replace " ", "" 
                Write-Host "     User Name:" $sUserName
            }
            
            # Looking for the password
            $iStart = $line.IndexOf("<password>")
            $iEnd = $line.IndexOf("</password>")
            if ($iStart -ge 0 -and $iEnd -ge 0) {
                # Password is found.
                $sRDCMPass = $line.Substring($iStart + 10, $iEnd - $iStart - 10)
                # Encrypt/Decrypt the password
                try {
                    if ($bEncrypt) {
                        $crypted = EncryptPassword($sRDCMPass)
                    } else {
                        $crypted = DecryptPassword($sRDCMPass)
                    }
                    # Replace the decrypted password with the encrypted password and vice versa
                    $line = $line.Replace($sRDCMPass, $crypted)
                    # Output the decrypted password to console if $bDisplayPassword is set to $true
                    if ($bDisplayPassword) {
                        if ($bEncrypt) {
                            Write-Host "      Password:"$sRDCMPass
                        } else {
                            Write-Host "      Password:"$crypted
                        }
                    }
                    if ($bEncrypt){
                        Write-Host "        Status: Encrypted"
                    } else {
                        Write-Host "        Status: Decrypted"
                    }
                } catch {
                    $crypted = ""
                    Write-Host "     !!! Error !!!"
                }
                $sDisplayName = ""
            }
            
            # Write the data back out to the *.rdg.dec file
            $line | Out-File -FilePath $fileOut -Append -Encoding utf8
        }
    }
}



# Credits: The EncryptPassword and DecryptPassword was found on github, from peterneave
#  EncryptDecryptRDCMan.ps1
#  
# There is no facility to replace passwords in RDCMan once they are stored. The only way is to create a new custom credential.
# If you open your *.rdg file in a text editor, locate the stored <password>, you can then decrypt it using this script.
# This script can also encrypt a plain text password in rdg format which can be used to overwrite an existing one in the xml.
Add-Type -AssemblyName System.Security;

Function EncryptPassword {
    [CmdletBinding()]
    param([String]$PlainText = $null)

    # convert to RDCMan format: (null terminated chars)
    $withPadding = @()
    foreach($char in $PlainText.ToCharArray()) {
        $withPadding += [int]$char
        $withPadding += 0
    }

    # encrypt with DPAPI (current user)
    $encrypted = [Security.Cryptography.ProtectedData]::Protect($withPadding, $null, 'CurrentUser')
    return $base64 = [Convert]::ToBase64String($encrypted)
}

Function DecryptPassword {
    [CmdletBinding()]
    param([String]$EncodedPasswordString = $null)
    
    $decoded = [Convert]::FromBase64String($EncodedPasswordString)
    $decryptedBytes = [Security.Cryptography.ProtectedData]::Unprotect($decoded, $null, 'CurrentUser')
    $decryptedString = [Text.Encoding]::ASCII.GetString($decryptedBytes)
    
    # trim null terminating chars from padding (does not account for pwds with spaces in them)
    $sb = [System.Text.StringBuilder]::new()
    foreach($char in $decryptedString.ToCharArray()) {
        if($char -ne 0) {
            $sb.Append($char) > $null
        }
    }
    return $sb.ToString()
}




cls
ProcessRDCMPass

