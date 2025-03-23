# GCP Auto-Scaling Setup for Local VM

This project demonstrates setting up a local VM to monitor CPU utilization and auto-scale VM instances on Google Cloud Platform (GCP) when resource usage exceeds 75%. The setup includes:

- Running a script on the local VM (`myapp.sh`) to trigger instance creation.
- Creating instance templates, instance groups, and VMs on GCP.
- Auto-scaling new VM instances based on CPU utilization metrics.

## Requirements

- Local VM with Linux (Ubuntu 22.04 LTS).
- GCP Account and service account credentials.
- GCP SDK installed on the local VM.
- Prometheus and Grafana installed for CPU utilization monitoring.
- Access to GCP Console for creating VM instances.

## Setup Steps

### 1. **Create GCP Service Account**

- Log in to the [Google Cloud Console](https://console.cloud.google.com/).
- Create a new service account under **IAM & Admin > Service Accounts**.
- Download the JSON key for the service account.
- Save the key file in your local VM.

### 2. **Install GCP SDK on Local VM**

- Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) on your local VM:

    ```bash
    curl https://sdk.cloud.google.com | bash
    exec -l $SHELL
    gcloud init
    ```

- Authenticate the SDK with the service account key:

    ```bash
    gcloud auth activate-service-account --key-file=<path_to_your_service_account_key>.json
    ```

### 3. **Configure Auto-Scaling on GCP**

- Create an **instance template** on GCP.
    ```bash
    gcloud compute instance-templates create my-instance-template --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud --machine-type=n1-standard-1
    ```

- Create an **instance group** using the template.
    ```bash
    gcloud compute instance-groups managed create my-instance-group --base-instance-name my-instance --size 1 --template my-instance-template --zone us-central1-a
    ```

### 4. **Run the Local Script (`myapp.sh`)**

- The `myapp.sh` script will start the process and trigger the creation of templates, groups, and VM instances. Run the script:

    ```bash
    ./myapp.sh
    ```

- This script will also monitor CPU usage and, once it exceeds 75%, will trigger new VM instances to be created automatically on GCP.

### 5. **Monitor CPU Utilization**

- Use Prometheus and Grafana to monitor the CPU utilization on the local VM. The system will automatically scale the VM instances on GCP once CPU utilization crosses the 75% threshold.

### 6. **Results and Scaling**

Once the CPU utilization crosses the 75% threshold, new VM instances will be automatically created on GCP, ensuring that the system can handle the increased load.

### 7. **Check Your GCP VM Instances**

To verify the new VM instances are created, you can run:

```bash
gcloud compute instances list --filter="name=my-instance"
