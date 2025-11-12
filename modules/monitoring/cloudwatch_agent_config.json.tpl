{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/opt/graphdb/node/logs/main.log",
                        "log_group_name": "${name}",
                        "log_stream_name": "{local_hostname}",
                        "filters": [
                            {
                            "type": "exclude",
                            "expression": "INFO"
                            }
                        ]
                    }
                ]
            }
        },
        "metrics_collected": {
            "prometheus": {
                "log_group_name": "${name}",
                "prometheus_config_path": "/etc/prometheus/prometheus.yaml",
                "emf_processor": {
                    "metric_declaration_dedup": true,
                    "metric_namespace": "${name}",
                    "metric_unit": {
                        "graphdb_nonheap_used_mem": "Bytes",
                        "graphdb_work_dir_used": "Bytes",
                        "graphdb_threads_count": "Count",
                        "graphdb_logs_dir_free": "Bytes",
                        "graphdb_heap_committed_mem": "Bytes",
                        "graphdb_logs_dir_used": "Bytes",
                        "graphdb_heap_max_mem": "Bytes",
                        "graphdb_heap_init_mem": "Bytes",
                        "graphdb_nonheap_init_mem": "Bytes",
                        "graphdb_class_count": "Count",
                        "graphdb_mem_garbage_collections_count": "Count",
                        "graphdb_data_dir_free": "Bytes",
                        "graphdb_nonheap_max_mem": "Bytes",
                        "graphdb_work_dir_free": "Bytes",
                        "graphdb_cpu_load": "Percent",
                        "graphdb_data_dir_used": "Bytes",
                        "graphdb_nonheap_committed_mem": "Bytes",
                        "graphdb_heap_used_mem": "Bytes",
                        "graphdb_open_file_descriptors": "Count",
                        "graphdb_nodes_in_cluster": "Count",
                        "graphdb_nodes_in_sync": "Count",
                        "graphdb_nodes_out_of_sync": "Count",
                        "graphdb_nodes_disconnected": "Count",
                        "graphdb_nodes_syncing": "Count",
                        "graphdb_leader_elections_count": "Count",
                        "graphdb_failure_recoveries_count": "Count"
                    },
                    "metric_declaration": [
                        {
                            "source_labels": [
                                "job"
                            ],
                            "label_matcher": "graphdb_infrastructure_monitor",
                            "dimensions": [
                                [
                                  "host"
                                ]
                            ],
                            "metric_selectors": [
                                "^graphdb_nonheap_used_mem$",
                                "^graphdb_work_dir_used$",
                                "^graphdb_threads_count$",
                                "^graphdb_logs_dir_free$",
                                "^graphdb_heap_committed_mem$",
                                "^graphdb_logs_dir_used$",
                                "^graphdb_heap_max_mem$",
                                "^graphdb_heap_init_mem$",
                                "^graphdb_nonheap_init_mem$",
                                "^graphdb_class_count$",
                                "^graphdb_mem_garbage_collections_count$",
                                "^graphdb_data_dir_free$",
                                "^graphdb_nonheap_max_mem$",
                                "^graphdb_work_dir_free$",
                                "^graphdb_cpu_load$",
                                "^graphdb_data_dir_used$",
                                "^graphdb_nonheap_committed_mem$",
                                "^graphdb_heap_used_mem$",
                                "^graphdb_open_file_descriptors$"
                            ]
                        },
                        {
                            "source_labels": [
                                "job"
                            ],
                            "label_matcher": "graphdb_cluster_monitor",
                            "dimensions": [
                                [
                                 "host"
                                ]
                            ],
                            "metric_selectors": [
                                "^graphdb_nodes_in_cluster$",
                                "^graphdb_nodes_in_sync$",
                                "^graphdb_nodes_out_of_sync$",
                                "^graphdb_nodes_disconnected$",
                                "^graphdb_nodes_syncing$",
                                "^graphdb_leader_elections_count$",
                                "^graphdb_failure_recoveries_count$"
                            ]
                        }
                    ]
                }
            }
        }
    },
    "metrics": {
        "aggregation_dimensions": [
            [
                "AutoScalingGroupName"
            ]
        ],
        "append_dimensions": {
         "InstanceId": "$${aws:InstanceId}",
         "AutoScalingGroupName": "$${aws:AutoScalingGroupName}"
        },
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 10,
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    "used_percent",
                    "disk_free",
                    "disk_used_percent"
                ],
                "metrics_collection_interval": 10,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 10,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent",
                    "mem_free",
                    "mem_available_percent",
                    "mem_total"
                ],
                "metrics_collection_interval": 10
            }
        }
    }
}
