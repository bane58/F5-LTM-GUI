###############
#By Tony Unger
#Version 0.99
#
###############
#
#This uses https://www.powershellgallery.com/packages/f5-ltm
########
#Issues:
#Token will expire after 20 mins. Need to figure out how to renew(patch) properly 
#Need to make GenerateForm into an advanced function to populate F5 load balancers
#Alert if not active f5
#Need to populate $F5Managment with f5 you wish to manage.

#Generated Form Function
function GenerateForm
{

  #Region Variables
  $F5Managment = 'ftdevice'

  #enable debug messages
  $Debug = $true

  #Enable changing pool member enable/disable state
  $ConditionChange = $true
  #endregion

  #region Import the Assemblies
  [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
  [reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
  #endregion


    #----------------------------------------------
  #region Generated Form Code
  $frmF5 = New-Object System.Windows.Forms.Form
  $lvPools = New-Object System.Windows.Forms.ListView
  $sBStatus = New-Object System.Windows.Forms.StatusBar
  $gbHeader = New-Object System.Windows.Forms.GroupBox
  $cmdConnect = New-Object System.Windows.Forms.Button
  $lblF5 = New-Object System.Windows.Forms.Label
  $lblUsername = New-Object System.Windows.Forms.Label
  $txtUsername = New-Object System.Windows.Forms.TextBox
  $cbF5 = New-Object System.Windows.Forms.ComboBox
  $lblPassword = New-Object System.Windows.Forms.Label
  $txtPassword = New-Object System.Windows.Forms.TextBox
  $gbControls = New-Object System.Windows.Forms.GroupBox
  $cmdExit = New-Object System.Windows.Forms.Button
  $cmdDisable = New-Object System.Windows.Forms.Button
  $cmdEnable = New-Object System.Windows.Forms.Button
  $lvPoolMembers = New-Object System.Windows.Forms.ListView
  $Member = New-Object System.Windows.Forms.ColumnHeader
  $Status = New-Object System.Windows.Forms.ColumnHeader
  $Count = New-Object System.Windows.Forms.ColumnHeader
  $Pool = New-Object System.Windows.Forms.ColumnHeader
  $Partition = New-Object System.Windows.Forms.ColumnHeader
  $State = New-Object System.Windows.Forms.ColumnHeader
  $sbpFtStatus = New-Object System.Windows.Forms.StatusBarPanel
  $sbpFtServer = New-Object System.Windows.Forms.StatusBarPanel
  $InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
  $lbLoading = New-Object System.Windows.Forms.Label 
  #endregion Generated Form Objects
  #----------------------------------------------
  #Generated Event Script Blocks
  #----------------------------------------------

  $cmdConnect_OnClick =
  {
    #Creates Session to f5 - change to function
    #Remove-Variable * -ErrorAction SilentlyContinue

    $f5LTMName = $cbF5.Text
    $User = $txtUsername.Text
    $Password = $txtPassword.Text

    #install-module "f5-ltm" - requires the f5-ltm module. may have to include function in this script to make it easier 
    $secpasswd = ConvertTo-SecureString $Password -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential "$User",$secpasswd


    if ($debug -eq $true)
    {
      Write-Host "Connection to " $cbF5.Text
      New-F5Session -LTMName $f5LTMName -LTMCredentials $mycreds -Verbose -TokenLifespan 1140
    }
    else
    {
      New-F5Session -LTMName $f5LTMName -LTMCredentials $mycreds -TokenLifespan 1140
    }

    Update-StatusBarPanel 
    
    #Load Pools
    $pools = Get-Pool
    Add-ItemToListViewPools $pools
    Update-Form

  }

  $cmdExit_OnClick =
  {

    $frmF5.Close()
  }

  $cmdDisable_OnClick =
  {

    if ($Debug -eq $True)
    {
      Write-Host "Disable Click"
    }

    #can't figure out null index fix
    try
    {
      $SelectedPool = $lvpools.selecteditems.Text
      $SelectedPoolPartition = $lvpools.selecteditems.SubItems[1].Text
    }
    catch {}



    foreach ($item in $lvPoolMembers.CheckedItems)
    {
      $Member = $item.SubItems[0].Text
      $status = $item.SubItems[1].Text

      if ($status -notlike "*Disable*")
      {
        Write-Host "Disabling $Member on Partition $SelectedPoolPartition on $SelectedPool"
        if ($ConditionChange -eq $true)
        {
          Write-Host "Disable True"
          Disable-PoolMember -Name $member -Partition $SelectedPoolPartition -PoolName $SelectedPool
        }
      }
      else
      {
        Write-Host "$Member already has a status of $status"
      }


    }




    Update-LVPoolMembers -SelectedPoolPartition $SelectedPoolPartition -SelectedPool $SelectedPool
    Update-Form

  }


  $cbF5_SelectedIndexChanged = {
    #TODO: Place custom script here
    if ($Debug -eq $True)
    {
      Write-Host "f5ComboIndexChange"
    }

    Update-StatusBarPanel
    Update-Form
  }

  $lvPools_ItemSelectionChanged = {

    #can't figure out null index fix event runs twice for some reason.
    try
    {
      $SelectedPool = $lvpools.selecteditems.Text
      $SelectedPoolPartition = $lvpools.selecteditems.SubItems[1].Text
    }
    catch
    {
    }

    $lvPools.Enabled = $False
    $lbLoading.Visible = $true

    if ($Debug -eq $true)
    {
      Write-Host "lvPools Index Change"
    }

    Update-LVPoolMembers -SelectedPoolPartition $SelectedPoolPartition -SelectedPool $SelectedPool
    Update-Form
    $lbLoading.Visible = $false
    $lvPools.Enabled = $true
  }


  $cmdEnable_OnClick =
  {
    #TODO : Add code to Enable checked pool members
    if ($Debug -eq $True)
    {
      Write-Host "Enable"
    }
    #can't figure out null index fix
    try
    {
      $SelectedPool = $lvpools.selecteditems.Text
      $SelectedPoolPartition = $lvpools.selecteditems.SubItems[1].Text
    }
    catch {}

    Write-Host $lvPoolMembers.CheckedItems

    foreach ($item in $lvPoolMembers.CheckedItems)
    {
      $Member = $item.SubItems[0].Text
      $status = $item.SubItems[1].Text

      if ($status -notlike "*Enable*")
      {
        Write-Host "Enabling $Member on Partition $SelectedPoolPartition on $SelectedPool"
        if ($ConditionChange -eq $true)
        {
          Write-Host "Enable True"
          Enable-PoolMember -Name $member -Partition $SelectedPoolPartition -PoolName $SelectedPool
        }
      }
      else
      {
        Write-Host "$Member already has a status of $status"
      }
    }




    Update-LVPoolMembers -SelectedPoolPartition $SelectedPoolPartition -SelectedPool $SelectedPool
    Update-Form
  }

  
  $OnLoadForm_StateCorrection =
  { #Correct the initial state of the form to prevent the .Net maximized form issue
    $frmF5.WindowState = $InitialFormWindowState
  }

  #----------------------------------------------
  #region Generated Form Code
  $frmF5.BackColor = [System.Drawing.Color]::FromArgb(255,250,235,215)
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 793
  $System_Drawing_Size.Width = 1220
  $frmF5.ClientSize = $System_Drawing_Size
  $frmF5.DataBindings.DefaultDataSourceUpdateMode = 0
  $frmF5.Name = "frmF5"
  $frmF5.Text = "F5 Menu"


  $lvPools.Columns.Add($Pool) | Out-Null
  $lvPools.Columns.Add($Partition) | Out-Null
  $lvPools.DataBindings.DefaultDataSourceUpdateMode = 0
  $lvPools.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",14.25,0,3,1)
  $lvPools.FullRowSelect = $True
  $lvPools.GridLines = $True
  $lvPools.HeaderStyle = 1
  $lvPools.HideSelection = $False
  $lvPools.add_ItemSelectionChanged($lvPools_ItemSelectionChanged)
  $System_Windows_Forms_ListViewItem_15 = New-Object System.Windows.Forms.ListViewItem
  $System_Windows_Forms_ListViewItem_15.BackColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
  $System_Windows_Forms_ListViewItem_15.Focused = $False
  $System_Windows_Forms_ListViewItem_15.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",14.25,0,3,1)
  $System_Windows_Forms_ListViewItem_15.ForeColor = [System.Drawing.Color]::FromArgb(255,0,0,0)
  $System_Windows_Forms_ListViewItem_15.Name = ""
  $System_Windows_Forms_ListViewItem_15.Selected = $False
  $System_Windows_Forms_ListViewItem_15.Text = ""

  $lvPools.Items.Add($System_Windows_Forms_ListViewItem_15) | Out-Null
  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 12
  $System_Drawing_Point.Y = 101
  $lvPools.Location = $System_Drawing_Point
  $lvPools.Name = "lvPools"
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 632
  $System_Drawing_Size.Width = 425
  $lvPools.Size = $System_Drawing_Size
  $lvPools.Sorting = 1
  $lvPools.TabIndex = 14
  $lvPools.UseCompatibleStateImageBehavior = $False
  $lvPools.View = 1

  $frmF5.Controls.Add($lvPools)

  $cbF5.DataBindings.DefaultDataSourceUpdateMode = 0
  $cbF5.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",12,0,3,0)
  $cbF5.FormattingEnabled = $True
  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 130
  $System_Drawing_Point.Y = 20
  $cbF5.Location = $System_Drawing_Point
  $cbF5.Name = "cbF5"
  $cbf5.add_SelectedIndexChanged($cbF5_SelectedIndexChanged)
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 28
  $System_Drawing_Size.Width = 167
  $cbF5.Size = $System_Drawing_Size
  $cbF5.TabIndex = 5
  $cbF5.Text = $F5Managment[0]

  #Add all f5 from $f5management variable
  $F5Managment | ForEach-Object { $cbF5.Items.Add($_) | Out-Null }

  $gbHeader.Controls.Add($cbF5)

  $lbLoading.BackColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
  $lbLoading.DataBindings.DefaultDataSourceUpdateMode = 0
  $lbLoading.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",14.25,1,3,0)

  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 450
  $System_Drawing_Point.Y = 135
  $lbLoading.Location = $System_Drawing_Point
  $lbLoading.Name = "lbLoading"
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 595
  $System_Drawing_Size.Width = 575
  $lbLoading.Size = $System_Drawing_Size
  $lbLoading.TabIndex = 15
  $lbLoading.Text = "Loading..."
  $lbLoading.TextAlign = 32
  $lbLoading.Visible = $False

  $frmF5.Controls.Add($lbLoading)

  $sBStatus.DataBindings.DefaultDataSourceUpdateMode = 0
  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 0
  $System_Drawing_Point.Y = 771
  $sBStatus.Location = $System_Drawing_Point
  $sBStatus.Name = "sBStatus"
  $sBStatus.Panels.Add($sbpFtServer)|Out-Null
  $sBStatus.Panels.Add($sbpFtStatus)|Out-Null
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 22
  $System_Drawing_Size.Width = 1220
  $sBStatus.Size = $System_Drawing_Size
  $sBStatus.TabIndex = 13
  $sbStatus.ShowPanels = $True
  $frmF5.Controls.Add($sBStatus)


  $gbHeader.DataBindings.DefaultDataSourceUpdateMode = 0
  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 12
  $System_Drawing_Point.Y = 10
  $gbHeader.Location = $System_Drawing_Point
  $gbHeader.Name = "gbHeader"
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 64
  $System_Drawing_Size.Width = 1141
  $gbHeader.Size = $System_Drawing_Size
  $gbHeader.TabIndex = 12
  $gbHeader.TabStop = $False

  $frmF5.Controls.Add($gbHeader)
  $cmdConnect.BackColor = [System.Drawing.Color]::FromArgb(255,220,220,220)

  $cmdConnect.DataBindings.DefaultDataSourceUpdateMode = 0
  $cmdConnect.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",12,0,3,1)

  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 1035
  $System_Drawing_Point.Y = 12
  $cmdConnect.Location = $System_Drawing_Point
  $cmdConnect.Name = "cmdConnect"
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 42
  $System_Drawing_Size.Width = 88
  $cmdConnect.Size = $System_Drawing_Size
  $cmdConnect.TabIndex = 12
  $cmdConnect.Text = "Connect"
  $cmdConnect.UseVisualStyleBackColor = $False
  $cmdConnect.add_Click($cmdConnect_OnClick)

  $gbHeader.Controls.Add($cmdConnect)

  $lblF5.DataBindings.DefaultDataSourceUpdateMode = 0
  $lblF5.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",12,0,3,1)

  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 6
  $System_Drawing_Point.Y = 23
  $lblF5.Location = $System_Drawing_Point
  $lblF5.Name = "lblF5"
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 23
  $System_Drawing_Size.Width = 118
  $lblF5.Size = $System_Drawing_Size
  $lblF5.TabIndex = 11
  $lblF5.Text = "F5 Hostname:"

  $gbHeader.Controls.Add($lblF5)

  $lblUsername.DataBindings.DefaultDataSourceUpdateMode = 0
  $lblUsername.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",12,0,3,1)

  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 303
  $System_Drawing_Point.Y = 20
  $lblUsername.Location = $System_Drawing_Point
  $lblUsername.Name = "lblUsername"
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 23
  $System_Drawing_Size.Width = 93
  $lblUsername.Size = $System_Drawing_Size
  $lblUsername.TabIndex = 8
  $lblUsername.Text = "Username:"

  $gbHeader.Controls.Add($lblUsername)

  $txtUsername.DataBindings.DefaultDataSourceUpdateMode = 0
  $txtUsername.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",12,0,3,1)
  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 402
  $System_Drawing_Point.Y = 20
  $txtUsername.Location = $System_Drawing_Point
  $txtUsername.Name = "txtUsername"
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 26
  $System_Drawing_Size.Width = 156
  $txtUsername.Size = $System_Drawing_Size
  $txtUsername.TabIndex = 6

  $gbHeader.Controls.Add($txtUsername)

  

  $lblPassword.DataBindings.DefaultDataSourceUpdateMode = 0
  $lblPassword.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",12,0,3,1)

  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 581
  $System_Drawing_Point.Y = 20
  $lblPassword.Location = $System_Drawing_Point
  $lblPassword.Name = "lblPassword"
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 23
  $System_Drawing_Size.Width = 108
  $lblPassword.Size = $System_Drawing_Size
  $lblPassword.TabIndex = 10
  $lblPassword.Text = "Password:"

  $gbHeader.Controls.Add($lblPassword)

  $txtPassword.DataBindings.DefaultDataSourceUpdateMode = 0
  $txtPassword.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",12,0,3,1)
  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 690
  $System_Drawing_Point.Y = 20
  $txtPassword.Location = $System_Drawing_Point
  $txtPassword.Name = "txtPassword"
  $txtPassword.PasswordChar = '*'
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 26
  $System_Drawing_Size.Width = 144
  $txtPassword.Size = $System_Drawing_Size
  $txtPassword.TabIndex = 9
  $txtPassword.UseSystemPasswordChar = $True

  $gbHeader.Controls.Add($txtPassword)



  $gbControls.DataBindings.DefaultDataSourceUpdateMode = 0
  $gbControls.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",12,0,3,1)
  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 1041
  $System_Drawing_Point.Y = 102
  $gbControls.Location = $System_Drawing_Point
  $gbControls.Name = "gbControls"
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 229
  $System_Drawing_Size.Width = 112
  $gbControls.Size = $System_Drawing_Size
  $gbControls.TabIndex = 11
  $gbControls.TabStop = $False
  $gbControls.Text = "Controls"

  $frmF5.Controls.Add($gbControls)
  $cmdExit.BackColor = [System.Drawing.Color]::FromArgb(255,220,220,220)

  $cmdExit.DataBindings.DefaultDataSourceUpdateMode = 0
  $cmdExit.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",12,0,3,1)

  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 6
  $System_Drawing_Point.Y = 151
  $cmdExit.Location = $System_Drawing_Point
  $cmdExit.Name = "cmdExit"
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 41
  $System_Drawing_Size.Width = 98
  $cmdExit.Size = $System_Drawing_Size
  $cmdExit.TabIndex = 4
  $cmdExit.Text = "Exit"
  $cmdExit.UseVisualStyleBackColor = $False
  $cmdExit.add_Click($cmdExit_OnClick)

  $gbControls.Controls.Add($cmdExit)

  $cmdDisable.BackColor = [System.Drawing.Color]::FromArgb(255,220,220,220)

  $cmdDisable.DataBindings.DefaultDataSourceUpdateMode = 0
  $cmdDisable.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",12,0,3,1)

  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 6
  $System_Drawing_Point.Y = 89
  $cmdDisable.Location = $System_Drawing_Point
  $cmdDisable.Name = "cmdDisable"
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 41
  $System_Drawing_Size.Width = 98
  $cmdDisable.Size = $System_Drawing_Size
  $cmdDisable.TabIndex = 3
  $cmdDisable.Text = "Disable"
  $cmdDisable.UseVisualStyleBackColor = $False
  $cmdDisable.add_Click($cmdDisable_OnClick)

  $gbControls.Controls.Add($cmdDisable)

  $cmdEnable.BackColor = [System.Drawing.Color]::FromArgb(255,220,220,220)

  $cmdEnable.DataBindings.DefaultDataSourceUpdateMode = 0
  $cmdEnable.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",12,0,3,1)

  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 6
  $System_Drawing_Point.Y = 33
  $cmdEnable.Location = $System_Drawing_Point
  $cmdEnable.Name = "cmdEnable"
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 41
  $System_Drawing_Size.Width = 98
  $cmdEnable.Size = $System_Drawing_Size
  $cmdEnable.TabIndex = 2
  $cmdEnable.Text = "Enable"
  $cmdEnable.UseVisualStyleBackColor = $False
  $cmdEnable.add_Click($cmdEnable_OnClick)

  $gbControls.Controls.Add($cmdEnable)



  $lvPoolMembers.CheckBoxes = $True

  $lvPoolMembers.Columns.Add($Member) | Out-Null
  $lvPoolMembers.Columns.Add($Status) | Out-Null
  $lvPoolMembers.Columns.Add($Count) | Out-Null
  $lvPoolMembers.Columns.Add($State) | Out-Null

  $lvPoolMembers.DataBindings.DefaultDataSourceUpdateMode = 0
  $lvPoolMembers.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",14.25,0,3,0)
  $lvPoolMembers.FullRowSelect = $True
  $lvPoolMembers.GridLines = $True
  $lvPoolMembers.HeaderStyle = 1
  $lvPoolMembers.HideSelection = $False

  $System_Drawing_Point = New-Object System.Drawing.Point
  $System_Drawing_Point.X = 445
  $System_Drawing_Point.Y = 101
  $lvPoolMembers.Location = $System_Drawing_Point
  $lvPoolMembers.Name = "lvPoolMembers"
  $System_Drawing_Size = New-Object System.Drawing.Size
  $System_Drawing_Size.Height = 633
  $System_Drawing_Size.Width = 583
  $lvPoolMembers.Size = $System_Drawing_Size
  $lvPoolMembers.Sorting = 1
  $lvPoolMembers.TabIndex = 0
  $lvPoolMembers.UseCompatibleStateImageBehavior = $False
  $lvPoolMembers.View = 1

  $frmF5.Controls.Add($lvPoolMembers)


  $Member.Name = "Member"
  $Member.Text = "Member"
  $Member.Width = 250

  $Status.Name = "Status"
  $Status.Text = "Status"
  $Status.Width = 110

  $Count.Name = "Count"
  $Count.Text = "Count"
  $Count.Width = 108

  $Pool.Name = "Pool"
  $Pool.Text = "Pool"
  $Pool.Width = 297

  $Partition.Name = "Partition"
  $Partition.Text = "Partition"
  $Partition.Width = 115

  $State.Name = "State"
  $State.Text = "State"
  $State.Width = 100

  $sbpFtServer.Name = "sbpFtServer"
  $sbpFtServer.Width = 200

  $sbpFtStatus.Name = "sbpFtStatus"
  $sbpFtStatus.Width = 200

  #endregion Generated Form Code

  #Save the initial state of the form
  $InitialFormWindowState = $frmF5.WindowState
  #Init the OnLoad event to correct the initial state of the form
  $frmF5.add_Load($OnLoadForm_StateCorrection)
  #Show the Form
  $frmf5.ShowInTaskbar = $True
  $frmF5.ShowDialog() | Out-Null

} #End Function



function Update-Form
{

  $frmF5.Refresh()
}

function Add-ItemToListViewPoolMember
{
  param($arr) $arr



  $lvPoolMembers.Items.Clear()
  try {
    foreach ($PoolMember in $PoolMembers)
    {

      $PMName = $PoolMember | Select-Object -ExpandProperty Name
      $PMSession = $PoolMember | Select-Object -ExpandProperty Session
      $PMCurrentConnections = $PoolMember | Select-Object -ExpandProperty CurrentConnections
      $PMState = $PoolMember | Select-Object -ExpandProperty State

      $PMSession = $PMSession.split("-")[1]



      $AddItemLV = New-Object System.Windows.Forms.ListViewItem
      $AddItemLV.BackColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
      $AddItemLV.Focused = $False

      if ($PMSession -like "*Enable*")
      {
        $AddItemLV.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",14.25,1,3,0)
      }
      else
      {
        $AddItemLV.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",14.25,0,3,0)
      }



      $AddItemLV.ForeColor = [System.Drawing.Color]::FromArgb(255,0,0,0)
      $AddItemLV.Name = ""

      $AddItemLV.SubItems.Add($PMSession)
      $AddItemLV.SubItems.Add($PMCurrentConnections)
      $AddItemLV.SubItems.Add($PMState)

      $AddItemLV.Selected = $False
      $AddItemLV.StateImageIndex = 0
      $AddItemLV.Text = $PMName


      $lvPoolMembers.Items.Add($AddItemLV) | Out-Null



    }
  }
  catch {
  }


}

#need to clean up 
function Add-ItemToListViewPools
{
  param($arr) $arr; $arr[0]; $arr[1]; $arr[2]

  $lvPools.Items.Clear()

  foreach ($PoolMember in $Pools)
  {

    $PMName = $PoolMember | Select-Object -ExpandProperty Name
    $PMPartition = $PoolMember | Select-Object -ExpandProperty Partition

    if ($Debug -eq $true)
    {
      Write-Host $PMName
      Write-Host $PMPartition
    }


    $AddItemLV = New-Object System.Windows.Forms.ListViewItem
    $AddItemLV.BackColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
    $AddItemLV.Focused = $False
    $AddItemLV.Font = New-Object System.Drawing.Font ("Microsoft Sans Serif",14.25,0,3,0)
    $AddItemLV.ForeColor = [System.Drawing.Color]::FromArgb(255,0,0,0)
    $AddItemLV.Name = ""

    $AddItemLV.SubItems.Add($PMPartition)
    $AddItemLV.Selected = $False
    $AddItemLV.Text = $PMName


    $lvPools.Items.Add($AddItemLV) | Out-Null



  }

}


function Update-LVPoolMembers
{
  param
  (
    [string]$SelectedPoolPartition,
    [string]$SelectedPool
  )
  #write-host "$SelectedPoolPartition 1"
  # $SelectedPool = $lvpools.selecteditems.text 
  # [string]$SelectedPoolPartition = $lvpools.selecteditems.SubItems[1].text 

  



  $PoolMembers = Get-PoolMember -PoolName $SelectedPool -Partition $SelectedPoolPartition | Select-Object Name,Session,@{ label = "CurrentConnections"; expression = { (Get-PoolMemberStats -Name $_.Name -PoolName $SelectedPool -Partition $SelectedPoolPartition | Select-Object -Expand serverside.curConns).value } },State


  Add-ItemToListViewPoolMember $PoolMembers
  #write-host "$SelectedPoolPartition 2"
  if ($Debug -eq $true)
  {
    write-host "Update-LVPoolMembers SelectedPoolPartition: $SelectedPoolPartition"
    write-host "Update-LVPoolMembers Selectedpool: $SelectedPool"
    write-host "Update-LVPoolMembers Poolmembers $PoolMembers"

  }

}

Function Update-StatusBarPanel {

  $F5Status = Get-F5Status
     
  $sBStatus.Panels[0].Text = "Server: "+$cbF5.Text
  $sBStatus.Panels[1].Text = "F5 Status:$F5Status"
  $sBStatus.Refresh()
  
}
#Call the Function
GenerateForm

