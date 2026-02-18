Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Tag Shuffler" Height="420" Width="720" WindowStartupLocation="CenterScreen">
  <Grid Margin="10">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
    </Grid.RowDefinitions>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="Auto"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>

    <TextBlock Grid.ColumnSpan="2" TextWrapping="Wrap" Margin="0,0,0,8">
      This tool selects pseudo-random entries from a single-column CSV/TXT file.
      Select a file, set numeric Range Start/End and Prompt Length, then click Execute.
    </TextBlock>

    <Button Name="SelectFileBtn" Grid.Row="1" Width="110" Height="26">Select File...</Button>
    <TextBlock Name="SelectedFileText" Grid.Row="1" Grid.Column="1" VerticalAlignment="Center" Margin="8,0,0,0" Text="No file selected"/>

    <TextBlock Grid.Row="2" Text="Range Start:" VerticalAlignment="Center"/>
    <TextBox Name="RangeStart" Grid.Row="2" Grid.Column="1" Width="120" Margin="8,2,0,2" Text="1"/>

    <TextBlock Grid.Row="3" Text="Range End:" VerticalAlignment="Center"/>
    <TextBox Name="RangeEnd" Grid.Row="3" Grid.Column="1" Width="120" Margin="8,2,0,2" Text="1"/>

    <TextBlock Grid.Row="4" Text="Prompt Length:" VerticalAlignment="Top"/>
    <StackPanel Grid.Row="4" Grid.Column="1" Orientation="Vertical" Margin="8,2,0,2">
      <TextBox Name="PromptLength" Width="120" Text="10"/>
      <StackPanel Orientation="Horizontal" Margin="0,8,0,0">
        <Button Name="ExecuteBtn" Width="100" Height="28">Execute</Button>
        <Button Name="CloseBtn" Width="100" Height="28" Margin="8,0,0,0">Close</Button>
      </StackPanel>
    </StackPanel>

    <TextBox Name="OutputBox" Grid.Row="5" Grid.ColumnSpan="2" Margin="0,12,0,0" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" IsReadOnly="True"/>
  </Grid>
</Window>
"@

[xml]$xamlXml = $xaml
$reader = (New-Object System.Xml.XmlNodeReader $xamlXml)
$window = [Windows.Markup.XamlReader]::Load($reader)

function Get-Control {
  param([string]$Name)
  $ctrl = $window.FindName($Name)
  if ($null -eq $ctrl) {
    throw "WPF control '$Name' not found in XAML. Check the control Name values."
  }
  return $ctrl
}

$selectBtn    = Get-Control 'SelectFileBtn'
$selectedText = Get-Control 'SelectedFileText'
$rangeStart   = Get-Control 'RangeStart'
$rangeEnd     = Get-Control 'RangeEnd'
$promptLength = Get-Control 'PromptLength'
$executeBtn   = Get-Control 'ExecuteBtn'
$closeBtn     = Get-Control 'CloseBtn'
$outputBox    = Get-Control 'OutputBox'

$global:lines = @()

function Get-FileContent {
    param([string]$Path)
    $vals = @()
    try {
        if (Test-Path -LiteralPath $Path -ErrorAction Stop) {
            $vals = Get-Content -LiteralPath $Path -ErrorAction Stop
        }
    } catch {
        [System.Windows.MessageBox]::Show("Failed to read file: $_", 'Error', 'OK', 'Error') | Out-Null
        return @()
    }
    return $vals
}

$selectBtn.Add_Click({
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Title = 'Select CSV/TXT file (single column)'
    $dlg.Filter = 'CSV or Text|*.csv;*.txt|All files|*.*'
    $dlg.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
    $ok = $dlg.ShowDialog()
    if ($ok -eq $true) {
        $path = $dlg.FileName
        $selectedText.Text = $path
        $global:lines = Get-FileContent -Path $path
        $count = $global:lines.Count
        if ($count -eq 0) {
            [System.Windows.MessageBox]::Show('File contains no usable entries.', 'Info', 'OK', 'Information') | Out-Null
            $rangeEnd.Text = '1'
            $promptLength.Text = '1'
            return
        }
        $rangeStart.Text = '1'
        $rangeEnd.Text = [string]$count
        if ($count -lt 10) { $promptLength.Text = '1' } else { $promptLength.Text = '10' }
    }
})

$executeBtn.Add_Click({
    if (-not $global:lines -or $global:lines.Count -eq 0) {
        [System.Windows.MessageBox]::Show('No file loaded. Please select a file first.', 'Info', 'OK', 'Information') | Out-Null
        return
    }

    try { $rsVal = [decimal]::Parse($rangeStart.Text) } catch { $rsVal = 1 }
    try { $reVal = [decimal]::Parse($rangeEnd.Text) } catch { $reVal = $global:lines.Count }
    try { $plVal = [decimal]::Parse($promptLength.Text) } catch { $plVal = 10 }

    $count = $global:lines.Count
    $rs = [int][math]::Round($rsVal)
    $re = [int][math]::Round($reVal)
    if ($rs -lt 1) { $rs = 1 }
    if ($re -gt $count) { $re = $count }
    if ($re -lt $rs) { $re = $rs }

    $maxAvailable = ($re - $rs) + 1
    $pl = [int][math]::Round($plVal)
    if ($pl -gt $maxAvailable) { $pl = $maxAvailable }
    if ($pl -lt 1) { $pl = 1 }

    $rangeItems = $global:lines[($rs - 1)..($re - 1)]
    if ($pl -ge $rangeItems.Count) { $picked = $rangeItems } else { $picked = Get-Random -InputObject $rangeItems -Count $pl }

    $outputBox.Text = ($picked -join ', ')
})

$closeBtn.Add_Click({ $window.Close() })

$window.ShowDialog() | Out-Null
