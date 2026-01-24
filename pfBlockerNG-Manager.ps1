<#
.SYNOPSIS
    pfBlockerNG Manager v3.5 - Ultimate pfSense/pfBlockerNG Management Tool
.DESCRIPTION
    Comprehensive GUI for managing pfBlockerNG on pfSense firewalls
.VERSION
    3.5.0
#>

#Requires -Version 5.1

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ============================================================================
# CONFIGURATION
# ============================================================================

$Script:Config = @{
    DefaultHost     = "192.168.1.1"
    DefaultPort     = 22
    DefaultUser     = "admin"
    
    ConfigPath      = "$env:APPDATA\pfBlockerNG-Manager\config.json"
    SettingsPath    = "$env:APPDATA\pfBlockerNG-Manager\settings.json"
    AlertsPath      = "$env:APPDATA\pfBlockerNG-Manager\alerts.json"
    
    # pfBlockerNG paths on pfSense
    DNSBLLogPath    = "/var/log/pfblockerng/dnsbl.log"
    DNSReplyLogPath = "/var/log/pfblockerng/dns_reply.log"
    IPBlockLogPath  = "/var/log/pfblockerng/ip_block.log"
    
    AutoRefreshInterval = 10
    LiveStreamInterval  = 2
    DefaultLogLines = 10000
    MaxLogLines     = 100000
    
    AppName         = "pfBlockerNG Manager"
    AppVersion      = "3.5.0"
}

# Default settings
$Script:DefaultSettings = @{
    Theme = "Dark"
    VisibleTabs = @("LiveMonitor", "DNSLogs", "IPBlocking", "ListEditor", "Statistics", "DNSLookup", "Alerts", "Feeds", "System")
    LiveMonitorMax = 500
    AutoRefreshOnTabChange = $true
}

$Script:Settings = $Script:DefaultSettings.Clone()

# ============================================================================
# XAML GUI
# ============================================================================

