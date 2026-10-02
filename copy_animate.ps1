#
 
# This is the file that contains the list of computers you want 
# to copy the folder and files to. Change this path IAW your folder structure.
$computers = gc "D:\scripts\3043.csv"
 
# This is the directory you want to copy to the computer (IE. c:\folder_to_be_copied)
$source = "D:\scripts\Adobe Animate 2024\"
 
# On the desination computer, where do you want the folder to be copied?
$dest = "c$\Program Files\Adobe\\Adobe Animate 2024"
 
foreach ($computer in $computers) {
    if (test-Connection -Computername $computer -quiet) {
        Copy-Item $source -Destination \\$computer\$dest -Recurse
    } else {
        "$computer is not online"
    }
 
}