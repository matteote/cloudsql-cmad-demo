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

resource "random_password" "admin_password" {
  length           = 16
  special          = true
  override_special = "#_-."
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
}

resource "random_password" "setupadmin_password" {
  length           = 16
  special          = true
  override_special = "#_-."
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
}

resource "google_compute_instance" "windows_vm" {
  project      = var.project_id
  zone         = var.zone
  name         = "windows-dc"
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

      function Connect-ToAD {
          param(
              [Parameter(Mandatory=$true)]
              [string]$adminPassword
          )
          $adminUser = "demo\administrator"
          $adminPass = (ConvertTo-SecureString $adminPassword -AsPlainText -Force)
          $cred = New-Object System.Management.Automation.PSCredential($adminUser, $adminPass)

          $maxRetries = 10
          $retryCount = 0

          Import-Module -Name ActiveDirectory
          while ($retryCount -lt $maxRetries) {
              try {
                  if (-not (Get-PSDrive -Name ADDEMO -ErrorAction SilentlyContinue)) {
                      New-PSDrive -Name ADDEMO -PSProvider ActiveDirectory -Server "windows-dc.demo.lab" -Scope Global -credential $cred -root "//RootDSE/" -ErrorAction Stop
                  }
                  Set-Location ADDEMO:
                  Write-Host "Successfully connected to Active Directory."
                  break
              }
              catch {
                  $retryCount++
                  Write-Host "Failed to connect to Active Directory. Retrying in 30 seconds... (Attempt $retryCount of $maxRetries)"
                  Write-Host "Error: $_"
                  Start-Sleep -Seconds 30
              }
          }
      }

      Write-Host "********************************"
      Write-Host "Windows startup script started."
      Write-Host "********************************"

      # Enable the default administrator account
      $InitFileAdministrator="C:\InitFileAdministrator.txt"
      if (-not (Test-Path $InitFileAdministrator)) {
        Write-Host "Enabling administrator account"
        # Set password for Administrator user
        $password = '${random_password.admin_password.result}'
        Set-LocalUser -Name Administrator -Password (ConvertTo-SecureString -String $password -AsPlainText -Force)
        Enable-LocalUser -Name Administrator

        New-Item $InitFileAdministrator | Out-Null
      }

      # Install AD
      $InitFileDC="C:\InitFileDC.txt"
      if (-not (Test-Path $InitFileDC)) {
        Write-Host "Installing ADDS and DNS"
        # Install AD Domain Services and DNS Server roles
        if (-not (Get-WindowsFeature -Name AD-Domain-Services).Installed) {
          Install-WindowsFeature -Name AD-Domain-Services,DNS -IncludeManagementTools
        }

        Write-Host "Creating the AD forest"  
        # Promote the server to a domain controller
        Install-ADDSForest -DomainName demo.lab -DomainNetbiosName DEMO -DomainMode Win2012R2 -ForestMode Win2012R2 -InstallDns -SafeModeAdministratorPassword (ConvertTo-SecureString -String $password -AsPlainText -Force) -Force

        New-Item $InitFileDC | Out-Null
      }


      # Create the Setupadmin user
      $InitFileSetupAdmin="C:\InitFileSetupAdmin.txt"
      if (-not (Test-Path $InitFileSetupAdmin)) {
          Connect-ToAD -adminPassword '${random_password.admin_password.result}'
          Write-Host "Creating setupadmin user"
          New-ADUser -Name "setupadmin" -Enabled $false
          Set-ADAccountPassword -Identity "setupadmin" -NewPassword (convertto-securestring '${random_password.setupadmin_password.result}' -asplaintext -force) -Reset
          Enable-AdAccount -Identity "setupadmin"
          Write-Host "Adding setupadmin to Domain Admins and DNS Admins groups"
          Add-ADGroupMember -Identity "Domain Admins" -Members "setupadmin"
          Add-ADGroupMember -Identity "DnsAdmins" -Members "setupadmin"

          New-Item $InitFileSetupAdmin | Out-Null
      }

      # Create the Cloud SQL OU
      $InitFileOU="C:\InitFileOU.txt"
      if (-not (Test-Path $InitFileOU)) {
          Connect-ToAD -adminPassword '${random_password.admin_password.result}'
          Write-Host "Creating Cloud SQL Organizational Unit in Active Directory"
          New-ADOrganizationalUnit -Name "CloudSQL"        

          New-Item $InitFileOU | Out-Null
      }

      Write-Host "DC fully initialized."

      Write-Host "********************************"
      Write-Host "Windows startup finished."
      Write-Host "********************************"
    EOF
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.subnet_name
  }
}