[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="MainWindow"
        Title="pfBlockerNG Manager v3.5" 
        Height="950" Width="1600"
        MinHeight="750" MinWidth="1300"
        WindowStartupLocation="CenterScreen"
        Background="#1a1a2e">
    
    <Window.Resources>
        <SolidColorBrush x:Key="PrimaryBg" Color="#1a1a2e"/>
        <SolidColorBrush x:Key="SecondaryBg" Color="#16213e"/>
        <SolidColorBrush x:Key="TertiaryBg" Color="#0f3460"/>
        <SolidColorBrush x:Key="AccentColor" Color="#e94560"/>
        <SolidColorBrush x:Key="SuccessColor" Color="#00d9a5"/>
        <SolidColorBrush x:Key="WarningColor" Color="#ffc107"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#edf2f4"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#8d99ae"/>
        <SolidColorBrush x:Key="BorderColor" Color="#2d4059"/>
        
        <Style x:Key="ModernButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource TertiaryBg}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderColor}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="4" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="{StaticResource AccentColor}"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Opacity" Value="0.5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <Style x:Key="AccentButton" TargetType="Button" BasedOn="{StaticResource ModernButton}">
            <Setter Property="Background" Value="{StaticResource AccentColor}"/>
        </Style>
        
        <Style x:Key="SuccessButton" TargetType="Button" BasedOn="{StaticResource ModernButton}">
            <Setter Property="Background" Value="{StaticResource SuccessColor}"/>
            <Setter Property="Foreground" Value="#1a1a2e"/>
        </Style>
        
        <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource ModernButton}">
            <Setter Property="Background" Value="#c0392b"/>
        </Style>
        
        <Style x:Key="SmallButton" TargetType="Button" BasedOn="{StaticResource ModernButton}">
            <Setter Property="Padding" Value="8,4"/>
            <Setter Property="FontSize" Value="11"/>
        </Style>
        
        <Style x:Key="ModernTextBox" TargetType="TextBox">
            <Setter Property="Background" Value="{StaticResource SecondaryBg}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderColor}"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="CaretBrush" Value="{StaticResource TextPrimary}"/>
        </Style>
        
        <Style x:Key="ModernPasswordBox" TargetType="PasswordBox">
            <Setter Property="Background" Value="{StaticResource SecondaryBg}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderColor}"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="CaretBrush" Value="{StaticResource TextPrimary}"/>
        </Style>
        
        <Style x:Key="ModernCheckBox" TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>
        
        <Style TargetType="TabControl">
            <Setter Property="Background" Value="{StaticResource PrimaryBg}"/>
            <Setter Property="BorderThickness" Value="0"/>
        </Style>
        
        <Style TargetType="TabItem">
            <Setter Property="Foreground" Value="{StaticResource TextSecondary}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border x:Name="Border" Background="{StaticResource SecondaryBg}" 
                                CornerRadius="4,4,0,0" Margin="2,0" Padding="12,8">
                            <ContentPresenter ContentSource="Header"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="{StaticResource TertiaryBg}"/>
                                <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <Style TargetType="DataGrid">
            <Setter Property="Background" Value="{StaticResource SecondaryBg}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderColor}"/>
            <Setter Property="GridLinesVisibility" Value="Horizontal"/>
            <Setter Property="HorizontalGridLinesBrush" Value="{StaticResource BorderColor}"/>
            <Setter Property="RowBackground" Value="{StaticResource SecondaryBg}"/>
            <Setter Property="AlternatingRowBackground" Value="{StaticResource PrimaryBg}"/>
        </Style>
        
        <Style TargetType="DataGridColumnHeader">
            <Setter Property="Background" Value="{StaticResource TertiaryBg}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
        </Style>
        
        <Style TargetType="DataGridRow">
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="{StaticResource AccentColor}"/>
                </Trigger>
                <DataTrigger Binding="{Binding RawType}" Value="DNSBL">
                    <Setter Property="Foreground" Value="#ff6b6b"/>
                </DataTrigger>
                <DataTrigger Binding="{Binding RawType}" Value="DNSReply">
                    <Setter Property="Foreground" Value="#00d9a5"/>
                </DataTrigger>
                <DataTrigger Binding="{Binding RawType}" Value="IPBlock">
                    <Setter Property="Foreground" Value="#ffc107"/>
                </DataTrigger>
            </Style.Triggers>
        </Style>
        
        <Style TargetType="ListBox">
            <Setter Property="Background" Value="{StaticResource SecondaryBg}"/>
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderColor}"/>
        </Style>
        
        <Style TargetType="ListBoxItem">
            <Setter Property="Padding" Value="8,4"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="{StaticResource AccentColor}"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>
    
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0" Background="{StaticResource SecondaryBg}" CornerRadius="8" Padding="15,10" Margin="0,0,0,10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <StackPanel Grid.Column="0" Orientation="Horizontal">
                    <Border Background="#0f3460" CornerRadius="4" Padding="8,4" Margin="0,0,10,0">
                        <TextBlock Text="pfB" FontSize="16" FontWeight="Bold" Foreground="#e94560"/>
                    </Border>
                    <StackPanel>
                        <TextBlock Text="pfBlockerNG Manager" FontSize="16" FontWeight="Bold" Foreground="{StaticResource TextPrimary}"/>
                        <TextBlock Text="v3.5 Ultimate" FontSize="10" Foreground="{StaticResource TextSecondary}"/>
                    </StackPanel>
                </StackPanel>
                
                <StackPanel Grid.Column="2" Orientation="Horizontal" Margin="0,0,15,0">
                    <Button x:Name="btnSettings" Content="Settings" Style="{StaticResource SmallButton}" Margin="0,0,10,0"/>
                </StackPanel>
                
                <StackPanel Grid.Column="3" Orientation="Horizontal">
                    <Ellipse x:Name="StatusIndicator" Width="10" Height="10" Fill="#ff6b6b" Margin="0,0,8,0"/>
                    <TextBlock x:Name="StatusText" Text="Disconnected" Foreground="{StaticResource TextSecondary}" VerticalAlignment="Center"/>
                </StackPanel>
            </Grid>
        </Border>
        
        <!-- Connection Panel -->
        <Border Grid.Row="1" Background="{StaticResource SecondaryBg}" CornerRadius="8" Padding="15,10" Margin="0,0,0,10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="140"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="60"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="100"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="140"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <TextBlock Grid.Column="0" Text="Host:" VerticalAlignment="Center" Margin="0,0,5,0" Foreground="{StaticResource TextSecondary}"/>
                <TextBox x:Name="txtHost" Grid.Column="1" Style="{StaticResource ModernTextBox}"/>
                
                <TextBlock Grid.Column="2" Text="Port:" VerticalAlignment="Center" Margin="10,0,5,0" Foreground="{StaticResource TextSecondary}"/>
                <TextBox x:Name="txtPort" Grid.Column="3" Style="{StaticResource ModernTextBox}" Text="22"/>
                
                <TextBlock Grid.Column="4" Text="User:" VerticalAlignment="Center" Margin="10,0,5,0" Foreground="{StaticResource TextSecondary}"/>
                <TextBox x:Name="txtUser" Grid.Column="5" Style="{StaticResource ModernTextBox}"/>
                
                <TextBlock Grid.Column="6" Text="Pass:" VerticalAlignment="Center" Margin="10,0,5,0" Foreground="{StaticResource TextSecondary}"/>
                <PasswordBox x:Name="txtPassword" Grid.Column="7" Style="{StaticResource ModernPasswordBox}"/>
                
                <CheckBox x:Name="chkSaveCredentials" Grid.Column="8" Content="Save" Style="{StaticResource ModernCheckBox}" 
                          VerticalAlignment="Center" Margin="10,0,0,0"/>
                
                <Button x:Name="btnConnect" Grid.Column="10" Content="Connect" Style="{StaticResource AccentButton}" Width="100"/>
            </Grid>
        </Border>
        
        <!-- Main Tabs -->
        <TabControl x:Name="MainTabs" Grid.Row="2">
            
            <!-- Live Monitor Tab (FIRST) -->
            <TabItem x:Name="tabLiveMonitor" Header="Live Monitor">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    
                    <Border Grid.Row="0" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12,8" Margin="0,0,0,10">
                        <StackPanel Orientation="Horizontal">
                            <Button x:Name="btnStartLive" Content="Start Streaming" Style="{StaticResource SuccessButton}" Margin="0,0,10,0"/>
                            <Button x:Name="btnStopLive" Content="Stop" Style="{StaticResource DangerButton}" Margin="0,0,20,0" IsEnabled="False"/>
                            
                            <CheckBox x:Name="chkLiveBlocked" Content="DNS Blocked" Style="{StaticResource ModernCheckBox}" IsChecked="True" VerticalAlignment="Center" Margin="0,0,10,0"/>
                            <CheckBox x:Name="chkLiveAllowed" Content="DNS Allowed" Style="{StaticResource ModernCheckBox}" IsChecked="True" VerticalAlignment="Center" Margin="0,0,10,0"/>
                            <CheckBox x:Name="chkLiveIP" Content="IP Blocks" Style="{StaticResource ModernCheckBox}" IsChecked="True" VerticalAlignment="Center" Margin="0,0,15,0"/>
                            
                            <TextBlock Text="Filter:" VerticalAlignment="Center" Margin="0,0,5,0" Foreground="{StaticResource TextSecondary}"/>
                            <TextBox x:Name="txtLiveFilter" Style="{StaticResource ModernTextBox}" Width="200"/>
                            
                            <TextBlock Text="Max:" VerticalAlignment="Center" Margin="15,0,5,0" Foreground="{StaticResource TextSecondary}"/>
                            <TextBox x:Name="txtLiveMax" Style="{StaticResource ModernTextBox}" Text="500" Width="50"/>
                            
                            <Button x:Name="btnClearLive" Content="Clear" Style="{StaticResource ModernButton}" Margin="15,0,0,0"/>
                        </StackPanel>
                    </Border>
                    
                    <!-- Quick Actions for Live Monitor -->
                    <Border Grid.Row="1" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12,8" Margin="0,0,0,10">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Text="Selected:" VerticalAlignment="Center" Margin="0,0,10,0" Foreground="{StaticResource TextSecondary}"/>
                            <Button x:Name="btnLiveWhitelist" Content="+ Whitelist" Style="{StaticResource SuccessButton}" Margin="0,0,5,0"/>
                            <Button x:Name="btnLiveBlocklist" Content="+ Blocklist" Style="{StaticResource AccentButton}" Margin="0,0,20,0"/>
                            
                            <Separator Width="1" Background="{StaticResource BorderColor}" Margin="0,0,20,0"/>
                            
                            <Button x:Name="btnLiveVirusTotal" Content="VirusTotal" Style="{StaticResource ModernButton}" Margin="0,0,5,0"/>
                            <Button x:Name="btnLiveCopyDomain" Content="Copy Domain" Style="{StaticResource ModernButton}" Margin="0,0,5,0"/>
                            <Button x:Name="btnLiveCopyIP" Content="Copy IP" Style="{StaticResource ModernButton}"/>
                        </StackPanel>
                    </Border>
                    
                    <ListBox x:Name="lstLiveLog" Grid.Row="2" FontFamily="Consolas" FontSize="11" SelectionMode="Single"/>
                </Grid>
            </TabItem>
            
            <!-- DNS Logs Tab -->
            <TabItem x:Name="tabDNSLogs" Header="DNS Logs">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    
                    <Border Grid.Row="0" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12,8" Margin="0,0,0,10">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            
                            <TextBlock Grid.Column="0" Text="Filter:" VerticalAlignment="Center" Margin="0,0,8,0" Foreground="{StaticResource TextSecondary}"/>
                            <TextBox x:Name="txtLogFilter" Grid.Column="1" Style="{StaticResource ModernTextBox}"/>
                            
                            <ComboBox x:Name="cmbLogType" Grid.Column="2" Width="120" Margin="10,0">
                                <ComboBoxItem Content="All Logs" IsSelected="True"/>
                                <ComboBoxItem Content="Blocked Only"/>
                                <ComboBoxItem Content="Allowed Only"/>
                            </ComboBox>
                            
                            <TextBlock Grid.Column="3" Text="Lines:" VerticalAlignment="Center" Margin="0,0,5,0" Foreground="{StaticResource TextSecondary}"/>
                            <TextBox x:Name="txtLogLines" Grid.Column="4" Style="{StaticResource ModernTextBox}" Text="10000" Width="60"/>
                            
                            <CheckBox x:Name="chkAutoRefresh" Grid.Column="5" Content="Auto" Style="{StaticResource ModernCheckBox}" 
                                      VerticalAlignment="Center" Margin="10,0"/>
                            
                            <Button x:Name="btnRefreshLogs" Grid.Column="6" Content="Refresh" Style="{StaticResource ModernButton}"/>
                        </Grid>
                    </Border>
                    
                    <Border Grid.Row="1" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12,8" Margin="0,0,0,10">
                        <StackPanel Orientation="Horizontal">
                            <Button x:Name="btnWhitelistLog" Content="+ Whitelist" Style="{StaticResource SuccessButton}" Margin="0,0,5,0"/>
                            <Button x:Name="btnBlocklistLog" Content="+ Blocklist" Style="{StaticResource AccentButton}" Margin="0,0,5,0"/>
                            <Button x:Name="btnExportLogs" Content="Export CSV" Style="{StaticResource ModernButton}" Margin="0,0,20,0"/>
                            
                            <Separator Width="1" Background="{StaticResource BorderColor}" Margin="0,0,20,0"/>
                            
                            <Button x:Name="btnReloadDNSBL" Content="Reload DNSBL" Style="{StaticResource ModernButton}" Margin="0,0,5,0"/>
                            <Button x:Name="btnForceUpdate" Content="Force Update" Style="{StaticResource ModernButton}" Margin="0,0,5,0"/>
                            <Button x:Name="btnClearCache" Content="Clear DNS Cache" Style="{StaticResource ModernButton}"/>
                        </StackPanel>
                    </Border>
                    
                    <DataGrid x:Name="dgLogs" Grid.Row="2" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Extended">
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Type" Binding="{Binding Type}" Width="70"/>
                            <DataGridTextColumn Header="Timestamp" Binding="{Binding Timestamp}" Width="140"/>
                            <DataGridTextColumn Header="Domain" Binding="{Binding Domain}" Width="*" MinWidth="200"/>
                            <DataGridTextColumn Header="Client" Binding="{Binding ClientIP}" Width="120"/>
                            <DataGridTextColumn Header="Feed" Binding="{Binding Feed}" Width="120"/>
                        </DataGrid.Columns>
                        <DataGrid.ContextMenu>
                            <ContextMenu>
                                <MenuItem x:Name="ctxWhitelist" Header="[+] Whitelist Domain"/>
                                <MenuItem x:Name="ctxBlocklist" Header="[X] Blocklist Domain"/>
                                <Separator/>
                                <MenuItem x:Name="ctxVirusTotal" Header="Lookup on VirusTotal"/>
                                <MenuItem x:Name="ctxCopyDomain" Header="Copy Domain"/>
                                <MenuItem x:Name="ctxCopyIP" Header="Copy IP"/>
                            </ContextMenu>
                        </DataGrid.ContextMenu>
                    </DataGrid>
                </Grid>
            </TabItem>
            
            <!-- IP Blocking Tab (NEW) -->
            <TabItem x:Name="tabIPBlocking" Header="IP Blocking">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    
                    <Border Grid.Row="0" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12,8" Margin="0,0,0,10">
                        <StackPanel Orientation="Horizontal">
                            <Button x:Name="btnRefreshIPLogs" Content="Refresh IP Logs" Style="{StaticResource ModernButton}" Margin="0,0,10,0"/>
                            <Button x:Name="btnExportIPLogs" Content="Export CSV" Style="{StaticResource ModernButton}" Margin="0,0,20,0"/>
                            
                            <TextBlock Text="Filter:" VerticalAlignment="Center" Margin="0,0,5,0" Foreground="{StaticResource TextSecondary}"/>
                            <TextBox x:Name="txtIPFilter" Style="{StaticResource ModernTextBox}" Width="200"/>
                            
                            <TextBlock Text="Lines:" VerticalAlignment="Center" Margin="15,0,5,0" Foreground="{StaticResource TextSecondary}"/>
                            <TextBox x:Name="txtIPLines" Style="{StaticResource ModernTextBox}" Text="5000" Width="60"/>
                        </StackPanel>
                    </Border>
                    
                    <!-- IP Stats Summary -->
                    <Border Grid.Row="1" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="15" Margin="0,0,0,10">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            
                            <StackPanel Grid.Column="0" HorizontalAlignment="Center">
                                <TextBlock Text="Total IP Blocks" Foreground="{StaticResource TextSecondary}" HorizontalAlignment="Center"/>
                                <TextBlock x:Name="txtIPTotalBlocks" Text="0" FontSize="24" FontWeight="Bold" Foreground="{StaticResource WarningColor}" HorizontalAlignment="Center"/>
                            </StackPanel>
                            
                            <StackPanel Grid.Column="1" HorizontalAlignment="Center">
                                <TextBlock Text="Inbound Blocks" Foreground="{StaticResource TextSecondary}" HorizontalAlignment="Center"/>
                                <TextBlock x:Name="txtIPInbound" Text="0" FontSize="24" FontWeight="Bold" Foreground="#ff6b6b" HorizontalAlignment="Center"/>
                            </StackPanel>
                            
                            <StackPanel Grid.Column="2" HorizontalAlignment="Center">
                                <TextBlock Text="Outbound Blocks" Foreground="{StaticResource TextSecondary}" HorizontalAlignment="Center"/>
                                <TextBlock x:Name="txtIPOutbound" Text="0" FontSize="24" FontWeight="Bold" Foreground="{StaticResource AccentColor}" HorizontalAlignment="Center"/>
                            </StackPanel>
                            
                            <StackPanel Grid.Column="3" HorizontalAlignment="Center">
                                <TextBlock Text="Active IP Tables" Foreground="{StaticResource TextSecondary}" HorizontalAlignment="Center"/>
                                <TextBlock x:Name="txtIPTables" Text="0" FontSize="24" FontWeight="Bold" Foreground="{StaticResource SuccessColor}" HorizontalAlignment="Center"/>
                            </StackPanel>
                        </Grid>
                    </Border>
                    
                    <DataGrid x:Name="dgIPLogs" Grid.Row="2" AutoGenerateColumns="False" IsReadOnly="True" SelectionMode="Extended">
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Timestamp" Binding="{Binding Timestamp}" Width="150"/>
                            <DataGridTextColumn Header="Direction" Binding="{Binding Direction}" Width="80"/>
                            <DataGridTextColumn Header="Source IP" Binding="{Binding SourceIP}" Width="140"/>
                            <DataGridTextColumn Header="Dest IP" Binding="{Binding DestIP}" Width="140"/>
                            <DataGridTextColumn Header="Port" Binding="{Binding Port}" Width="60"/>
                            <DataGridTextColumn Header="Protocol" Binding="{Binding Protocol}" Width="70"/>
                            <DataGridTextColumn Header="Feed/List" Binding="{Binding Feed}" Width="150"/>
                            <DataGridTextColumn Header="Country" Binding="{Binding Country}" Width="80"/>
                        </DataGrid.Columns>
                        <DataGrid.ContextMenu>
                            <ContextMenu>
                                <MenuItem x:Name="ctxIPWhitelist" Header="[+] Add IP to Whitelist"/>
                                <MenuItem x:Name="ctxIPLookup" Header="Lookup IP on AbuseIPDB"/>
                                <MenuItem x:Name="ctxIPCopy" Header="Copy IP"/>
                            </ContextMenu>
                        </DataGrid.ContextMenu>
                    </DataGrid>
                </Grid>
            </TabItem>
            
            <!-- List Editor Tab -->
            <TabItem x:Name="tabListEditor" Header="List Editor">
                <Grid Margin="10">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <!-- Whitelist -->
                    <Border Grid.Column="0" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12" Margin="0,0,5,0">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>
                            
                            <TextBlock Grid.Row="0" Text="DNSBL WHITELIST (Allowed Domains)" FontSize="14" FontWeight="Bold" Foreground="{StaticResource SuccessColor}" Margin="0,0,0,10"/>
                            
                            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,10">
                                <TextBox x:Name="txtWhitelistAdd" Style="{StaticResource ModernTextBox}" Width="250" ToolTip="Enter domain (e.g., example.com or .example.com for wildcard)"/>
                                <Button x:Name="btnWhitelistAdd" Content="Add" Style="{StaticResource SuccessButton}" Margin="5,0"/>
                                <Button x:Name="btnWhitelistRemove" Content="Remove" Style="{StaticResource DangerButton}"/>
                            </StackPanel>
                            
                            <ListBox x:Name="lstWhitelist" Grid.Row="2" SelectionMode="Extended"/>
                            
                            <StackPanel Grid.Row="3" Orientation="Horizontal" Margin="0,10,0,0">
                                <Button x:Name="btnWhitelistRefresh" Content="Refresh" Style="{StaticResource SmallButton}" Margin="0,0,5,0"/>
                                <Button x:Name="btnWhitelistImport" Content="Import" Style="{StaticResource SmallButton}" Margin="0,0,5,0"/>
                                <Button x:Name="btnWhitelistExport" Content="Export" Style="{StaticResource SmallButton}"/>
                                <TextBlock x:Name="txtWhitelistCount" Text="0 entries" VerticalAlignment="Center" Margin="10,0,0,0" Foreground="{StaticResource TextSecondary}"/>
                            </StackPanel>
                        </Grid>
                    </Border>
                    
                    <!-- Blocklist -->
                    <Border Grid.Column="1" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12" Margin="5,0,0,0">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>
                            
                            <TextBlock Grid.Row="0" Text="DNSBL BLOCKLIST (Custom Blocked)" FontSize="14" FontWeight="Bold" Foreground="{StaticResource AccentColor}" Margin="0,0,0,10"/>
                            
                            <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,10">
                                <TextBox x:Name="txtBlocklistAdd" Style="{StaticResource ModernTextBox}" Width="250" ToolTip="Enter domain to block"/>
                                <Button x:Name="btnBlocklistAdd" Content="Add" Style="{StaticResource AccentButton}" Margin="5,0"/>
                                <Button x:Name="btnBlocklistRemove" Content="Remove" Style="{StaticResource DangerButton}"/>
                            </StackPanel>
                            
                            <ListBox x:Name="lstBlocklist" Grid.Row="2" SelectionMode="Extended"/>
                            
                            <StackPanel Grid.Row="3" Orientation="Horizontal" Margin="0,10,0,0">
                                <Button x:Name="btnBlocklistRefresh" Content="Refresh" Style="{StaticResource SmallButton}" Margin="0,0,5,0"/>
                                <Button x:Name="btnBlocklistImport" Content="Import" Style="{StaticResource SmallButton}" Margin="0,0,5,0"/>
                                <Button x:Name="btnBlocklistExport" Content="Export" Style="{StaticResource SmallButton}"/>
                                <TextBlock x:Name="txtBlocklistCount" Text="0 entries" VerticalAlignment="Center" Margin="10,0,0,0" Foreground="{StaticResource TextSecondary}"/>
                            </StackPanel>
                        </Grid>
                    </Border>
                </Grid>
            </TabItem>
            
            <!-- Statistics Tab -->
            <TabItem x:Name="tabStatistics" Header="Statistics">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    
                    <Border Grid.Row="0" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12,8" Margin="0,0,0,10">
                        <StackPanel Orientation="Horizontal">
                            <Button x:Name="btnRefreshStats" Content="Refresh Stats" Style="{StaticResource ModernButton}" Margin="0,0,10,0"/>
                            <Button x:Name="btnExportStats" Content="Export CSV" Style="{StaticResource ModernButton}"/>
                        </StackPanel>
                    </Border>
                    
                    <!-- Stats Summary -->
                    <Border Grid.Row="1" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="15" Margin="0,0,0,10">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            
                            <StackPanel Grid.Column="0" HorizontalAlignment="Center">
                                <TextBlock Text="Total Queries" Foreground="{StaticResource TextSecondary}" HorizontalAlignment="Center"/>
                                <TextBlock x:Name="txtStatTotal" Text="0" FontSize="24" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" HorizontalAlignment="Center"/>
                            </StackPanel>
                            
                            <StackPanel Grid.Column="1" HorizontalAlignment="Center">
                                <TextBlock Text="Blocked" Foreground="{StaticResource TextSecondary}" HorizontalAlignment="Center"/>
                                <TextBlock x:Name="txtStatBlocked" Text="0" FontSize="24" FontWeight="Bold" Foreground="#ff6b6b" HorizontalAlignment="Center"/>
                            </StackPanel>
                            
                            <StackPanel Grid.Column="2" HorizontalAlignment="Center">
                                <TextBlock Text="Allowed" Foreground="{StaticResource TextSecondary}" HorizontalAlignment="Center"/>
                                <TextBlock x:Name="txtStatAllowed" Text="0" FontSize="24" FontWeight="Bold" Foreground="{StaticResource SuccessColor}" HorizontalAlignment="Center"/>
                            </StackPanel>
                            
                            <StackPanel Grid.Column="3" HorizontalAlignment="Center">
                                <TextBlock Text="Block Rate" Foreground="{StaticResource TextSecondary}" HorizontalAlignment="Center"/>
                                <TextBlock x:Name="txtStatBlockRate" Text="0%" FontSize="24" FontWeight="Bold" Foreground="{StaticResource WarningColor}" HorizontalAlignment="Center"/>
                            </StackPanel>
                            
                            <StackPanel Grid.Column="4" HorizontalAlignment="Center">
                                <TextBlock Text="Unique Clients" Foreground="{StaticResource TextSecondary}" HorizontalAlignment="Center"/>
                                <TextBlock x:Name="txtStatClients" Text="0" FontSize="24" FontWeight="Bold" Foreground="{StaticResource AccentColor}" HorizontalAlignment="Center"/>
                            </StackPanel>
                        </Grid>
                    </Border>
                    
                    <Grid Grid.Row="2">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        
                        <Border Grid.Column="0" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12" Margin="0,0,5,0">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                </Grid.RowDefinitions>
                                <TextBlock Grid.Row="0" Text="Queries by Client" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,10"/>
                                <DataGrid x:Name="dgClientStats" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True">
                                    <DataGrid.Columns>
                                        <DataGridTextColumn Header="Client IP" Binding="{Binding ClientIP}" Width="*"/>
                                        <DataGridTextColumn Header="Total" Binding="{Binding Total}" Width="60"/>
                                        <DataGridTextColumn Header="Blocked" Binding="{Binding Blocked}" Width="60"/>
                                        <DataGridTextColumn Header="Block %" Binding="{Binding BlockPercent}" Width="60"/>
                                    </DataGrid.Columns>
                                </DataGrid>
                            </Grid>
                        </Border>
                        
                        <Border Grid.Column="1" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12" Margin="5,0,0,0">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                </Grid.RowDefinitions>
                                
                                <TextBlock Grid.Row="0" Text="Top Blocked Domains" FontWeight="Bold" Foreground="#ff6b6b" Margin="0,0,0,5"/>
                                <DataGrid x:Name="dgTopBlocked" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True">
                                    <DataGrid.Columns>
                                        <DataGridTextColumn Header="Domain" Binding="{Binding Domain}" Width="*"/>
                                        <DataGridTextColumn Header="Count" Binding="{Binding Count}" Width="60"/>
                                    </DataGrid.Columns>
                                </DataGrid>
                                
                                <TextBlock Grid.Row="2" Text="Top Allowed Domains" FontWeight="Bold" Foreground="{StaticResource SuccessColor}" Margin="0,10,0,5"/>
                                <DataGrid x:Name="dgTopAllowed" Grid.Row="3" AutoGenerateColumns="False" IsReadOnly="True">
                                    <DataGrid.Columns>
                                        <DataGridTextColumn Header="Domain" Binding="{Binding Domain}" Width="*"/>
                                        <DataGridTextColumn Header="Count" Binding="{Binding Count}" Width="60"/>
                                    </DataGrid.Columns>
                                </DataGrid>
                            </Grid>
                        </Border>
                    </Grid>
                </Grid>
            </TabItem>
            
            <!-- DNS Lookup Tab -->
            <TabItem x:Name="tabDNSLookup" Header="DNS Lookup">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    
                    <Border Grid.Row="0" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="15" Margin="0,0,0,10">
                        <StackPanel>
                            <TextBlock Text="Test if a domain would be blocked by pfBlockerNG" Foreground="{StaticResource TextSecondary}" Margin="0,0,0,10"/>
                            <StackPanel Orientation="Horizontal">
                                <TextBox x:Name="txtLookupDomain" Style="{StaticResource ModernTextBox}" Width="400"/>
                                <Button x:Name="btnLookupDomain" Content="Test Domain" Style="{StaticResource AccentButton}" Margin="10,0,0,0"/>
                                <Button x:Name="btnLookupVirusTotal" Content="VirusTotal" Style="{StaticResource ModernButton}" Margin="10,0,0,0"/>
                            </StackPanel>
                        </StackPanel>
                    </Border>
                    
                    <Border Grid.Row="1" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="15" Margin="0,0,0,10">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            
                            <StackPanel Grid.Column="0">
                                <TextBlock Text="Block Status" Foreground="{StaticResource TextSecondary}"/>
                                <TextBlock x:Name="txtLookupStatus" Text="-" FontSize="18" FontWeight="Bold" Foreground="{StaticResource TextPrimary}"/>
                            </StackPanel>
                            
                            <StackPanel Grid.Column="1">
                                <TextBlock Text="Matched Feed" Foreground="{StaticResource TextSecondary}"/>
                                <TextBlock x:Name="txtLookupFeed" Text="-" FontSize="18" Foreground="{StaticResource TextPrimary}"/>
                            </StackPanel>
                            
                            <StackPanel Grid.Column="2">
                                <TextBlock Text="Resolved IP" Foreground="{StaticResource TextSecondary}"/>
                                <TextBlock x:Name="txtLookupIP" Text="-" FontSize="18" Foreground="{StaticResource TextPrimary}"/>
                            </StackPanel>
                        </Grid>
                    </Border>
                    
                    <Border Grid.Row="2" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="15">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <TextBlock Grid.Row="0" Text="Lookup Results" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,10"/>
                            <TextBox x:Name="txtLookupResults" Grid.Row="1" Style="{StaticResource ModernTextBox}" 
                                     IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" 
                                     FontFamily="Consolas" AcceptsReturn="True"/>
                        </Grid>
                    </Border>
                </Grid>
            </TabItem>
            
            <!-- Alerts Tab -->
            <TabItem x:Name="tabAlerts" Header="Alerts">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    
                    <Border Grid.Row="0" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12,8" Margin="0,0,0,10">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            
                            <TextBlock Grid.Column="0" Text="Domain Pattern:" VerticalAlignment="Center" Margin="0,0,8,0" Foreground="{StaticResource TextSecondary}"/>
                            <TextBox x:Name="txtAlertDomain" Grid.Column="1" Style="{StaticResource ModernTextBox}"/>
                            
                            <ComboBox x:Name="cmbAlertType" Grid.Column="2" Width="100" Margin="10,0">
                                <ComboBoxItem Content="Any" IsSelected="True"/>
                                <ComboBoxItem Content="Blocked"/>
                                <ComboBoxItem Content="Allowed"/>
                            </ComboBox>
                            
                            <Button x:Name="btnAddAlert" Grid.Column="3" Content="Add Rule" Style="{StaticResource SuccessButton}" Margin="0,0,5,0"/>
                            <Button x:Name="btnRemoveAlert" Grid.Column="4" Content="Remove" Style="{StaticResource DangerButton}"/>
                        </Grid>
                    </Border>
                    
                    <Grid Grid.Row="1">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        
                        <Border Grid.Column="0" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12" Margin="0,0,5,0">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                </Grid.RowDefinitions>
                                <TextBlock Grid.Row="0" Text="Alert Rules" FontWeight="Bold" Foreground="{StaticResource WarningColor}" Margin="0,0,0,10"/>
                                <ListBox x:Name="lstAlertRules" Grid.Row="1"/>
                            </Grid>
                        </Border>
                        
                        <Border Grid.Column="1" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12" Margin="5,0,0,0">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                </Grid.RowDefinitions>
                                <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,10">
                                    <TextBlock Text="Triggered Alerts" FontWeight="Bold" Foreground="{StaticResource AccentColor}"/>
                                    <TextBlock x:Name="txtAlertCount" Text=" (0)" Foreground="{StaticResource TextSecondary}"/>
                                    <Button x:Name="btnClearAlerts" Content="Clear" Style="{StaticResource SmallButton}" Margin="15,0,0,0"/>
                                </StackPanel>
                                <ListBox x:Name="lstTriggeredAlerts" Grid.Row="1" FontFamily="Consolas" FontSize="11"/>
                            </Grid>
                        </Border>
                    </Grid>
                    
                    <Border Grid.Row="2" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12,8" Margin="0,10,0,0">
                        <StackPanel Orientation="Horizontal">
                            <CheckBox x:Name="chkAlertSound" Content="Play sound" Style="{StaticResource ModernCheckBox}" Margin="0,0,20,0"/>
                            <CheckBox x:Name="chkAlertPopup" Content="Show popup" Style="{StaticResource ModernCheckBox}" IsChecked="True" Margin="0,0,20,0"/>
                            <CheckBox x:Name="chkAlertMonitor" Content="Enable monitoring" Style="{StaticResource ModernCheckBox}"/>
                        </StackPanel>
                    </Border>
                </Grid>
            </TabItem>
            
            <!-- Feeds Tab -->
            <TabItem x:Name="tabFeeds" Header="Feeds">
                <Grid Margin="10">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    
                    <Border Grid.Row="0" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12,8" Margin="0,0,0,10">
                        <StackPanel Orientation="Horizontal">
                            <Button x:Name="btnRefreshFeeds" Content="Refresh Feeds" Style="{StaticResource ModernButton}" Margin="0,0,10,0"/>
                            <Button x:Name="btnUpdateAllFeeds" Content="Update All Feeds" Style="{StaticResource AccentButton}"/>
                        </StackPanel>
                    </Border>
                    
                    <Border Grid.Row="1" Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="12">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <TextBlock Grid.Row="0" Text="pfBlockerNG DNSBL Feeds" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,10"/>
                            <DataGrid x:Name="dgFeeds" Grid.Row="1" AutoGenerateColumns="False" IsReadOnly="True">
                                <DataGrid.Columns>
                                    <DataGridTextColumn Header="Feed Name" Binding="{Binding Name}" Width="200"/>
                                    <DataGridTextColumn Header="Entries" Binding="{Binding Entries}" Width="80"/>
                                    <DataGridTextColumn Header="Last Updated" Binding="{Binding Updated}" Width="150"/>
                                    <DataGridTextColumn Header="File" Binding="{Binding File}" Width="*"/>
                                </DataGrid.Columns>
                            </DataGrid>
                        </Grid>
                    </Border>
                </Grid>
            </TabItem>
            
            <!-- System Tab -->
            <TabItem x:Name="tabSystem" Header="System">
                <Grid Margin="10">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <!-- Left Column -->
                    <StackPanel Grid.Column="0" Margin="0,0,5,0">
                        <Border Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="15" Margin="0,0,0,10">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                
                                <TextBlock Grid.Row="0" Text="pfBlockerNG Status" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,15"/>
                                
                                <Grid Grid.Row="1">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions>
                                        <RowDefinition/>
                                        <RowDefinition/>
                                        <RowDefinition/>
                                        <RowDefinition/>
                                        <RowDefinition/>
                                    </Grid.RowDefinitions>
                                    
                                    <TextBlock Grid.Row="0" Grid.Column="0" Text="DNSBL Domains:" Foreground="{StaticResource TextSecondary}"/>
                                    <TextBlock x:Name="txtSysDNSBL" Grid.Row="0" Grid.Column="1" Text="-" Foreground="{StaticResource TextPrimary}" FontWeight="Bold"/>
                                    
                                    <TextBlock Grid.Row="1" Grid.Column="0" Text="IP Blocks:" Foreground="{StaticResource TextSecondary}" Margin="0,5,0,0"/>
                                    <TextBlock x:Name="txtSysIP" Grid.Row="1" Grid.Column="1" Text="-" Foreground="{StaticResource TextPrimary}" FontWeight="Bold" Margin="0,5,0,0"/>
                                    
                                    <TextBlock Grid.Row="2" Grid.Column="0" Text="Blocks Today:" Foreground="{StaticResource TextSecondary}" Margin="0,5,0,0"/>
                                    <TextBlock x:Name="txtSysToday" Grid.Row="2" Grid.Column="1" Text="-" Foreground="#ff6b6b" FontWeight="Bold" Margin="0,5,0,0"/>
                                    
                                    <TextBlock Grid.Row="3" Grid.Column="0" Text="Whitelist:" Foreground="{StaticResource TextSecondary}" Margin="0,5,0,0"/>
                                    <TextBlock x:Name="txtSysWhite" Grid.Row="3" Grid.Column="1" Text="-" Foreground="{StaticResource SuccessColor}" FontWeight="Bold" Margin="0,5,0,0"/>
                                    
                                    <TextBlock Grid.Row="4" Grid.Column="0" Text="Blocklist:" Foreground="{StaticResource TextSecondary}" Margin="0,5,0,0"/>
                                    <TextBlock x:Name="txtSysBlock" Grid.Row="4" Grid.Column="1" Text="-" Foreground="{StaticResource AccentColor}" FontWeight="Bold" Margin="0,5,0,0"/>
                                </Grid>
                            </Grid>
                        </Border>
                        
                        <Border Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="15">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                
                                <TextBlock Grid.Row="0" Text="Firewall Actions" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,15"/>
                                
                                <WrapPanel Grid.Row="1">
                                    <Button x:Name="btnSysReload" Content="Reload DNSBL" Style="{StaticResource ModernButton}" Margin="0,0,5,5"/>
                                    <Button x:Name="btnSysUpdate" Content="Force Update" Style="{StaticResource ModernButton}" Margin="0,0,5,5"/>
                                    <Button x:Name="btnSysClear" Content="Clear DNS Cache" Style="{StaticResource ModernButton}" Margin="0,0,5,5"/>
                                    <Button x:Name="btnSysRestartDNS" Content="Restart DNS" Style="{StaticResource ModernButton}" Margin="0,0,5,5"/>
                                    <Button x:Name="btnSysRefresh" Content="Refresh Stats" Style="{StaticResource ModernButton}" Margin="0,0,5,5"/>
                                    <Button x:Name="btnSysReboot" Content="Reboot Firewall" Style="{StaticResource DangerButton}" Margin="0,0,5,5"/>
                                </WrapPanel>
                            </Grid>
                        </Border>
                    </StackPanel>
                    
                    <!-- Right Column -->
                    <StackPanel Grid.Column="1" Margin="5,0,0,0">
                        <Border Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="15" Margin="0,0,0,10">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                
                                <TextBlock Grid.Row="0" Text="Backup / Restore" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,15"/>
                                
                                <StackPanel Grid.Row="1" Orientation="Horizontal">
                                    <Button x:Name="btnBackupLists" Content="Backup Lists" Style="{StaticResource ModernButton}" Margin="0,0,10,0"/>
                                    <Button x:Name="btnRestoreLists" Content="Restore Lists" Style="{StaticResource ModernButton}"/>
                                </StackPanel>
                            </Grid>
                        </Border>
                        
                        <Border Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="15">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                
                                <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,10">
                                    <TextBlock Text="Installed Packages" FontWeight="Bold" Foreground="{StaticResource TextPrimary}"/>
                                    <Button x:Name="btnRefreshPackages" Content="Refresh" Style="{StaticResource SmallButton}" Margin="15,0,0,0"/>
                                </StackPanel>
                                
                                <ListBox x:Name="lstPackages" Grid.Row="1" Height="200" FontFamily="Consolas" FontSize="11"/>
                            </Grid>
                        </Border>
                    </StackPanel>
                </Grid>
            </TabItem>
            
        </TabControl>
        
        <!-- Status Bar -->
        <Border Grid.Row="3" Background="{StaticResource SecondaryBg}" CornerRadius="8" Padding="12,8" Margin="0,10,0,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <TextBlock x:Name="txtStatusMessage" Grid.Column="0" Text="Ready" Foreground="{StaticResource TextSecondary}"/>
                
                <StackPanel Grid.Column="1" Orientation="Horizontal" Margin="15,0">
                    <TextBlock Text="Total: " Foreground="{StaticResource TextSecondary}"/>
                    <TextBlock x:Name="txtTotalCount" Text="0" Foreground="{StaticResource AccentColor}" FontWeight="Bold"/>
                </StackPanel>
                
                <StackPanel Grid.Column="2" Orientation="Horizontal" Margin="15,0">
                    <TextBlock Text="Blocked: " Foreground="{StaticResource TextSecondary}"/>
                    <TextBlock x:Name="txtBlockedCount" Text="0" Foreground="#ff6b6b" FontWeight="Bold"/>
                </StackPanel>
                
                <StackPanel Grid.Column="3" Orientation="Horizontal" Margin="15,0">
                    <TextBlock Text="Allowed: " Foreground="{StaticResource TextSecondary}"/>
                    <TextBlock x:Name="txtAllowedCount" Text="0" Foreground="{StaticResource SuccessColor}" FontWeight="Bold"/>
                </StackPanel>
                
                <StackPanel Grid.Column="4" Orientation="Horizontal" Margin="15,0,0,0">
                    <TextBlock Text="Alerts: " Foreground="{StaticResource TextSecondary}"/>
                    <TextBlock x:Name="txtActiveAlerts" Text="0" Foreground="{StaticResource WarningColor}" FontWeight="Bold"/>
                </StackPanel>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# ============================================================================
