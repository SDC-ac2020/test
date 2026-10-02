#
 
# This is the file that contains the list of computers you want 
# to copy the folder and files to. Change this path IAW your folder structure.
$computers = gc "D:\scripts\htf14.csv"
 
# This is the directory you want to copy to the computer (IE. c:\folder_to_be_copied)
$source = "D:\scripts\computing\*.*"
 
# On the desination computer, where do you want the folder to be copied?
$dest = "c$\programdata\shared desktop\"
 
foreach ($computer in $computers) {
    if (test-Connection -Computername $computer -quiet) {
        Copy-Item $source -Destination \\$computer\$dest -Recurse
    } else {
        "$computer is not online"
    }
 
}