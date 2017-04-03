$inputXML = @"
<Window x:Class="WpfApplication3.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApplication3"
        mc:Ignorable="d"
        Title="PaltoShell" Height="350" Width="590">
    <Grid>
        <TextBlock x:Name="API_Key_Text" HorizontalAlignment="Left" Margin="120,19,0,0" TextWrapping="Wrap" Text="API Key:" VerticalAlignment="Top" Height="15" Width="42"/>
        <TextBox x:Name="Found_or_Missing" HorizontalAlignment="Left" Height="20" Margin="163,15,0,0" TextWrapping="Wrap" Text="Missing" VerticalAlignment="Top" Width="47" />
        <Button x:Name="Generate_Button" Content="Generate Key" HorizontalAlignment="Left" Margin="120,39,0,0" VerticalAlignment="Top" Width="93" Height="20" IsEnabled="False" />
        <CheckBox x:Name="Force_Checkbox" Content="Force" HorizontalAlignment="Left" Margin="120,65,0,0" VerticalAlignment="Top" Height="17" Width="52" />
        <RadioButton x:Name="Connected_Users_Button" Content="Connected now" HorizontalAlignment="Left" Margin="23,145,0,0" VerticalAlignment="Top" Height="14" Width="107" />
        <RadioButton x:Name="Previous_Users_Button" Content="Was connected" HorizontalAlignment="Left" Margin="23,164,0,0" VerticalAlignment="Top" Height="15" Width="105"/>
        <DatePicker x:Name="Datepicker" HorizontalAlignment="Left" Margin="133,160,0,0" VerticalAlignment="Top" BorderThickness="0" Height="20" Width="105" IsEnabled="False" />
        <Image x:Name="Logo" HorizontalAlignment="Left" Height="100" Margin="10,10,0,0" VerticalAlignment="Top" Width="100" Source="logo.png"/>
        <TextBlock x:Name="Header_Text" HorizontalAlignment="Left" TextWrapping="Wrap" VerticalAlignment="Top" Margin="23,121,0,0" Height="19" Width="95">
          <Run Text="Check VPN users" Foreground="#FF1A3B81" />
        </TextBlock>
        <Button x:Name="Query_Button" Content="Query" HorizontalAlignment="Left" Margin="23,193,0,0" VerticalAlignment="Top" Width="75" />
        <TextBlock x:Name="Results_Text" HorizontalAlignment="Left" TextWrapping="Wrap" VerticalAlignment="Top" Margin="251,15,0,0" Height="19" Width="95"><Run Text="Results" Foreground="#FF1A3B81" FontSize="12" /></TextBlock>
        <ListBox x:Name="Results_Box" HorizontalAlignment="Left" Height="258" Margin="251,34,0,0" VerticalAlignment="Top" Width="305" SelectionMode="Extended" FontSize="12" FontFamily="Lucida Console"/>
        <Button x:Name="Save_Button" Content="Save Results" HorizontalAlignment="Left" Margin="120,193,0,0" VerticalAlignment="Top" Width="75"/>
        <TextBlock x:Name="Error_Text" HorizontalAlignment="Left" Height="17" Margin="23,220,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="150" FontSize="12" Foreground="Red" />
        <TextBlock x:Name="Created_By_Text" HorizontalAlignment="Left" Height="17" Margin="10,292,0,0" TextWrapping="Wrap" Text="Created by Marcus Olander" VerticalAlignment="Top" Width="127" FontSize="10" />
        <TextBlock x:Name="Count" HorizontalAlignment="Left" Height="17" Margin="250,295,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top"  FontSize="12" />
    </Grid>