# SETTINGS WINDOW XAML
# ============================================================================

[xml]$SettingsXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Settings" Height="500" Width="450"
        WindowStartupLocation="CenterOwner"
        Background="#1a1a2e" ResizeMode="NoResize">
    
    <Window.Resources>
        <SolidColorBrush x:Key="SecondaryBg" Color="#16213e"/>
        <SolidColorBrush x:Key="TertiaryBg" Color="#0f3460"/>
        <SolidColorBrush x:Key="AccentColor" Color="#e94560"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#edf2f4"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#8d99ae"/>
        <SolidColorBrush x:Key="BorderColor" Color="#2d4059"/>
        
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="Margin" Value="0,5"/>
        </Style>
    </Window.Resources>
    
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <TextBlock Grid.Row="0" Text="Settings" FontSize="18" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,20"/>
        
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel>
                <!-- Theme -->
                <Border Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="15" Margin="0,0,0,10">
                    <StackPanel>
                        <TextBlock Text="Theme" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,10"/>
                        <ComboBox x:Name="cmbTheme" Width="150" HorizontalAlignment="Left">
                            <ComboBoxItem Content="Dark" IsSelected="True"/>
                            <ComboBoxItem Content="Light"/>
                        </ComboBox>
                    </StackPanel>
                </Border>
                
                <!-- Visible Tabs -->
                <Border Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="15" Margin="0,0,0,10">
                    <StackPanel>
                        <TextBlock Text="Visible Tabs" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,10"/>
                        <CheckBox x:Name="chkTabLiveMonitor" Content="Live Monitor" IsChecked="True"/>
                        <CheckBox x:Name="chkTabDNSLogs" Content="DNS Logs" IsChecked="True"/>
                        <CheckBox x:Name="chkTabIPBlocking" Content="IP Blocking" IsChecked="True"/>
                        <CheckBox x:Name="chkTabListEditor" Content="List Editor" IsChecked="True"/>
                        <CheckBox x:Name="chkTabStatistics" Content="Statistics" IsChecked="True"/>
                        <CheckBox x:Name="chkTabDNSLookup" Content="DNS Lookup" IsChecked="True"/>
                        <CheckBox x:Name="chkTabAlerts" Content="Alerts" IsChecked="True"/>
                        <CheckBox x:Name="chkTabFeeds" Content="Feeds" IsChecked="True"/>
                        <CheckBox x:Name="chkTabSystem" Content="System" IsChecked="True"/>
                    </StackPanel>
                </Border>
                
                <!-- Behavior -->
                <Border Background="{StaticResource SecondaryBg}" CornerRadius="6" Padding="15">
                    <StackPanel>
                        <TextBlock Text="Behavior" FontWeight="Bold" Foreground="{StaticResource TextPrimary}" Margin="0,0,0,10"/>
                        <CheckBox x:Name="chkAutoRefreshTab" Content="Auto-refresh data when changing tabs" IsChecked="True"/>
                        <StackPanel Orientation="Horizontal" Margin="0,10,0,0">
                            <TextBlock Text="Live Monitor max entries:" Foreground="{StaticResource TextSecondary}" VerticalAlignment="Center"/>
                            <TextBox x:Name="txtSettingsLiveMax" Text="500" Width="60" Margin="10,0,0,0" 
                                     Background="{StaticResource TertiaryBg}" Foreground="{StaticResource TextPrimary}" 
                                     BorderBrush="{StaticResource BorderColor}" Padding="5,3"/>
                        </StackPanel>
                    </StackPanel>
                </Border>
            </StackPanel>
        </ScrollViewer>
        
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,20,0,0">
            <Button x:Name="btnSettingsSave" Content="Save" Width="80" Margin="0,0,10,0" Padding="10,8"
                    Background="{StaticResource AccentColor}" Foreground="{StaticResource TextPrimary}" 
                    BorderThickness="0" Cursor="Hand"/>
            <Button x:Name="btnSettingsCancel" Content="Cancel" Width="80" Padding="10,8"
                    Background="{StaticResource TertiaryBg}" Foreground="{StaticResource TextPrimary}" 
                    BorderThickness="0" Cursor="Hand"/>
        </StackPanel>
    </Grid>
