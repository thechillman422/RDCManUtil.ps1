RDCManUtil.ps1
 By: Thechillman

 This is my first stab at Powershell.  It took a lot of googling.  Probably not the most
  elegant code, but it works :)
 
 This script is provided "As Is".  Use at your own risk.

 The Remote Desktop Connection Manager encrypts the saved password in the *.rdg files.
  Even if you move the rdg files to another computer, the saved password will not work
  because the passwords are encrypted with the user profile on the current computer.
  You will need to retype all of the passwords after you copy the rdg files to a new
  computer.
  
 This ps1 utility will assist you in moving/copying your rdg files to a new computer
  and restore the passwords.  It will decrypt the password in the rdg file and save them
  into a new rdg.dec file.  You have the option to display the decrypted password in the
  console during the encryption/decryption process by setting $bDisplayPassword to $true.
 
 To move or copy the rdg files to another computer;
   - Set $directoryPath to your RDC Manager Sites Folder on the current computer.
   - Run this Powershell Script.  A copy of the rdg file will be created with *.rdg.dec
   - The encrypted password, in the *.rdg.dec file, is replaced with the decrypted
      passwords.  Keep these files secured.

   - Move the *.rdg.dec files to the RDC Manager Sites Folder of the new computer.
   - Set $directoryPath to the RDC Manager Sites Folder of the new computer.
   - Make sure the RDC Manager Sites Folder of the new computer does not contain any
      *.rdg files. If *.rdg files exist, it will go into the decrypt mode instead of the
      encrypt mode, and it will create new *.rdg.dec files instead of *.rdg files.
   - Run this Powershell Script.  A copy of the *.rdg.dec file will be created with *.rdg
      with the newly encrypted passwords.

 Now, when you launch RDCMan.exe, you should not get any password errors, and should be
  able to RDP into the servers without having to respecify passwords.

 After you're all done, make sure to delete all copies of the *.rdg.dec files because it
  contains the decrypted passwords.
