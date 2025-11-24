# Customer-Managed Active Directory for Cloud SQL for SQL Server Demo

This repository contains the code needed to demonstrate the new Customer-Managed Active Directory feature in Cloud SQL for SQL Server.

## Table of Contents

* [Environment Setup](#environment-setup)
* [Connect to the Environment](#connect-to-the-environment)
* [Conducting the Demo](#conducting-the-demo)

## Environment Setup

This section describes how to set up the demo environment.

### Requirements

*   **Google Cloud SDK (`gcloud`):** You need the `gcloud` CLI installed and authenticated to your Google Cloud account.
*   **Terraform:** Terraform is used to provision the cloud resources.
*   **RDP Client:** You will need an RDP client to connect to the Windows virtual machine.

### Deployment

1.  **Select a GCP Project and Zone:** Choose a Google Cloud project and a zone where you want to deploy the resources.
2.  **Run the deployment script:** Execute the `deploy.sh` script with your project ID and chosen zone as arguments:

    ```bash
    ./deploy.sh <YOUR_PROJECT_ID> <YOUR_GCP_ZONE>
    ```

    The deployment process takes approximately 20 minutes to complete.

3.  **Review the output:** At the end of the deployment, the script will output the connection details for the created resources. This information is provided also by the `get-lab-info.sh` script.

### Getting Environment Information

You can retrieve the environment information at any time by running the `get-lab-info.sh` script:

```bash
./get-lab-info.sh
```

### Cleanup

At the end of the demo, you can remove the resources created by the deployment running the `cleanup.sh` script:

```bash
./cleanup.sh
```

## Connect to the Environment

To connect to the Windows client VM, you will use an IAP (Identity-Aware Proxy) tunnel for RDP.

Run the following on a machine where an RDP client is available (e.g. [Windows App](https://apps.apple.com/it/app/windows-app/id1295203466?mt=12) for macOS.)

1.  **Open an IAP tunnel:** Use the following `gcloud` command to open a tunnel to the `windows-client` VM on port `3389` (RDP). Replace `YOUR_GCP_PROJECT` and `YOUR_GCP_ZONE` with the values of project ID and zone that you used with `deploy.sh`.

    ```bash
    gcloud compute start-iap-tunnel windows-client 3389 --local-host-port=localhost:3389 --project=YOUR_GCP_PROJECT --zone=YOUR_GCP_ZONE
    ```

    This will open a tunnel from your local machine's port `3389` to the VM's RDP port.

2.  **Connect with an RDP client:** Open your RDP client and connect to `localhost:3389`.

3.  **Authenticate:** Use the following credentials to log in:
    *   **User:** `demo\administrator`
    *   **Password:** The password can be obtained from the output of `deploy.sh` or by running `get-lab-info.sh`.

## Conducting the Demo

This section guides you through the process of demonstrating the Customer-Managed Active Directory feature.

1.  **Join the Cloud SQL instance to the domain:** The command to do this is provided in the output of `deploy.sh` and `get-lab-info.sh`. Run this command from your terminal.

2.  **Connect to the Cloud SQL instance in Cloud SQL Studio:** Use the credentials from `get-lab-info.sh` to connect to the instance.

3.  **Create a Windows login:** Execute the following SQL command to create a Windows login in Cloud SQL for the `demo\administrator` user:

    ```sql
    CREATE LOGIN [demo\administrator] FROM WINDOWS
    ```

4.  **Connect to the `windows-client` VM:** If you are not already connected, connect to the `windows-client` VM using RDP as described in the "Connect to the Environment" section.

5.  **Open SQL Server Management Studio (SSMS):** Once on the `windows-client` VM, open SQL Server Management Studio.

6.  **Get the Cloud SQL FQDN:** In the Google Cloud Console, navigate to your Cloud SQL instance and find the "Active Directory FQDN (Private)" value in the instance overview.

7.  **Connect with SSMS:**
    *   In SSMS, use the FQDN you just copied as the server name.
    *   Enable the "Trust server certificate" option.
    *   Use "Windows Authentication".

8.  **Verify the connection:** Once connected, open a new query window and execute the following to verify that you are connected with your Windows identity:

    ```sql
    SELECT SUSER_SNAME()
    ```

    The result should be `demo\administrator`.