</Window>
"@

# ============================================================================
# INITIALIZE WINDOW
# ============================================================================

$Reader = New-Object System.Xml.XmlNodeReader $XAML
$Window = [Windows.Markup.XamlReader]::Load($Reader)

$XAML.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {
    Set-Variable -Name ($_.Name) -Value $Window.FindName($_.Name) -Scope Script
}

# ============================================================================
# GLOBAL STATE
# ============================================================================

$Script:LogData = [System.Collections.ObjectModel.ObservableCollection[PSObject]]::new()
$Script:FilteredData = [System.Collections.ObjectModel.ObservableCollection[PSObject]]::new()
$Script:IPLogData = [System.Collections.ObjectModel.ObservableCollection[PSObject]]::new()
$Script:WhitelistData = [System.Collections.ObjectModel.ObservableCollection[string]]::new()
$Script:BlocklistData = [System.Collections.ObjectModel.ObservableCollection[string]]::new()
$Script:LiveLogData = [System.Collections.ObjectModel.ObservableCollection[string]]::new()
$Script:AlertRules = [System.Collections.ObjectModel.ObservableCollection[PSObject]]::new()
$Script:TriggeredAlerts = [System.Collections.ObjectModel.ObservableCollection[string]]::new()
$Script:ClientStats = [System.Collections.ObjectModel.ObservableCollection[PSObject]]::new()
$Script:TopBlocked = [System.Collections.ObjectModel.ObservableCollection[PSObject]]::new()
$Script:TopAllowed = [System.Collections.ObjectModel.ObservableCollection[PSObject]]::new()
$Script:FeedData = [System.Collections.ObjectModel.ObservableCollection[PSObject]]::new()

$Script:IsConnected = $false
$Script:SSHSession = $null
$Script:RefreshTimer = $null
$Script:LiveStreamTimer = $null
$Script:LastLogPosition = @{ DNSBL = 0; DNSReply = 0; IPBlock = 0 }
$Script:ConnectionInfo = @{ TargetHost = ""; Port = 22; User = ""; Password = "" }

# Bind collections
$dgLogs.ItemsSource = $Script:FilteredData
$dgIPLogs.ItemsSource = $Script:IPLogData
$lstWhitelist.ItemsSource = $Script:WhitelistData
$lstBlocklist.ItemsSource = $Script:BlocklistData
$lstLiveLog.ItemsSource = $Script:LiveLogData
$lstAlertRules.ItemsSource = $Script:AlertRules
$lstTriggeredAlerts.ItemsSource = $Script:TriggeredAlerts
$dgClientStats.ItemsSource = $Script:ClientStats
$dgTopBlocked.ItemsSource = $Script:TopBlocked
$dgTopAllowed.ItemsSource = $Script:TopAllowed
$dgFeeds.ItemsSource = $Script:FeedData

# ============================================================================
# SETTINGS MANAGEMENT
# ============================================================================

function Save-AppSettings {
    try {
        $dir = Split-Path $Script:Config.SettingsPath -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $Script:Settings | ConvertTo-Json | Set-Content $Script:Config.SettingsPath
    } catch {}
}

function Load-AppSettings {
    try {
        if (Test-Path $Script:Config.SettingsPath) {
            $loaded = Get-Content $Script:Config.SettingsPath -Raw | ConvertFrom-Json
            $Script:Settings = @{
                Theme = if ($loaded.Theme) { $loaded.Theme } else { "Dark" }
                VisibleTabs = if ($loaded.VisibleTabs) { $loaded.VisibleTabs } else { $Script:DefaultSettings.VisibleTabs }
                LiveMonitorMax = if ($loaded.LiveMonitorMax) { $loaded.LiveMonitorMax } else { 500 }
                AutoRefreshOnTabChange = if ($null -ne $loaded.AutoRefreshOnTabChange) { $loaded.AutoRefreshOnTabChange } else { $true }
            }
        }
    } catch { $Script:Settings = $Script:DefaultSettings.Clone() }
}

function Apply-Settings {
    # Apply tab visibility
    $tabLiveMonitor.Visibility = if ($Script:Settings.VisibleTabs -contains "LiveMonitor") { "Visible" } else { "Collapsed" }
    $tabDNSLogs.Visibility = if ($Script:Settings.VisibleTabs -contains "DNSLogs") { "Visible" } else { "Collapsed" }
    $tabIPBlocking.Visibility = if ($Script:Settings.VisibleTabs -contains "IPBlocking") { "Visible" } else { "Collapsed" }
    $tabListEditor.Visibility = if ($Script:Settings.VisibleTabs -contains "ListEditor") { "Visible" } else { "Collapsed" }
    $tabStatistics.Visibility = if ($Script:Settings.VisibleTabs -contains "Statistics") { "Visible" } else { "Collapsed" }
    $tabDNSLookup.Visibility = if ($Script:Settings.VisibleTabs -contains "DNSLookup") { "Visible" } else { "Collapsed" }
    $tabAlerts.Visibility = if ($Script:Settings.VisibleTabs -contains "Alerts") { "Visible" } else { "Collapsed" }
    $tabFeeds.Visibility = if ($Script:Settings.VisibleTabs -contains "Feeds") { "Visible" } else { "Collapsed" }
    $tabSystem.Visibility = if ($Script:Settings.VisibleTabs -contains "System") { "Visible" } else { "Collapsed" }
    
    $txtLiveMax.Text = $Script:Settings.LiveMonitorMax.ToString()
}

function Show-SettingsWindow {
    $settingsReader = New-Object System.Xml.XmlNodeReader $SettingsXAML
    $settingsWindow = [Windows.Markup.XamlReader]::Load($settingsReader)
    
    # Get controls
    $cmbTheme = $settingsWindow.FindName("cmbTheme")
    $chkTabLiveMonitor = $settingsWindow.FindName("chkTabLiveMonitor")
    $chkTabDNSLogs = $settingsWindow.FindName("chkTabDNSLogs")
    $chkTabIPBlocking = $settingsWindow.FindName("chkTabIPBlocking")
    $chkTabListEditor = $settingsWindow.FindName("chkTabListEditor")
    $chkTabStatistics = $settingsWindow.FindName("chkTabStatistics")
    $chkTabDNSLookup = $settingsWindow.FindName("chkTabDNSLookup")
    $chkTabAlerts = $settingsWindow.FindName("chkTabAlerts")
    $chkTabFeeds = $settingsWindow.FindName("chkTabFeeds")
    $chkTabSystem = $settingsWindow.FindName("chkTabSystem")
    $chkAutoRefreshTab = $settingsWindow.FindName("chkAutoRefreshTab")
    $txtSettingsLiveMax = $settingsWindow.FindName("txtSettingsLiveMax")
    $btnSettingsSave = $settingsWindow.FindName("btnSettingsSave")
    $btnSettingsCancel = $settingsWindow.FindName("btnSettingsCancel")
    
    # Load current settings
    $cmbTheme.SelectedIndex = if ($Script:Settings.Theme -eq "Light") { 1 } else { 0 }
    $chkTabLiveMonitor.IsChecked = $Script:Settings.VisibleTabs -contains "LiveMonitor"
    $chkTabDNSLogs.IsChecked = $Script:Settings.VisibleTabs -contains "DNSLogs"
    $chkTabIPBlocking.IsChecked = $Script:Settings.VisibleTabs -contains "IPBlocking"
    $chkTabListEditor.IsChecked = $Script:Settings.VisibleTabs -contains "ListEditor"
    $chkTabStatistics.IsChecked = $Script:Settings.VisibleTabs -contains "Statistics"
    $chkTabDNSLookup.IsChecked = $Script:Settings.VisibleTabs -contains "DNSLookup"
    $chkTabAlerts.IsChecked = $Script:Settings.VisibleTabs -contains "Alerts"
    $chkTabFeeds.IsChecked = $Script:Settings.VisibleTabs -contains "Feeds"
    $chkTabSystem.IsChecked = $Script:Settings.VisibleTabs -contains "System"
    $chkAutoRefreshTab.IsChecked = $Script:Settings.AutoRefreshOnTabChange
    $txtSettingsLiveMax.Text = $Script:Settings.LiveMonitorMax.ToString()
    
    $btnSettingsSave.Add_Click({
        $tabs = @()
        if ($chkTabLiveMonitor.IsChecked) { $tabs += "LiveMonitor" }
        if ($chkTabDNSLogs.IsChecked) { $tabs += "DNSLogs" }
        if ($chkTabIPBlocking.IsChecked) { $tabs += "IPBlocking" }
        if ($chkTabListEditor.IsChecked) { $tabs += "ListEditor" }
        if ($chkTabStatistics.IsChecked) { $tabs += "Statistics" }
        if ($chkTabDNSLookup.IsChecked) { $tabs += "DNSLookup" }
        if ($chkTabAlerts.IsChecked) { $tabs += "Alerts" }
        if ($chkTabFeeds.IsChecked) { $tabs += "Feeds" }
        if ($chkTabSystem.IsChecked) { $tabs += "System" }
        
        $Script:Settings.Theme = if ($cmbTheme.SelectedIndex -eq 1) { "Light" } else { "Dark" }
        $Script:Settings.VisibleTabs = $tabs
        $Script:Settings.AutoRefreshOnTabChange = $chkAutoRefreshTab.IsChecked
        $Script:Settings.LiveMonitorMax = [int]$txtSettingsLiveMax.Text
        
        Save-AppSettings
        Apply-Settings
        $settingsWindow.Close()
    })
    
    $btnSettingsCancel.Add_Click({ $settingsWindow.Close() })
    
    $settingsWindow.Owner = $Window
    $settingsWindow.ShowDialog() | Out-Null
}

