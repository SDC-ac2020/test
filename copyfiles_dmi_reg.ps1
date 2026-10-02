#VA
 
# This is the file that contains the list of computers you want 
# to copy the folder and files to. Change this path IAW your folder structure.
$computers = gc "c:\scripts\3079a.csv"
 
# This is the directory you want to copy to the computer (IE. c:\folder_to_be_copied)
$source = "C:\scripts\dmi\dmi_edit.reg"
 
# On the desination computer, where do you want the folder to be copied?
$dest = "c$\dmi"
 
foreach ($computer in $computers) {
    if (test-Connection -Cn $computer -quiet) {
        Copy-Item $source -Destination \\$computer\$dest -Recurse -Force
    } else {
        "$computer is not online"
    }
 
}