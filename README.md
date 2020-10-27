Powershell script to set remote powershell session with Azure VMs
=================================================================

            

In Azure Microsoft has a large list of VM templates that can be used in the Gallery to provision VMs. These VMs come with few pre-configured features to facilitate secure powershell remoting into the VMs:


- WinRM is enabled and configured to listen on HTTPS port 5986


- A certificate is already created to enable authentication from remote on-premises computers that do not belong to the same AD domain as the target Azure VM.


This PS script takes advantage of these settings and establishes PS session with Azure VM. Once the session is established, you can issue PS commands as shown in the examples


 

[ For more information see this link.](https://superwidgets.wordpress.com/2016/02/15/managing-azure-vms-using-powershell-from-your-local-desktop/)

        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