# ============================================================================
# CREDENTIAL MANAGEMENT
# ============================================================================

function Save-Credentials {
    param([string]$TargetHost, [int]$Port, [string]$User, [string]$Password)
    try {
        $dir = Split-Path $Script:Config.ConfigPath -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $enc = ConvertFrom-SecureString (ConvertTo-SecureString $Password -AsPlainText -Force)
        @{ TargetHost=$TargetHost; Port=$Port; User=$User; EncryptedPassword=$enc } | ConvertTo-Json | Set-Content $Script:Config.ConfigPath
    } catch {}
}

function Load-Credentials {
    try {
        if (Test-Path $Script:Config.ConfigPath) {
            $d = Get-Content $Script:Config.ConfigPath -Raw | ConvertFrom-Json
            $sec = ConvertTo-SecureString $d.EncryptedPassword
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
            $pass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
            return @{ TargetHost=$d.TargetHost; Port=$d.Port; User=$d.User; Password=$pass }
        }
    } catch {}
    return $null
}

function Save-AlertRules { try { $Script:AlertRules | ConvertTo-Json | Set-Content $Script:Config.AlertsPath } catch {} }
function Load-AlertRules {
    try {
        if (Test-Path $Script:Config.AlertsPath) {
            Get-Content $Script:Config.AlertsPath -Raw | ConvertFrom-Json | ForEach-Object { $Script:AlertRules.Add($_) }
        }
    } catch {}
}

# ============================================================================
# SSH FUNCTIONS
# ============================================================================

function Install-PoshSSH {
    if (Get-Module -ListAvailable -Name Posh-SSH) { return $true }
    $r = [System.Windows.MessageBox]::Show("Posh-SSH required. Install now?", "Install", [System.Windows.MessageBoxButton]::YesNo)
    if ($r -eq [System.Windows.MessageBoxResult]::Yes) {
        try {
            Install-Module -Name Posh-SSH -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            return $true
        } catch { [System.Windows.MessageBox]::Show("Failed: $_", "Error") }
    }
    return $false
}

function Test-SSHAvailable {
    if (Get-Module -ListAvailable -Name Posh-SSH) { return @{ Available=$true } }
    return @{ Available=$false }
}

function Run-SSHCommand {
    param([string]$Command, [string]$TargetHost, [int]$Port=22, [string]$User, [string]$Password)
    try {
        Import-Module Posh-SSH -ErrorAction Stop
        $sec = ConvertTo-SecureString $Password -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($User, $sec)
        if (-not $Script:SSHSession -or -not $Script:SSHSession.Connected) {
            Get-SSHSession | Remove-SSHSession -ErrorAction SilentlyContinue | Out-Null
            $Script:SSHSession = New-SSHSession -ComputerName $TargetHost -Port $Port -Credential $cred -AcceptKey -Force -ErrorAction Stop
        }
        $result = Invoke-SSHCommand -SSHSession $Script:SSHSession -Command $Command -ErrorAction Stop
        return $result.Output
    } catch { throw "SSH failed: $_" }
}

function Connect-ToFirewall {
    param([string]$TargetHost, [int]$Port, [string]$User, [string]$Password)
    Update-Status "Connecting to $TargetHost..."
    $test = Run-SSHCommand -Command "echo 'ok'" -TargetHost $TargetHost -Port $Port -User $User -Password $Password
    if ($test -match "ok") {
        $Script:ConnectionInfo = @{ TargetHost=$TargetHost; Port=$Port; User=$User; Password=$Password }
        return $true
    }
    throw "Connection failed"
}

# ============================================================================
# PFBLOCKERNG WHITELIST/BLOCKLIST FUNCTIONS (FIXED)
# ============================================================================

function Add-ToDNSBLWhitelist {
    param([string]$Domain, [switch]$Reload)
    if (-not $Script:IsConnected) { throw "Not connected" }
    
    $Domain = $Domain.Trim().ToLower()
    # Handle wildcard format
    if ($Domain.StartsWith("*.")) { $Domain = $Domain.Substring(1) }
    elseif (-not $Domain.StartsWith(".")) { $Domain = ".$Domain" }
    
    Update-Status "Adding $Domain to DNSBL whitelist..."
    
    # Method 1: Use pfBlockerNG's PHP whitelist function (most reliable)
    $phpCmd = @"
/usr/local/bin/php -r "
require_once('/usr/local/pkg/pfblockerng/pfblockerng.inc');
\\\$domain = '$Domain';
// Add to suppression list (whitelist)
\\\$suppression = pfbng_get_config_path('installedpackages/pfblockerngdnsblsettings/config/0/suppression');
\\\$decoded = base64_decode(\\\$suppression);
if (strpos(\\\$decoded, \\\$domain) === false) {
    \\\$decoded .= \\\$domain . \"\\n\";
    pfbng_set_config_path('installedpackages/pfblockerngdnsblsettings/config/0/suppression', base64_encode(\\\$decoded));
    write_config('pfBlockerNG: Added domain to whitelist via Manager');
    echo 'ADDED';
} else {
    echo 'EXISTS';
}
"
"@
    
    try {
        $result = Run-SSHCommand -Command $phpCmd @Script:ConnectionInfo
        
        if ($result -match "ADDED" -or $result -match "EXISTS") {
            # Also add to Unbound immediately for instant effect
            $unboundCmd = "/usr/local/sbin/unbound-control local_zone_remove `"$($Domain.TrimStart('.'))`" 2>/dev/null; echo done"
            Run-SSHCommand -Command $unboundCmd @Script:ConnectionInfo
            
            if ($Reload) {
                # Reload DNSBL to apply changes
                Run-SSHCommand -Command "/usr/local/bin/php /usr/local/www/pfblockerng/pfblockerng.php cron dnsbl 2>&1" @Script:ConnectionInfo
            }
            
            return @{ Success = $true; Message = "Added $Domain to whitelist" }
        }
    }
    catch {
        # Fallback: Direct file method
        $fallbackCmd = "echo '$Domain' >> /var/db/pfblockerng/native/whitelist.txt 2>/dev/null && echo 'ADDED'"
        $result = Run-SSHCommand -Command $fallbackCmd @Script:ConnectionInfo
    }
    
    return @{ Success = $true; Message = "Whitelist updated" }
}

function Add-ToDNSBLBlocklist {
    param([string]$Domain, [switch]$Reload)
    if (-not $Script:IsConnected) { throw "Not connected" }
    
    $Domain = $Domain.Trim().ToLower()
    if ($Domain.StartsWith("*.")) { $Domain = "." + $Domain.Substring(2) }
    
    Update-Status "Adding $Domain to DNSBL blocklist..."
    
    # Method 1: Use pfBlockerNG's custom blocklist
    $phpCmd = @"
/usr/local/bin/php -r "
require_once('/usr/local/pkg/pfblockerng/pfblockerng.inc');
\\\$domain = '$Domain';
// Add to custom blocklist
\\\$custom = pfbng_get_config_path('installedpackages/pfblockerngdnsbl/config/0/custom');
\\\$decoded = base64_decode(\\\$custom);
if (strpos(\\\$decoded, \\\$domain) === false) {
    \\\$decoded .= \\\$domain . \"\\n\";
    pfbng_set_config_path('installedpackages/pfblockerngdnsbl/config/0/custom', base64_encode(\\\$decoded));
    write_config('pfBlockerNG: Added domain to blocklist via Manager');
    echo 'ADDED';
} else {
    echo 'EXISTS';
}
"
"@
    
    try {
        $result = Run-SSHCommand -Command $phpCmd @Script:ConnectionInfo
        
        if ($result -match "ADDED" -or $result -match "EXISTS") {
            # Add to Unbound immediately for instant effect
            $unboundCmd = "/usr/local/sbin/unbound-control local_zone `"$($Domain.TrimStart('.'))`" always_nxdomain 2>/dev/null; echo done"
            Run-SSHCommand -Command $unboundCmd @Script:ConnectionInfo
            
            if ($Reload) {
                Run-SSHCommand -Command "/usr/local/bin/php /usr/local/www/pfblockerng/pfblockerng.php cron dnsbl 2>&1" @Script:ConnectionInfo
            }
            
            return @{ Success = $true; Message = "Added $Domain to blocklist" }
        }
    }
    catch {
        # Fallback: Direct Unbound method
        $fallbackCmd = "/usr/local/sbin/unbound-control local_zone `"$($Domain.TrimStart('.'))`" always_nxdomain 2>/dev/null && echo 'ADDED'"
        Run-SSHCommand -Command $fallbackCmd @Script:ConnectionInfo
    }
    
    return @{ Success = $true; Message = "Blocklist updated" }
}

function Get-DNSBLWhitelist {
    if (-not $Script:IsConnected) { return @() }
    Update-Status "Fetching whitelist..."
    
    $entries = @()
    
    # Get from config.xml suppression list
    $phpCmd = @"
/usr/local/bin/php -r "
require_once('/etc/inc/config.inc');
\\\$suppression = config_get_path('installedpackages/pfblockerngdnsblsettings/config/0/suppression');
if (\\\$suppression) { echo base64_decode(\\\$suppression); }
"
"@
    
    try {
        $result = Run-SSHCommand -Command $phpCmd @Script:ConnectionInfo
        if ($result) {
            $result | ForEach-Object {
                $line = $_.Trim()
                if ($line -and -not $line.StartsWith("#")) {
                    $entries += $line
                }
            }
        }
    }
    catch {
        # Fallback: Try native whitelist file
        $result = Run-SSHCommand -Command "cat /var/db/pfblockerng/native/whitelist.txt 2>/dev/null" @Script:ConnectionInfo
        if ($result) {
            $result | ForEach-Object { if ($_.Trim()) { $entries += $_.Trim() } }
        }
    }
    
    return $entries | Sort-Object -Unique
}

function Get-DNSBLBlocklist {
    if (-not $Script:IsConnected) { return @() }
    Update-Status "Fetching blocklist..."
    
    $entries = @()
    
    # Get from config.xml custom blocklist
    $phpCmd = @"
/usr/local/bin/php -r "
require_once('/etc/inc/config.inc');
\\\$custom = config_get_path('installedpackages/pfblockerngdnsbl/config/0/custom');
if (\\\$custom) { echo base64_decode(\\\$custom); }
"
"@
    
    try {
        $result = Run-SSHCommand -Command $phpCmd @Script:ConnectionInfo
        if ($result) {
            $result | ForEach-Object {
                $line = $_.Trim()
                if ($line -and -not $line.StartsWith("#")) {
                    $entries += $line
                }
            }
        }
    }
    catch {}
    
    return $entries | Sort-Object -Unique
}

function Remove-FromDNSBLWhitelist {
    param([string]$Domain)
    if (-not $Script:IsConnected) { throw "Not connected" }
    
    $Domain = $Domain.Trim()
    $escapedDomain = [regex]::Escape($Domain)
    
    $phpCmd = @"
/usr/local/bin/php -r "
require_once('/usr/local/pkg/pfblockerng/pfblockerng.inc');
\\\$suppression = pfbng_get_config_path('installedpackages/pfblockerngdnsblsettings/config/0/suppression');
\\\$decoded = base64_decode(\\\$suppression);
\\\$lines = explode(\"\\n\", \\\$decoded);
\\\$newlines = array_filter(\\\$lines, function(\\\$l) { return trim(\\\$l) !== '$Domain'; });
pfbng_set_config_path('installedpackages/pfblockerngdnsblsettings/config/0/suppression', base64_encode(implode(\"\\n\", \\\$newlines)));
write_config('pfBlockerNG: Removed domain from whitelist via Manager');
echo 'REMOVED';
"
"@
    
    Run-SSHCommand -Command $phpCmd @Script:ConnectionInfo
    return @{ Success = $true; Message = "Removed $Domain" }
}

function Remove-FromDNSBLBlocklist {
    param([string]$Domain)
    if (-not $Script:IsConnected) { throw "Not connected" }
    
    $phpCmd = @"
/usr/local/bin/php -r "
require_once('/usr/local/pkg/pfblockerng/pfblockerng.inc');
\\\$custom = pfbng_get_config_path('installedpackages/pfblockerngdnsbl/config/0/custom');
\\\$decoded = base64_decode(\\\$custom);
\\\$lines = explode(\"\\n\", \\\$decoded);
\\\$newlines = array_filter(\\\$lines, function(\\\$l) { return trim(\\\$l) !== '$Domain'; });
pfbng_set_config_path('installedpackages/pfblockerngdnsbl/config/0/custom', base64_encode(implode(\"\\n\", \\\$newlines)));
write_config('pfBlockerNG: Removed domain from blocklist via Manager');
echo 'REMOVED';
"
"@
    
    Run-SSHCommand -Command $phpCmd @Script:ConnectionInfo
    
    # Also remove from Unbound
    Run-SSHCommand -Command "/usr/local/sbin/unbound-control local_zone_remove `"$($Domain.TrimStart('.'))`" 2>/dev/null" @Script:ConnectionInfo
    
    return @{ Success = $true; Message = "Removed $Domain" }
}

# ============================================================================
# LOG PARSING FUNCTIONS
# ============================================================================

function Parse-DNSBLLine {
    param([string]$Line)
    if ([string]::IsNullOrWhiteSpace($Line)) { return $null }
    $p = $Line -split ','
    if ($p.Count -lt 5) { return $null }
    try {
        return [PSCustomObject]@{
            Type="BLOCKED"; Timestamp=$p[1].Trim(); Domain=$p[2].Trim()
            ClientIP=$p[3].Trim(); ResolvedIP="10.10.10.1"
            Feed=if($p.Count -gt 8){$p[8].Trim()}else{"DNSBL"}
            RawType="DNSBL"; RawLine=$Line
        }
    } catch { return $null }
}

function Parse-DNSReplyLine {
    param([string]$Line)
    if ([string]::IsNullOrWhiteSpace($Line)) { return $null }
    $p = $Line -split ','
    if ($p.Count -lt 8) { return $null }
    try {
        return [PSCustomObject]@{
            Type="ALLOWED"; Timestamp=$p[1].Trim()
            Domain=if($p.Count -gt 6){$p[6].Trim()}else{$p[2].Trim()}
            ClientIP=if($p.Count -gt 7){$p[7].Trim()}else{"-"}
            ResolvedIP=if($p.Count -gt 8){$p[8].Trim()}else{"-"}
            Feed="DNS Reply"; RawType="DNSReply"; RawLine=$Line
        }
    } catch { return $null }
}

function Parse-IPBlockLine {
    param([string]$Line)
    if ([string]::IsNullOrWhiteSpace($Line)) { return $null }
    # Format: timestamp,rule,interface,reason,action,direction,version,proto,src,dst,srcport,dstport,feed
    $p = $Line -split ','
    if ($p.Count -lt 10) { return $null }
    try {
        return [PSCustomObject]@{
            Timestamp = $p[0].Trim()
            Direction = if ($p.Count -gt 5) { $p[5].Trim() } else { "-" }
            SourceIP = if ($p.Count -gt 8) { $p[8].Trim() } else { "-" }
            DestIP = if ($p.Count -gt 9) { $p[9].Trim() } else { "-" }
            Port = if ($p.Count -gt 11) { $p[11].Trim() } else { "-" }
            Protocol = if ($p.Count -gt 7) { $p[7].Trim() } else { "-" }
            Feed = if ($p.Count -gt 12) { $p[12].Trim() } else { "IP Block" }
            Country = "-"
            RawType = "IPBlock"
            RawLine = $Line
        }
    } catch { return $null }
}

function Get-DNSLogs {
    param([string]$LogType="All", [int]$MaxLines=10000)
    if (-not $Script:IsConnected) { return @() }
    $logs = @()
    if ($MaxLines -gt $Script:Config.MaxLogLines) { $MaxLines = $Script:Config.MaxLogLines }
    
    if ($LogType -eq "All" -or $LogType -eq "DNSBL") {
        Update-Status "Fetching blocked logs..."
        $raw = Run-SSHCommand -Command "tail -n $MaxLines $($Script:Config.DNSBLLogPath) 2>/dev/null" @Script:ConnectionInfo
        if ($raw) { $raw | ForEach-Object { $p = Parse-DNSBLLine $_; if ($p) { $logs += $p } } }
    }
    
    if ($LogType -eq "All" -or $LogType -eq "DNSReply") {
        Update-Status "Fetching allowed logs..."
        $raw = Run-SSHCommand -Command "tail -n $MaxLines $($Script:Config.DNSReplyLogPath) 2>/dev/null" @Script:ConnectionInfo
        if ($raw) { $raw | ForEach-Object { $p = Parse-DNSReplyLine $_; if ($p) { $logs += $p } } }
    }
    
    return $logs | Sort-Object { try { [DateTime]::Parse($_.Timestamp) } catch { [DateTime]::MinValue } } -Descending
}

function Get-IPLogs {
    param([int]$MaxLines=5000)
    if (-not $Script:IsConnected) { return @() }
    
    Update-Status "Fetching IP block logs..."
    $logs = @()
    
    $raw = Run-SSHCommand -Command "tail -n $MaxLines $($Script:Config.IPBlockLogPath) 2>/dev/null" @Script:ConnectionInfo
    if ($raw) { $raw | ForEach-Object { $p = Parse-IPBlockLine $_; if ($p) { $logs += $p } } }
    
    return $logs | Sort-Object { try { [DateTime]::Parse($_.Timestamp) } catch { [DateTime]::MinValue } } -Descending
}

# ============================================================================
# STATS FUNCTIONS
# ============================================================================

function Get-ClientStats {
    Update-Status "Calculating statistics..."
    $Script:ClientStats.Clear()
    $Script:TopBlocked.Clear()
    $Script:TopAllowed.Clear()
    
    $clients = @{}
    $Script:LogData | ForEach-Object {
        $ip = $_.ClientIP
        if (-not $clients.ContainsKey($ip)) { $clients[$ip] = @{ Total=0; Blocked=0; Allowed=0 } }
        $clients[$ip].Total++
        if ($_.RawType -eq "DNSBL") { $clients[$ip].Blocked++ } else { $clients[$ip].Allowed++ }
    }
    
    $clients.GetEnumerator() | Sort-Object { $_.Value.Total } -Descending | ForEach-Object {
        $pct = if ($_.Value.Total -gt 0) { [math]::Round(($_.Value.Blocked / $_.Value.Total) * 100, 1) } else { 0 }
        $Script:ClientStats.Add([PSCustomObject]@{
            ClientIP=$_.Key; Total=$_.Value.Total; Blocked=$_.Value.Blocked
            Allowed=$_.Value.Allowed; BlockPercent="$pct%"
        })
    }
    
    $Script:LogData | Where-Object { $_.RawType -eq "DNSBL" } | Group-Object Domain | 
        Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
            $Script:TopBlocked.Add([PSCustomObject]@{ Domain=$_.Name; Count=$_.Count })
        }
    
    $Script:LogData | Where-Object { $_.RawType -eq "DNSReply" } | Group-Object Domain | 
        Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
            $Script:TopAllowed.Add([PSCustomObject]@{ Domain=$_.Name; Count=$_.Count })
        }
    
    $total = $Script:LogData.Count
    $blocked = ($Script:LogData | Where-Object { $_.RawType -eq "DNSBL" }).Count
    $allowed = $total - $blocked
    $rate = if ($total -gt 0) { [math]::Round(($blocked / $total) * 100, 1) } else { 0 }
    
    $txtStatTotal.Text = $total.ToString("N0")
    $txtStatBlocked.Text = $blocked.ToString("N0")
    $txtStatAllowed.Text = $allowed.ToString("N0")
    $txtStatBlockRate.Text = "$rate%"
    $txtStatClients.Text = $clients.Count.ToString()
}