</Window>
"@       
##############################
# B U I L D I N G   G U I
##############################
$InputXML = $InputXML -Replace 'mc:Ignorable="d"','' -Replace "x:N",'N'  -Replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $InputXML
$Reader=(New-Object System.Xml.XmlNodeReader $XAML)
Try { $Form=[Windows.Markup.XamlReader]::Load( $Reader ) }
Catch { Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed." }
$XAML.SelectNodes("//*[@Name]") | % { Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) }
Add-Type -Name Window -Namespace Console -MemberDefinition '
 [DllImport("Kernel32.dll")]
 public static extern IntPtr GetConsoleWindow();
 [DllImport("user32.dll")]
 public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
 '
##############################
# V A R I A B L E S
##############################
$fw_hostname = "<INSERT FIREWALL HOSTNAME OR IP HERE>"
$url = "https://$fw_hostname/api/?key="
$homedir = $env:homedrive+$env:homepath
$default_path = "H:\"
$keyfile = $homedir+"palo_alto.key"
##############################
# F U N C T I O N S
##############################
Function Hide-Console {
  $ConsolePtr = [Console.Window]::GetConsoleWindow()
  [Console.Window]::ShowWindow($ConsolePtr, 0)
}
Function Get-FileName($InitialDirectory) {
  [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
  $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
  $SaveFileDialog.initialDirectory = $InitialDirectory
  $SaveFileDialog.filter = "CSV (*.csv)| *.csv"
  $SaveFileDialog.ShowDialog() | Out-Null
  $SaveFileDialog.filename
}
Function New_API_Key {
  $pass = Get-Credential -Credential $env:userdomain\$env:username
  if (-Not ($pass)) { Return }
  $plainpass = $pass.GetNetworkCredential().Password
  $key_url = "https://"+$fw_hostname+"/api/?type=keygen&user="+$env:username+"&password="+$plainpass
  $KeyClient = New-Object System.Net.WebClient
  [xml]$get_api_key = $KeyClient.DownloadString($key_url)
  $get_api_key.response.result.key > $keyfile
  Clear-Error
}
Function Key_Test {
  if ((-Not (Test-Path $keyfile -ErrorAction SilentlyContinue)) -or (-Not (Get-Content $keyfile))) {
    $WPFFound_or_Missing.Text = "Missing"
    $WPFGenerate_Button.IsEnabled = $true
    $WPFForce_Checkbox.IsEnabled = $false
  }
  else {
    $WPFFound_or_Missing.Text = "Found"
    $WPFGenerate_Button.IsEnabled = $false
    $WPFForce_Checkbox.IsChecked = $false
    $WPFForce_Checkbox.IsEnabled = $true
  }
}
Function Query {
  $n = 0
  if ($results) { $global:results = $null }
  if (-Not(Get-Content $keyfile)) {
    Clear-Error
    $WPFError_Text.AddText("API Key missing")
    $WPFFound_or_Missing.Text = "Missing"
    $WPFGenerate_Button.IsEnabled = $true
    $WPFForce_Checkbox.IsEnabled = $false
  } else {
    $WebClient = New-Object System.Net.WebClient
    $key = Get-Content $keyfile
    if ($WPFConnected_Users_Button.IsChecked) {
      $query_url = $url+$key+"&?type=op&cmd=<show><global-protect-gateway><current-user%2F><%2Fglobal-protect-gateway><%2Fshow>"
    } elseif ($WPFPrevious_Users_Button.IsChecked) {
      $query_url = $url+$key+"&?type=op&cmd=<show><global-protect-gateway><previous-user%2F><%2Fglobal-protect-gateway><%2Fshow>"
    }
    [xml]$global:result = $WebClient.DownloadString($query_url)
    if ($WPFConnected_Users_Button.IsChecked) {
      Results_Header
      $result.response.result.entry | Sort-Object username | foreach {
        $AD_username = (Get-Aduser -Properties Displayname $_.username).DisplayName    
        if ($AD_username.Length -eq 4) {
          $padding = "`t`t`t`t`t"
        } elseif ($AD_username.Length -lt 7) {
          $padding = "`t`t`t`t"
        } elseif ($AD_username.Length -le 13) {
          $padding = "`t`t`t"
        } elseif ($AD_username.Length -le 19) {
          $padding = "`t`t"
        } elseif ($AD_username.Length -gt 19) {
          $padding = "`t"
        }
        $WPFResults_Box.AddText( $AD_username + $padding + $_."login-time".Substring(0,$_."login-time".Length-3) )
      }
      $number_of_users = ($result.response.result.entry.username).count
      $WPFCount.Text = "Total number of users: $number_of_users"
    } elseif ($WPFPrevious_Users_Button.IsChecked) {
      if (-Not($WPFDatepicker.Text)) {
        Clear-Error
        $WPFError_Text.AddText("Please enter a date")
      } elseif ([DateTime]$WPFDatepicker.Text -gt (Get-Date)) {
        Clear-Error
        $WPFError_Text.AddText("Cannot predict the future")
      } else {
        Clear-Error
        Results_Header
        $global:datebox = [DateTime]$WPFDatepicker.Text
        $global:date_string = $datebox.ToString("MMM.dd")
        $result.response.result.entry | Sort-Object username | foreach {
          $global:user_login = [DateTime]$_."login-time".Substring(0,$_."login-time".Length-9)
          $global:user_logout = [DateTime]$_."logout-time".Substring(0,$_."login-time".Length-9)
          if ( ( $user_login -le $datebox ) -And ($user_logout -ge $datebox ) )  {
            $n++
            $AD_username = (Get-Aduser -Properties Displayname $_.username).DisplayName
            if ($AD_username.Length -eq 4) {
              $padding = "`t`t`t`t`t"
            } elseif ($AD_username.Length -lt 7) {
              $padding = "`t`t`t`t"
            } elseif ($AD_username.Length -le 13) {
              $padding = "`t`t`t"
            } elseif ($AD_username.Length -le 19) {
              $padding = "`t`t"
            } elseif ($AD_username.Length -gt 19) {
              $padding = "`t"
            }
            $WPFResults_Box.AddText( $AD_username + $padding + $_."login-time".Substring(0,$_."login-time".Length-3) )
          }
          $global:previous_users_query = 1
          $WPFCount.Text = "Total number of users: $n"
        }
      }
    }
  }
}
Function Export_Results { 
  if ($previous_users_query -eq 1) {
    $result.response.result.entry | Sort-Object username | foreach {
      if ($_."logout-time".Substring(0,$_."logout-time".Length-9) -like $date_string ) {
        $_ | select * | Export-CSV -Append -Path $Save_Path
      } 
    }
  $global:previous_users_query = 0
  } else { $result.response.result.entry | Export-CSV -Path $Save_Path }
}
Function Results_Header { $WPFResults_Box.AddText("Username`t`t`tLogin Time`n--------------------------------------") }
Function Clear-Results { $WPFResults_Box.Items.Clear() }
Function Clear-Error { $WPFError_Text.Text = $null }
##############################
# G U I   E L E M E N T S
##############################
$WPFConnected_Users_Button.IsChecked = $true
$WPFForce_Checkbox.Add_Click({
  if ( $WPFForce_Checkbox.IsChecked ) { $WPFGenerate_Button.IsEnabled = $true }
  elseif ($WPFFound_or_Missing.Text -like "Found") { $WPFGenerate_Button.IsEnabled = $false }
})
$WPFPrevious_Users_Button.Add_Click({ $WPFDatepicker.IsEnabled = $true })
$WPFConnected_Users_Button.Add_Click({ $WPFDatepicker.IsEnabled = $false })
$WPFGenerate_Button.Add_Click({ New_API_Key ; Key_Test })
$WPFSave_Button.Add_Click({ $Save_Path = Get-FileName $default_path ; Export_Results })
$WPFQuery_Button.Add_Click({ Clear-Results ; Query })
##############################
# L A U N C H   G U I
##############################
Hide-Console
Key_Test
Import-Module ActiveDirectory
$Form.ShowDialog() | Out-Null
