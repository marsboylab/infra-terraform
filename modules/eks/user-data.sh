#!/bin/bash

# EKS Node Group User Data Script
# This script is used to bootstrap EKS worker nodes

set -o xtrace

# Variables passed from Terraform
CLUSTER_NAME="${cluster_name}"
CLUSTER_ENDPOINT="${cluster_endpoint}"
CLUSTER_CA_DATA="${cluster_ca_data}"
BOOTSTRAP_ARGUMENTS="${bootstrap_arguments}"

# Update system packages
yum update -y

# Install additional packages
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Configure Docker daemon for better performance
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

# Restart Docker service
systemctl restart docker

# Bootstrap the EKS node
/etc/eks/bootstrap.sh $CLUSTER_NAME $BOOTSTRAP_ARGUMENTS

# Add custom CloudWatch agent configuration for container insights
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "metrics": {
    "namespace": "CWAgent",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ],
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "diskio": {
        "measurement": [
          "io_time"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": [
          "tcp_established",
          "tcp_time_wait"
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/eks/$CLUSTER_NAME/node-logs",
            "log_stream_name": "{instance_id}/messages"
          },
          {
            "file_path": "/var/log/dmesg",
            "log_group_name": "/aws/eks/$CLUSTER_NAME/node-logs",
            "log_stream_name": "{instance_id}/dmesg"
          }
        ]
      }
    }
  }
}
EOF

# Install and start CloudWatch agent
yum install -y amazon-cloudwatch-agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Configure kubelet with additional arguments
cat <<EOF > /etc/kubernetes/kubelet/kubelet-config.json
{
  "kind": "KubeletConfiguration",
  "apiVersion": "kubelet.config.k8s.io/v1beta1",
  "address": "0.0.0.0",
  "port": 10250,
  "readOnlyPort": 0,
  "cgroupDriver": "systemd",
  "hairpinMode": "hairpin-veth",
  "serializeImagePulls": false,
  "featureGates": {
    "RotateKubeletServerCertificate": true
  },
  "serverTLSBootstrap": true,
  "authentication": {
    "x509": {
      "clientCAFile": "/etc/kubernetes/pki/ca.crt"
    },
    "webhook": {
      "enabled": true,
      "cacheTTL": "2m0s"
    },
    "anonymous": {
      "enabled": false
    }
  },
  "authorization": {
    "mode": "Webhook",
    "webhook": {
      "cacheAuthorizedTTL": "5m0s",
      "cacheUnauthorizedTTL": "30s"
    }
  },
  "eventRecordQPS": 0,
  "protectKernelDefaults": true,
  "failSwapOn": false,
  "containerLogMaxSize": "10Mi",
  "containerLogMaxFiles": 5,
  "systemReserved": {
    "cpu": "100m",
    "memory": "100Mi",
    "ephemeral-storage": "1Gi"
  },
  "kubeReserved": {
    "cpu": "100m",
    "memory": "100Mi",
    "ephemeral-storage": "1Gi"
  },
  "evictionHard": {
    "memory.available": "100Mi",
    "nodefs.available": "10%",
    "nodefs.inodesFree": "5%"
  },
  "evictionSoft": {
    "memory.available": "300Mi",
    "nodefs.available": "15%",
    "nodefs.inodesFree": "10%"
  },
  "evictionSoftGracePeriod": {
    "memory.available": "2m",
    "nodefs.available": "2m",
    "nodefs.inodesFree": "2m"
  },
  "evictionMaxPodGracePeriod": 90,
  "imageGCHighThresholdPercent": 85,
  "imageGCLowThresholdPercent": 80,
  "imageMinimumGCAge": "2m",
  "registryPullQPS": 10,
  "registryBurst": 20,
  "runtimeRequestTimeout": "2m",
  "volumeStatsAggPeriod": "1m",
  "allowedUnsafeSysctls": [],
  "streamingConnectionIdleTimeout": "4h",
  "nodeStatusUpdateFrequency": "10s",
  "nodeStatusReportFrequency": "5m",
  "nodeLeaseDurationSeconds": 40,
  "imageMaximumGCAge": "0s",
  "maxOpenFiles": 1000000,
  "contentType": "application/vnd.kubernetes.protobuf",
  "kubeAPIQPS": 10,
  "kubeAPIBurst": 20,
  "clusterDNS": ["172.20.0.10"],
  "clusterDomain": "cluster.local",
  "resolvConf": "/etc/resolv.conf",
  "tlsCipherSuites": [
    "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256",
    "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
    "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305",
    "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
    "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305",
    "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",
    "TLS_RSA_WITH_AES_256_GCM_SHA384",
    "TLS_RSA_WITH_AES_128_GCM_SHA256"
  ],
  "tlsMinVersion": "VersionTLS12",
  "localStorageCapacityIsolation": true
}
EOF

# Signal successful completion
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource NodeGroup --region ${AWS::Region}

# Install additional tools
yum install -y htop iotop sysstat tree jq

# Set up log rotation for containerd
cat <<EOF > /etc/logrotate.d/containerd
/var/log/containerd.log {
    daily
    rotate 10
    missingok
    compress
    notifempty
    create 0644 root root
    postrotate
        /bin/kill -USR1 \$(pidof containerd) 2>/dev/null || true
    endscript
}
EOF

# Configure system limits
cat <<EOF >> /etc/security/limits.conf
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF

# Configure kernel parameters
cat <<EOF >> /etc/sysctl.conf
# Network tuning
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_congestion_control = bbr
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_probes = 7
net.ipv4.tcp_keepalive_intvl = 30

# File system
fs.file-max = 2097152
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 1024

# Memory management
vm.swappiness = 1
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.max_map_count = 262144

# Process limits
kernel.pid_max = 4194304
EOF

# Apply sysctl settings
sysctl -p

echo "EKS Node bootstrap completed successfully!" 