function Get-SystemStats {
    if (-not $Script:IsConnected) { return }
    Update-Status "Fetching system stats..."
    try {
        $dnsbl = Run-SSHCommand -Command "wc -l /var/db/pfblockerng/DNSBL/*.txt 2>/dev/null | tail -1 | awk '{print `$1}'" @Script:ConnectionInfo
        $txtSysDNSBL.Text = if ($dnsbl) { $dnsbl.Trim() } else { "0" }
        
        $ip = Run-SSHCommand -Command "pfctl -t pfB_PRI1_v4 -T show 2>/dev/null | wc -l" @Script:ConnectionInfo
        $txtSysIP.Text = if ($ip) { $ip.Trim() } else { "0" }
        
        $today = Get-Date -Format "MMM  d"
        $todayAlt = Get-Date -Format "MMM d"
        $blocks = Run-SSHCommand -Command "grep -c '$today\|$todayAlt' /var/log/pfblockerng/dnsbl.log 2>/dev/null || echo 0" @Script:ConnectionInfo
        $txtSysToday.Text = if ($blocks) { $blocks.Trim() } else { "0" }
        
        $whiteCount = (Get-DNSBLWhitelist).Count
        $txtSysWhite.Text = $whiteCount.ToString()
        
        $blockCount = (Get-DNSBLBlocklist).Count
        $txtSysBlock.Text = $blockCount.ToString()
    } catch {}
}

function Get-IPStats {
    if (-not $Script:IsConnected) { return }
    
    $total = $Script:IPLogData.Count
    $inbound = ($Script:IPLogData | Where-Object { $_.Direction -eq "in" }).Count
    $outbound = $total - $inbound
    
    $txtIPTotalBlocks.Text = $total.ToString("N0")
    $txtIPInbound.Text = $inbound.ToString("N0")
    $txtIPOutbound.Text = $outbound.ToString("N0")
    
    # Count IP tables
    $tables = Run-SSHCommand -Command "pfctl -s Tables 2>/dev/null | grep -c pfB" @Script:ConnectionInfo
    $txtIPTables.Text = if ($tables) { $tables.Trim() } else { "0" }
}

function Get-FeedInfo {
    if (-not $Script:IsConnected) { return }
    Update-Status "Fetching feed information..."
    $Script:FeedData.Clear()
    
    try {
        $files = Run-SSHCommand -Command "ls -la /var/db/pfblockerng/DNSBL/*.txt 2>/dev/null | head -30" @Script:ConnectionInfo
        $files | ForEach-Object {
            if ($_ -match '(\d+)\s+(\w+\s+\d+\s+[\d:]+)\s+(.+\.txt)$') {
                $size = $Matches[1]
                $date = $Matches[2]
                $file = Split-Path $Matches[3] -Leaf
                $name = $file -replace '\.txt$', ''
                
                $Script:FeedData.Add([PSCustomObject]@{
                    Name = $name; Entries = $size; Updated = $date; File = $file
                })
            }
        }
    } catch {}
}

# ============================================================================
# FIREWALL ACTIONS
# ============================================================================

function Invoke-ReloadDNSBL {
    Update-Status "Reloading DNSBL..."
    Run-SSHCommand -Command "/usr/local/bin/php /usr/local/www/pfblockerng/pfblockerng.php cron dnsbl 2>&1" @Script:ConnectionInfo
    Update-Status "DNSBL reloaded"
}

function Invoke-ForceUpdate {
    Update-Status "Starting force update..."
    Run-SSHCommand -Command "/usr/local/bin/php /usr/local/www/pfblockerng/pfblockerng.php update 2>&1" @Script:ConnectionInfo
    Update-Status "Force update complete"
}

function Invoke-ClearDNSCache {
    Update-Status "Clearing DNS cache..."
    Run-SSHCommand -Command "/usr/local/sbin/unbound-control flush_zone . 2>&1" @Script:ConnectionInfo
    Update-Status "DNS cache cleared"
}

function Invoke-RestartDNS {
    Update-Status "Restarting DNS..."
    Run-SSHCommand -Command "/usr/local/sbin/pfSsh.php playback svc restart unbound 2>&1" @Script:ConnectionInfo
    Update-Status "DNS restarted"
}

function Invoke-RebootFirewall {
    Run-SSHCommand -Command "/sbin/shutdown -r now 2>&1" @Script:ConnectionInfo
    $Script:IsConnected = $false
    if ($Script:SSHSession) { try { Remove-SSHSession -SSHSession $Script:SSHSession -ErrorAction SilentlyContinue | Out-Null } catch {} }
    $Script:SSHSession = $null
    Update-ConnectionStatus -Connected $false
}

function Get-InstalledPackages {
    if (-not $Script:IsConnected) { return }
    $lstPackages.Items.Clear()
    $pkgs = Run-SSHCommand -Command "pkg info -a 2>/dev/null | grep -i 'pfsense\|pfblocker\|snort\|suricata\|squid\|openvpn\|ntop' | head -20" @Script:ConnectionInfo
    if ($pkgs) { $pkgs | ForEach-Object { $lstPackages.Items.Add($_) } }
}

# ============================================================================
# DNS LOOKUP
# ============================================================================

