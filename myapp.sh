#!/bin/bash

# Function to generate unique resource names
generate_unique_name() {
    local base_name=$1
    echo "${base_name}-$(date +%Y%m%d%H%M%S)"
}

# Function to create a sample CPU-intensive Python application
create_cpu_app() {
    echo "Creating CPU-intensive Python application..."
    cat << EOF > cpu_app.py
import time
import threading

def cpu_intensive_task(task_id):
    iteration = 0
    while True:
        _ = [x**2 for x in range(10**6)]  # Simulate CPU-intensive computation
        iteration += 1
        print(f"Task {task_id}: Completed iteration {iteration}")  # Log progress
        time.sleep(1)  # Optional: Add a small delay to avoid flooding logs

def main():
    threads = []
    for i in range(4):  # Create 4 threads for parallel computation
        thread = threading.Thread(target=cpu_intensive_task, args=(i,))
        thread.start()
        threads.append(thread)
    for thread in threads:
        thread.join()

if __name__ == "__main__":
    print("CPU-intensive application started...")
    main()
EOF
    echo "CPU-intensive Python app created successfully!"
}

# Function to create Prometheus configuration
create_prometheus_config() {
    echo "Creating Prometheus configuration file..."
    cat << EOF > prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
EOF
    echo "Prometheus configuration created successfully!"
}

# Function to create the startup script for VM deployment
create_startup_script() {
    echo "Creating startup script for VM deployment..."
    cat << EOF > startup.sh
#!/bin/bash
sudo apt update
sudo apt install -y python3 python3-pip grafana prometheus node-exporter

# Start Grafana server
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# Start Prometheus
sudo cp prometheus.yml /etc/prometheus/prometheus.yml
sudo systemctl start prometheus
sudo systemctl enable prometheus

# Start Node Exporter
sudo systemctl start node-exporter
sudo systemctl enable node-exporter

# Run the CPU-intensive application in the background and log output to a file
nohup python3 /cpu_app.py > /var/log/cpu_app.log 2>&1 &

echo "Application, Prometheus, and Grafana started successfully."
EOF
    chmod +x startup.sh
    echo "Startup script created successfully!"
}

# Function to create the VM instance template with dynamic name
create_instance_template() {
    local template_name=$1
    echo "Creating instance template '$template_name'..."
    gcloud compute instance-templates create "$template_name" \
      --machine-type=n1-standard-1 \
      --image-family=debian-12 \
      --image-project=debian-cloud \
      --metadata-from-file startup-script=startup.sh \
      --service-account=assignment3@weighty-smoke-434207-a4.iam.gserviceaccount.com \
      --scopes=https://www.googleapis.com/auth/cloud-platform || {
          echo "Error: Failed to create instance template."
          exit 1
      }
    echo "Instance template '$template_name' created successfully!"
}

# Function to create instance group with auto-scaling using dynamic name
create_instance_group() {
    local group_name=$1
    local template_name=$2

    echo "Creating managed instance group '$group_name' using template '$template_name'..."
    gcloud compute instance-groups managed create "$group_name" \
      --base-instance-name=web-app \
      --template="$template_name" \
      --size=1 \
      --zone=us-central1-a || {
          echo "Error: Failed to create managed instance group."
          exit 1
      }

    echo "Configuring auto-scaling for the managed instance group '$group_name'..."
    gcloud compute instance-groups managed set-autoscaling "$group_name" \
      --max-num-replicas=5 \
      --min-num-replicas=1 \
      --target-cpu-utilization=0.75 \
      --cool-down-period=60 \
      --zone=us-central1-a || {
          echo "Error: Failed to configure auto-scaling."
          exit 1
      }
    echo "Instance group '$group_name' with auto-scaling created successfully!"
}

# Main Execution Flow

echo "Starting the deployment process..."

# Step 1: Create the CPU-intensive application locally.
create_cpu_app

# Step 2: Create Prometheus configuration locally.
create_prometheus_config

# Step 3: Create a startup script for VM deployment.
create_startup_script

# Step 4: Generate unique names for resources.
template_name=$(generate_unique_name "cpu-intensive-template")
group_name=$(generate_unique_name "web-app-group")

# Step 5: Create an instance template for VM creation.
create_instance_template "$template_name"

# Step 6: Create a managed instance group with auto-scaling.
create_instance_group "$group_name" "$template_name"

echo "Deployment process completed successfully!"
echo "Access Grafana at http://[EXTERNAL_IP]:3000 (default credentials: admin/admin)."
echo "Access Prometheus at http://[EXTERNAL_IP]:9090."
