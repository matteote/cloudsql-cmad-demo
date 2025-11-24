terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

data "google_compute_image" "windows_server" {
  family  = "windows-2022"
  project = "windows-cloud"
}

resource "google_compute_instance" "windows_client_vm" {
  project      = var.project_id
  zone         = var.zone
  name         = "windows-client"
  machine_type = "n2-standard-4"
  tags         = ["windows-vm"]

  shielded_instance_config {
    enable_secure_boot = true
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.windows_server.self_link
      size  = 128
      type  = "pd-balanced"
    }
  }

  metadata = {
    serial-port-enable = "TRUE"
    enable-windows-ssh = "TRUE"
    windows-startup-script-ps1 = <<-EOF
      $ErrorActionPreference = "Stop"

      $InitFileSsms="C:\ClientInitSsmsInstalled.txt"
      $InitFileVsCode="C:\ClientInitVsCodeInstalled.txt"
      $InitFileDotnet="C:\ClientInitDotnetInstalled.txt"

      Write-Host "********************************"
      Write-Host "Windows startup script started."
      Write-Host "********************************"
      
      # Install SQL Server Management Studio
      if (-not (Test-Path $InitFileSsms)) {
        # Install SSMS
        $ssms_url = "https://aka.ms/ssmsfullsetup"
        $ssms_setup_path = "C:\ssms_setup.exe"
        
        Write-Host "Downloading SQL Server Management Studio setup..."
        Invoke-WebRequest -Uri $ssms_url -OutFile $ssms_setup_path

        Write-Host "Installing SQL Server Management Studio..."
        Start-Process $ssms_setup_path -ArgumentList "/Install /Quiet /NoRestart" -Wait

        New-Item $InitFileSsms | Out-Null
        Write-Host "SQL Server Management Studio installed."
      }

      # Install Visual Studio Code
      if (-not (Test-Path $InitFileVsCode)) {
        # Install VS Code
        $vsCode_url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
        $vsCode_setup_path = "C:\vsCode_setup.exe"

        Write-Host "Downloading Visual Studio Code setup..."
        Invoke-WebRequest -Uri $vsCode_url -OutFile $vsCode_setup_path

        Write-Host "Installing Visual Studio Code..."
        Start-Process $vsCode_setup_path -ArgumentList "/verysilent /mergetasks=!runcode" -Wait

        New-Item $InitFileVsCode | Out-Null
        Write-Host "Visual Studio Code installed."
      }

      # Install .NET SDK 9.0
      if (-not (Test-Path $InitFileDotnet)) {
        # Install .NET SDK
        $sdkInstallerUrl = "https://builds.dotnet.microsoft.com/dotnet/Sdk/9.0.308/dotnet-sdk-9.0.308-win-x64.exe"
        $sdkInstallerPath = "C:\dotnet-sdk-installer.exe"

        Write-Host "Downloading .NET SDK installer..."
        Invoke-WebRequest -Uri $sdkInstallerUrl -OutFile $sdkInstallerPath

        Write-Host "Installing .NET 9.0 SDK..."
        Start-Process -FilePath $sdkInstallerPath -ArgumentList "/install /quiet /norestart" -Wait

        New-Item $InitFileDotnet | Out-Null
        Write-Host ".NET 9.0 SDK installed."
      }

      if (!((Get-ComputerInfo).CsDomainRole -eq 'MemberServer')) {
        Write-Host "Machine is not a domain member. Joining the domain."

        # Set DNS Server
        Write-Host "Setting DNS Server to ${var.windows_vm_ip_address}"
        Get-NetAdapter | ForEach-Object { 
          Write-Host "Configuring adapter $($_.Name) with DNS ${var.windows_vm_ip_address}"
          Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses "${var.windows_vm_ip_address}" 
          Write-Host "Adapter Configuration for $($_.Name) after DNS update:"
          Get-NetAdapter -Name $_.Name | Get-NetIPConfiguration | Format-List
        }

        Write-Host "Waiting for DNS resolution of windows-dc.demo.lab..."
        while ($true) {
            try {
                Resolve-DnsName -Name "windows-dc.demo.lab" -ErrorAction Stop
                Write-Host "DNS resolution for windows-dc.demo.lab is successful."
                break
            }
            catch {
                Write-Host "DNS resolution for windows-dc.demo.lab failed. Retrying in 15 seconds..."
                Start-Sleep -Seconds 15
            }
        }
        # Join the domain
        $domain = "demo.lab"
        $password = '${var.admin_password}'
        $username = "demo\Administrator"
        $credential = New-Object System.Management.Automation.PSCredential($username, (ConvertTo-SecureString $password -AsPlainText -Force))
        
        $maxRetries = 10
        $retryCount = 0
        while ($retryCount -lt $maxRetries) {
            try {
                Add-Computer -DomainName $domain -Credential $credential -Restart -Force -ErrorAction Stop
                Write-Host "Successfully joined the domain."
                break
            }
            catch {
                $retryCount++
                Write-Host "Failed to join the domain. Retrying in 30 seconds... (Attempt $retryCount of $maxRetries)"
                Write-Host "Error: "$_.Exception.Message
                Start-Sleep -Seconds 30
            }
        }
        Write-Host "The client is joined to demo.lab domain."
      }

      Write-Host "Client fully initialized."

      Write-Host "********************************"
      Write-Host "Windows startup finished."
      Write-Host "Client fully initialized"
      Write-Host "********************************"
    EOF
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.subnet_name
  }
}