function Test-DomainBlock {
    param([string]$Domain)
    if (-not $Script:IsConnected) { return }
    
    Update-Status "Testing domain: $Domain"
    $txtLookupResults.Text = ""
    
    try {
        # Check whitelist
        $white = Get-DNSBLWhitelist
        $isWhitelisted = $white | Where-Object { $Domain -like "*$($_)" -or $_ -like "*$Domain*" }
        if ($isWhitelisted) {
            $txtLookupStatus.Text = "WHITELISTED"
            $txtLookupStatus.Foreground = [System.Windows.Media.Brushes]::LimeGreen
            $txtLookupFeed.Text = "Custom Whitelist"
            $txtLookupResults.Text = "Domain matches whitelist entry: $isWhitelisted"
            return
        }
        
        # Check custom blocklist
        $block = Get-DNSBLBlocklist
        $isBlocked = $block | Where-Object { $Domain -like "*$($_)" -or $_ -like "*$Domain*" }
        if ($isBlocked) {
            $txtLookupStatus.Text = "BLOCKED"
            $txtLookupStatus.Foreground = [System.Windows.Media.Brushes]::Red
            $txtLookupFeed.Text = "Custom Blocklist"
            $txtLookupResults.Text = "Domain matches blocklist entry: $isBlocked"
            return
        }
        
        # Check DNSBL feeds
        $dnsbl = Run-SSHCommand -Command "grep -ri '$Domain' /var/db/pfblockerng/DNSBL/*.txt 2>/dev/null | head -5" @Script:ConnectionInfo
        if ($dnsbl) {
            $txtLookupStatus.Text = "BLOCKED"
            $txtLookupStatus.Foreground = [System.Windows.Media.Brushes]::Red
            $feed = if ($dnsbl -match '/([^/]+)\.txt:') { $Matches[1] } else { "DNSBL Feed" }
            $txtLookupFeed.Text = $feed
            $txtLookupResults.Text = "Domain found in DNSBL feeds:`n$($dnsbl -join "`n")"
            return
        }
        
        # Resolve
        $resolve = Run-SSHCommand -Command "drill $Domain @127.0.0.1 2>/dev/null | grep -A5 'ANSWER SECTION' | head -6" @Script:ConnectionInfo
        $ip = if ($resolve -match '\s+IN\s+A\s+([\d\.]+)') { $Matches[1] } else { "Could not resolve" }
        
        $txtLookupStatus.Text = "NOT BLOCKED"
        $txtLookupStatus.Foreground = [System.Windows.Media.Brushes]::LimeGreen
        $txtLookupFeed.Text = "-"
        $txtLookupIP.Text = $ip
        $txtLookupResults.Text = "Domain is not in any blocklist.`n`nDNS Resolution:`n$resolve"
        
    } catch { $txtLookupResults.Text = "Error: $_" }
}

# ============================================================================
# LIVE MONITOR FUNCTIONS
# ============================================================================

function Start-LiveMonitor {
    if (-not $Script:IsConnected) { return }
    $Script:LastLogPosition = @{ DNSBL=0; DNSReply=0; IPBlock=0 }
    
    try {
        $dc = Run-SSHCommand -Command "wc -l < $($Script:Config.DNSBLLogPath) 2>/dev/null || echo 0" @Script:ConnectionInfo
        $rc = Run-SSHCommand -Command "wc -l < $($Script:Config.DNSReplyLogPath) 2>/dev/null || echo 0" @Script:ConnectionInfo
        $ic = Run-SSHCommand -Command "wc -l < $($Script:Config.IPBlockLogPath) 2>/dev/null || echo 0" @Script:ConnectionInfo
        $Script:LastLogPosition.DNSBL = [int]($dc.Trim())
        $Script:LastLogPosition.DNSReply = [int]($rc.Trim())
        $Script:LastLogPosition.IPBlock = [int]($ic.Trim())
    } catch {}
    
    $Script:LiveStreamTimer = New-Object System.Windows.Threading.DispatcherTimer
    $Script:LiveStreamTimer.Interval = [TimeSpan]::FromSeconds($Script:Config.LiveStreamInterval)
    $Script:LiveStreamTimer.Add_Tick({ Get-LiveUpdates })
    $Script:LiveStreamTimer.Start()
    Update-Status "Live monitor started"
}

function Stop-LiveMonitor {
    if ($Script:LiveStreamTimer) { $Script:LiveStreamTimer.Stop(); $Script:LiveStreamTimer = $null }
    Update-Status "Live monitor stopped"
}

function Get-LiveUpdates {
    if (-not $Script:IsConnected) { return }
    try {
        $filter = $txtLiveFilter.Text.Trim()
        $max = [int]$txtLiveMax.Text
        
        # DNS Blocked
        if ($chkLiveBlocked.IsChecked) {
            $nc = Run-SSHCommand -Command "wc -l < $($Script:Config.DNSBLLogPath) 2>/dev/null || echo 0" @Script:ConnectionInfo
            $nc = [int]($nc.Trim())
            if ($nc -gt $Script:LastLogPosition.DNSBL) {
                $diff = $nc - $Script:LastLogPosition.DNSBL
                $new = Run-SSHCommand -Command "tail -n $diff $($Script:Config.DNSBLLogPath) 2>/dev/null" @Script:ConnectionInfo
                if ($new) {
                    $new | ForEach-Object {
                        $p = Parse-DNSBLLine $_
                        if ($p -and ([string]::IsNullOrWhiteSpace($filter) -or $p.Domain -like "*$filter*")) {
                            $entry = "[DNS-BLOCKED] $($p.Timestamp) | $($p.Domain) | $($p.ClientIP)"
                            $Script:LiveLogData.Insert(0, $entry)
                            Check-AlertRules $p
                        }
                    }
                }
                $Script:LastLogPosition.DNSBL = $nc
            }
        }
        
        # DNS Allowed
        if ($chkLiveAllowed.IsChecked) {
            $nc = Run-SSHCommand -Command "wc -l < $($Script:Config.DNSReplyLogPath) 2>/dev/null || echo 0" @Script:ConnectionInfo
            $nc = [int]($nc.Trim())
            if ($nc -gt $Script:LastLogPosition.DNSReply) {
                $diff = $nc - $Script:LastLogPosition.DNSReply
                $new = Run-SSHCommand -Command "tail -n $diff $($Script:Config.DNSReplyLogPath) 2>/dev/null" @Script:ConnectionInfo
                if ($new) {
                    $new | ForEach-Object {
                        $p = Parse-DNSReplyLine $_
                        if ($p -and ([string]::IsNullOrWhiteSpace($filter) -or $p.Domain -like "*$filter*")) {
                            $entry = "[DNS-ALLOWED] $($p.Timestamp) | $($p.Domain) | $($p.ClientIP)"
                            $Script:LiveLogData.Insert(0, $entry)
                            Check-AlertRules $p
                        }
                    }
                }
                $Script:LastLogPosition.DNSReply = $nc
            }
        }
        
        # IP Blocks
        if ($chkLiveIP.IsChecked) {
            $nc = Run-SSHCommand -Command "wc -l < $($Script:Config.IPBlockLogPath) 2>/dev/null || echo 0" @Script:ConnectionInfo
            $nc = [int]($nc.Trim())
            if ($nc -gt $Script:LastLogPosition.IPBlock) {
                $diff = $nc - $Script:LastLogPosition.IPBlock
                $new = Run-SSHCommand -Command "tail -n $diff $($Script:Config.IPBlockLogPath) 2>/dev/null" @Script:ConnectionInfo
                if ($new) {
                    $new | ForEach-Object {
                        $p = Parse-IPBlockLine $_
                        if ($p -and ([string]::IsNullOrWhiteSpace($filter) -or $p.SourceIP -like "*$filter*" -or $p.DestIP -like "*$filter*")) {
                            $entry = "[IP-BLOCK] $($p.Timestamp) | $($p.Direction) | $($p.SourceIP) -> $($p.DestIP):$($p.Port)"
                            $Script:LiveLogData.Insert(0, $entry)
                        }
                    }
                }
                $Script:LastLogPosition.IPBlock = $nc
            }
        }
        
        while ($Script:LiveLogData.Count -gt $max) { $Script:LiveLogData.RemoveAt($Script:LiveLogData.Count - 1) }
    } catch {}
}

function Get-SelectedLiveEntry {
    $selected = $lstLiveLog.SelectedItem
    if (-not $selected) { return $null }
    
    # Parse the selected line to extract domain and IP
    $result = @{ Domain = ""; IP = "" }
    
    if ($selected -match '\|\s*([a-zA-Z0-9][-a-zA-Z0-9.]+\.[a-zA-Z]{2,})\s*\|') {
        $result.Domain = $Matches[1]
    }
    if ($selected -match '\|\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') {
        $result.IP = $Matches[1]
    }
    
    return $result
}

# ============================================================================
# ALERT FUNCTIONS
# ============================================================================

function Check-AlertRules {
    param($Entry)
    if (-not $chkAlertMonitor.IsChecked) { return }
    
    foreach ($rule in $Script:AlertRules) {
        $match = $false
        if ($rule.Type -eq "Any" -or ($rule.Type -eq "Blocked" -and $Entry.RawType -eq "DNSBL") -or ($rule.Type -eq "Allowed" -and $Entry.RawType -eq "DNSReply")) {
            $pattern = $rule.Pattern -replace '\*', '.*'
            if ($Entry.Domain -match $pattern) { $match = $true }
        }
        
        if ($match) {
            $alert = "[$(Get-Date -Format 'HH:mm:ss')] $($Entry.Type): $($Entry.Domain) from $($Entry.ClientIP)"
            $Script:TriggeredAlerts.Insert(0, $alert)
            $txtAlertCount.Text = " ($($Script:TriggeredAlerts.Count))"
            $txtActiveAlerts.Text = $Script:TriggeredAlerts.Count.ToString()
            
            if ($chkAlertSound.IsChecked) { [System.Media.SystemSounds]::Exclamation.Play() }
            if ($chkAlertPopup.IsChecked) {
                [System.Windows.MessageBox]::Show("Alert: $($Entry.Domain)`nType: $($Entry.Type)`nClient: $($Entry.ClientIP)", "Domain Alert", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            }
        }
    }
}

# ============================================================================
# BACKUP/RESTORE
# ============================================================================

function Backup-Lists {
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "JSON|*.json"
    $dlg.FileName = "pfblockerng_lists_$(Get-Date -Format 'yyyyMMdd').json"
    
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $backup = @{
                Whitelist = Get-DNSBLWhitelist
                Blocklist = Get-DNSBLBlocklist
                ExportDate = (Get-Date).ToString("o")
            }
            $backup | ConvertTo-Json | Set-Content $dlg.FileName
            [System.Windows.MessageBox]::Show("Backup saved!", "Complete")
        } catch { [System.Windows.MessageBox]::Show("Error: $_", "Failed") }
    }
}

function Restore-Lists {
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "JSON|*.json"
    
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $confirm = [System.Windows.MessageBox]::Show("This will ADD to your current lists. Continue?", "Confirm", [System.Windows.MessageBoxButton]::YesNo)
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
        
        try {
            $backup = Get-Content $dlg.FileName -Raw | ConvertFrom-Json
            
            $backup.Whitelist | ForEach-Object { Add-ToDNSBLWhitelist -Domain $_ }
            $backup.Blocklist | ForEach-Object { Add-ToDNSBLBlocklist -Domain $_ }
            
            Invoke-ReloadDNSBL
            Refresh-Lists
            
            [System.Windows.MessageBox]::Show("Restore complete!", "Complete")
        } catch { [System.Windows.MessageBox]::Show("Error: $_", "Failed") }
    }
}

# ============================================================================
# UI HELPERS
# ============================================================================

function Update-Status { param([string]$Msg); $Window.Dispatcher.Invoke([Action]{ $txtStatusMessage.Text = $Msg }) }

function Update-ConnectionStatus {
    param([bool]$Connected)
    $Window.Dispatcher.Invoke([Action]{
        if ($Connected) {
            $StatusIndicator.Fill = [System.Windows.Media.Brushes]::LimeGreen
            $StatusText.Text = "Connected to $($Script:ConnectionInfo.TargetHost)"
            $btnConnect.Content = "Disconnect"
        } else {
            $StatusIndicator.Fill = "#ff6b6b"
            $StatusText.Text = "Disconnected"
            $btnConnect.Content = "Connect"
        }
    })
}

function Update-Counts {
    $total = $Script:FilteredData.Count
    $blocked = ($Script:FilteredData | Where-Object { $_.RawType -eq "DNSBL" }).Count
    $txtTotalCount.Text = $total.ToString("N0")
    $txtBlockedCount.Text = $blocked.ToString("N0")
    $txtAllowedCount.Text = ($total - $blocked).ToString("N0")
}

function Apply-LogFilter {
    $search = $txtLogFilter.Text.ToLower()
    $type = $cmbLogType.SelectedIndex
    $Script:FilteredData.Clear()
    
    $Script:LogData | ForEach-Object {
        $inc = $true
        if ($type -eq 1 -and $_.RawType -ne "DNSBL") { $inc = $false }
        if ($type -eq 2 -and $_.RawType -ne "DNSReply") { $inc = $false }
        if ($inc -and $search) { $inc = $_.Domain -like "*$search*" -or $_.ClientIP -like "*$search*" }
        if ($inc) { $Script:FilteredData.Add($_) }
    }
    Update-Counts
}

function Refresh-Logs {
    if (-not $Script:IsConnected) { return }
    try {
        $max = [int]$txtLogLines.Text
        $logs = Get-DNSLogs -MaxLines $max
        $Window.Dispatcher.Invoke([Action]{
            $Script:LogData.Clear()
            $logs | ForEach-Object { $Script:LogData.Add($_) }
            Apply-LogFilter
            Update-Status "Loaded $($logs.Count) entries"
        })
    } catch { Update-Status "Error: $_" }
}

function Refresh-IPLogs {
    if (-not $Script:IsConnected) { return }
    try {
        $max = [int]$txtIPLines.Text
        $logs = Get-IPLogs -MaxLines $max
        $Script:IPLogData.Clear()
        $logs | ForEach-Object { $Script:IPLogData.Add($_) }
        Get-IPStats
        Update-Status "Loaded $($logs.Count) IP block entries"
    } catch { Update-Status "Error: $_" }
}

function Refresh-Lists {
    if (-not $Script:IsConnected) { return }
    try {
        $white = Get-DNSBLWhitelist
        $Script:WhitelistData.Clear()
        $white | ForEach-Object { $Script:WhitelistData.Add($_) }
        $txtWhitelistCount.Text = "$($Script:WhitelistData.Count) entries"
        
        $block = Get-DNSBLBlocklist
        $Script:BlocklistData.Clear()
        $block | ForEach-Object { $Script:BlocklistData.Add($_) }
        $txtBlocklistCount.Text = "$($Script:BlocklistData.Count) entries"
    } catch { Update-Status "Error loading lists: $_" }
}

# ============================================================================
# EVENT HANDLERS
# ============================================================================

$btnSettings.Add_Click({ Show-SettingsWindow })

$btnConnect.Add_Click({
    if ($Script:IsConnected) {
        $Script:IsConnected = $false
        if ($Script:SSHSession) { try { Remove-SSHSession -SSHSession $Script:SSHSession -ErrorAction SilentlyContinue | Out-Null } catch {} }
        $Script:SSHSession = $null
        Stop-LiveMonitor
        if ($Script:RefreshTimer) { $Script:RefreshTimer.Stop() }
        Update-ConnectionStatus -Connected $false
        Update-Status "Disconnected"
    } else {
        if (-not (Test-SSHAvailable).Available) { if (-not (Install-PoshSSH)) { return } }
        try {
            $btnConnect.IsEnabled = $false
            $result = Connect-ToFirewall -TargetHost $txtHost.Text -Port ([int]$txtPort.Text) -User $txtUser.Text -Password $txtPassword.Password
            if ($result) {
                $Script:IsConnected = $true
                Update-ConnectionStatus -Connected $true
                if ($chkSaveCredentials.IsChecked) { Save-Credentials -TargetHost $txtHost.Text -Port ([int]$txtPort.Text) -User $txtUser.Text -Password $txtPassword.Password }
                
                # Initial data load
                Refresh-Logs
                Refresh-IPLogs
                Refresh-Lists
                Get-SystemStats
            }
        } catch { [System.Windows.MessageBox]::Show("Failed: $_", "Error"); Update-Status "Failed" }
        finally { $btnConnect.IsEnabled = $true }
    }
})

# Tab change - refresh data
$MainTabs.Add_SelectionChanged({
    if (-not $Script:IsConnected -or -not $Script:Settings.AutoRefreshOnTabChange) { return }
    
    $selectedTab = $MainTabs.SelectedItem
    if (-not $selectedTab) { return }
    
    switch ($selectedTab.Header) {
        "Live Monitor" { }
        "DNS Logs" { Refresh-Logs }
        "IP Blocking" { Refresh-IPLogs }
        "List Editor" { Refresh-Lists }
        "Statistics" { Get-ClientStats }
        "Feeds" { Get-FeedInfo }
        "System" { Get-SystemStats; Get-InstalledPackages }
    }
})

# Live Monitor
$btnStartLive.Add_Click({ Start-LiveMonitor; $btnStartLive.IsEnabled = $false; $btnStopLive.IsEnabled = $true })
$btnStopLive.Add_Click({ Stop-LiveMonitor; $btnStartLive.IsEnabled = $true; $btnStopLive.IsEnabled = $false })
$btnClearLive.Add_Click({ $Script:LiveLogData.Clear() })

$btnLiveWhitelist.Add_Click({
    $entry = Get-SelectedLiveEntry
    if ($entry -and $entry.Domain) {
        $confirm = [System.Windows.MessageBox]::Show("Whitelist domain: $($entry.Domain)?", "Confirm", [System.Windows.MessageBoxButton]::YesNo)
        if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
            Add-ToDNSBLWhitelist -Domain $entry.Domain -Reload
            [System.Windows.MessageBox]::Show("Added to whitelist!", "Done")
        }
    } else { [System.Windows.MessageBox]::Show("Select an entry with a domain first", "No Selection") }
})

$btnLiveBlocklist.Add_Click({
    $entry = Get-SelectedLiveEntry
    if ($entry -and $entry.Domain) {
        $confirm = [System.Windows.MessageBox]::Show("Blocklist domain: $($entry.Domain)?", "Confirm", [System.Windows.MessageBoxButton]::YesNo)
        if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
            Add-ToDNSBLBlocklist -Domain $entry.Domain -Reload
            [System.Windows.MessageBox]::Show("Added to blocklist!", "Done")
        }
    } else { [System.Windows.MessageBox]::Show("Select an entry with a domain first", "No Selection") }
})

$btnLiveVirusTotal.Add_Click({
    $entry = Get-SelectedLiveEntry
    if ($entry -and $entry.Domain) { Start-Process "https://www.virustotal.com/gui/domain/$($entry.Domain)" }
    elseif ($entry -and $entry.IP) { Start-Process "https://www.virustotal.com/gui/ip-address/$($entry.IP)" }
})

$btnLiveCopyDomain.Add_Click({
    $entry = Get-SelectedLiveEntry
    if ($entry -and $entry.Domain) { [System.Windows.Clipboard]::SetText($entry.Domain) }
})

$btnLiveCopyIP.Add_Click({
    $entry = Get-SelectedLiveEntry
    if ($entry -and $entry.IP) { [System.Windows.Clipboard]::SetText($entry.IP) }
})

# DNS Logs
$btnRefreshLogs.Add_Click({ Refresh-Logs })
$txtLogFilter.Add_TextChanged({ Apply-LogFilter })
$cmbLogType.Add_SelectionChanged({ Apply-LogFilter })
$btnExportLogs.Add_Click({
    if ($Script:FilteredData.Count -eq 0) { return }
    $dlg = New-Object System.Windows.Forms.SaveFileDialog; $dlg.Filter = "CSV|*.csv"; $dlg.FileName = "dns_logs_$(Get-Date -Format 'yyyyMMdd').csv"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $Script:FilteredData | Export-Csv $dlg.FileName -NoTypeInformation }
})

$btnWhitelistLog.Add_Click({
    $sel = $dgLogs.SelectedItems; if ($sel.Count -eq 0) { return }
    $domains = $sel | Select-Object -ExpandProperty Domain -Unique
    if ([System.Windows.MessageBox]::Show("Whitelist?`n$($domains -join "`n")", "Confirm", [System.Windows.MessageBoxButton]::YesNo) -eq [System.Windows.MessageBoxResult]::Yes) {
        $domains | ForEach-Object { Add-ToDNSBLWhitelist -Domain $_ }
        Invoke-ReloadDNSBL; Refresh-Lists
    }
})

$btnBlocklistLog.Add_Click({
    $sel = $dgLogs.SelectedItems; if ($sel.Count -eq 0) { return }
    $domains = $sel | Select-Object -ExpandProperty Domain -Unique
    if ([System.Windows.MessageBox]::Show("Blocklist?`n$($domains -join "`n")", "Confirm", [System.Windows.MessageBoxButton]::YesNo) -eq [System.Windows.MessageBoxResult]::Yes) {
        $domains | ForEach-Object { Add-ToDNSBLBlocklist -Domain $_ }
        Invoke-ReloadDNSBL; Refresh-Lists
    }
})

$btnReloadDNSBL.Add_Click({ try { Invoke-ReloadDNSBL } catch {} })
$btnForceUpdate.Add_Click({ try { Invoke-ForceUpdate } catch {} })
$btnClearCache.Add_Click({ try { Invoke-ClearDNSCache } catch {} })

$chkAutoRefresh.Add_Checked({
    if (-not $Script:RefreshTimer) {
        $Script:RefreshTimer = New-Object System.Windows.Threading.DispatcherTimer
        $Script:RefreshTimer.Interval = [TimeSpan]::FromSeconds($Script:Config.AutoRefreshInterval)
        $Script:RefreshTimer.Add_Tick({ Refresh-Logs })
    }
    $Script:RefreshTimer.Start()
})
$chkAutoRefresh.Add_Unchecked({ if ($Script:RefreshTimer) { $Script:RefreshTimer.Stop() } })

# Context menu
$ctxWhitelist.Add_Click({ $s = $dgLogs.SelectedItem; if ($s) { Add-ToDNSBLWhitelist -Domain $s.Domain -Reload; Refresh-Lists } })
$ctxBlocklist.Add_Click({ $s = $dgLogs.SelectedItem; if ($s) { Add-ToDNSBLBlocklist -Domain $s.Domain -Reload; Refresh-Lists } })
$ctxCopyDomain.Add_Click({ $s = $dgLogs.SelectedItem; if ($s) { [System.Windows.Clipboard]::SetText($s.Domain) } })
$ctxCopyIP.Add_Click({ $s = $dgLogs.SelectedItem; if ($s) { [System.Windows.Clipboard]::SetText($s.ClientIP) } })
$ctxVirusTotal.Add_Click({ $s = $dgLogs.SelectedItem; if ($s) { Start-Process "https://www.virustotal.com/gui/domain/$($s.Domain)" } })

# IP Blocking
$btnRefreshIPLogs.Add_Click({ Refresh-IPLogs })
$btnExportIPLogs.Add_Click({
    if ($Script:IPLogData.Count -eq 0) { return }
    $dlg = New-Object System.Windows.Forms.SaveFileDialog; $dlg.Filter = "CSV|*.csv"; $dlg.FileName = "ip_blocks_$(Get-Date -Format 'yyyyMMdd').csv"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $Script:IPLogData | Export-Csv $dlg.FileName -NoTypeInformation }
})

$ctxIPLookup.Add_Click({ $s = $dgIPLogs.SelectedItem; if ($s) { Start-Process "https://www.abuseipdb.com/check/$($s.SourceIP)" } })
$ctxIPCopy.Add_Click({ $s = $dgIPLogs.SelectedItem; if ($s) { [System.Windows.Clipboard]::SetText($s.SourceIP) } })

# List Editor
$btnWhitelistRefresh.Add_Click({ Refresh-Lists })
$btnBlocklistRefresh.Add_Click({ Refresh-Lists })
$btnWhitelistAdd.Add_Click({ $d = $txtWhitelistAdd.Text.Trim(); if ($d) { Add-ToDNSBLWhitelist -Domain $d -Reload; $txtWhitelistAdd.Text = ""; Refresh-Lists } })
$btnBlocklistAdd.Add_Click({ $d = $txtBlocklistAdd.Text.Trim(); if ($d) { Add-ToDNSBLBlocklist -Domain $d -Reload; $txtBlocklistAdd.Text = ""; Refresh-Lists } })
$btnWhitelistRemove.Add_Click({ $sel = $lstWhitelist.SelectedItems; $sel | ForEach-Object { Remove-FromDNSBLWhitelist -Domain $_ }; Invoke-ReloadDNSBL; Refresh-Lists })
$btnBlocklistRemove.Add_Click({ $sel = $lstBlocklist.SelectedItems; $sel | ForEach-Object { Remove-FromDNSBLBlocklist -Domain $_ }; Invoke-ReloadDNSBL; Refresh-Lists })

$btnWhitelistImport.Add_Click({ 
    $dlg = New-Object System.Windows.Forms.OpenFileDialog; $dlg.Filter = "Text|*.txt"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { 
        Get-Content $dlg.FileName | ForEach-Object { if ($_.Trim()) { Add-ToDNSBLWhitelist -Domain $_.Trim() } }
        Invoke-ReloadDNSBL; Refresh-Lists 
    } 
})
$btnBlocklistImport.Add_Click({ 
    $dlg = New-Object System.Windows.Forms.OpenFileDialog; $dlg.Filter = "Text|*.txt"
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { 
        Get-Content $dlg.FileName | ForEach-Object { if ($_.Trim()) { Add-ToDNSBLBlocklist -Domain $_.Trim() } }
        Invoke-ReloadDNSBL; Refresh-Lists 
    } 
})
$btnWhitelistExport.Add_Click({ $dlg = New-Object System.Windows.Forms.SaveFileDialog; $dlg.Filter = "Text|*.txt"; $dlg.FileName = "whitelist.txt"; if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $Script:WhitelistData | Set-Content $dlg.FileName } })
$btnBlocklistExport.Add_Click({ $dlg = New-Object System.Windows.Forms.SaveFileDialog; $dlg.Filter = "Text|*.txt"; $dlg.FileName = "blocklist.txt"; if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $Script:BlocklistData | Set-Content $dlg.FileName } })

# Statistics
$btnRefreshStats.Add_Click({ Get-ClientStats })
$btnExportStats.Add_Click({ $dlg = New-Object System.Windows.Forms.SaveFileDialog; $dlg.Filter = "CSV|*.csv"; $dlg.FileName = "stats.csv"; if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $Script:ClientStats | Export-Csv $dlg.FileName -NoTypeInformation } })

# DNS Lookup
$btnLookupDomain.Add_Click({ $d = $txtLookupDomain.Text.Trim(); if ($d) { Test-DomainBlock $d } })
$btnLookupVirusTotal.Add_Click({ $d = $txtLookupDomain.Text.Trim(); if ($d) { Start-Process "https://www.virustotal.com/gui/domain/$d" } })

# Alerts
$btnAddAlert.Add_Click({ $p = $txtAlertDomain.Text.Trim(); if ($p) { $Script:AlertRules.Add([PSCustomObject]@{ Pattern=$p; Type=$cmbAlertType.Text }); $txtAlertDomain.Text = ""; Save-AlertRules } })
$btnRemoveAlert.Add_Click({ $i = $lstAlertRules.SelectedIndex; if ($i -ge 0) { $Script:AlertRules.RemoveAt($i); Save-AlertRules } })
$btnClearAlerts.Add_Click({ $Script:TriggeredAlerts.Clear(); $txtAlertCount.Text = " (0)"; $txtActiveAlerts.Text = "0" })

# Feeds
$btnRefreshFeeds.Add_Click({ Get-FeedInfo })
$btnUpdateAllFeeds.Add_Click({ try { Invoke-ForceUpdate; Get-FeedInfo } catch {} })

# System
$btnSysReload.Add_Click({ try { Invoke-ReloadDNSBL; Get-SystemStats } catch {} })
$btnSysUpdate.Add_Click({ try { Invoke-ForceUpdate; Get-SystemStats } catch {} })
$btnSysClear.Add_Click({ try { Invoke-ClearDNSCache } catch {} })
$btnSysRestartDNS.Add_Click({ try { Invoke-RestartDNS } catch {} })
$btnSysRefresh.Add_Click({ Get-SystemStats })
$btnSysReboot.Add_Click({
    $c1 = [System.Windows.MessageBox]::Show("REBOOT firewall?", "Confirm", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($c1 -ne [System.Windows.MessageBoxResult]::Yes) { return }
    $c2 = [System.Windows.MessageBox]::Show("FINAL CONFIRMATION - Reboot NOW?", "Confirm", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($c2 -eq [System.Windows.MessageBoxResult]::Yes) { Invoke-RebootFirewall; [System.Windows.MessageBox]::Show("Rebooting. Wait 2-5 minutes.", "Rebooting") }
})

$btnRefreshPackages.Add_Click({ Get-InstalledPackages })
$btnBackupLists.Add_Click({ Backup-Lists })
$btnRestoreLists.Add_Click({ Restore-Lists })

# ============================================================================
# STARTUP
# ============================================================================

if (-not (Test-SSHAvailable).Available) { Install-PoshSSH }

Load-AppSettings
Apply-Settings
Load-AlertRules

$creds = Load-Credentials
if ($creds) {
    $txtHost.Text = $creds.TargetHost
    $txtPort.Text = $creds.Port.ToString()
    $txtUser.Text = $creds.User
    $txtPassword.Password = $creds.Password
    $chkSaveCredentials.IsChecked = $true
    Update-Status "Credentials loaded"
} else {
    $txtHost.Text = $Script:Config.DefaultHost
    $txtPort.Text = $Script:Config.DefaultPort.ToString()
    $txtUser.Text = $Script:Config.DefaultUser
}

$Window.ShowDialog() | Out-Null
