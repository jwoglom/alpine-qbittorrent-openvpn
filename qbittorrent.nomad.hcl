job "qbittorrent" {
    datacenters = ["dc1"]

    type = "service"

    group "default" {
        count = 1
        network {
            port "http" {
                static = 8080
            }
        }

        volume "config_qbittorrent" {
            type = "host"
            source = "config_qbittorrent"
        }

        volume "downloads" {
            type = "host"
            source = "downloads"
        }

        restart {
            attempts = 1
            interval = "1m"
            mode = "delay"
        }

        service {
            name = "qbittorrent"
            port = "http"

            check {
                type = "tcp"
                port = "http"
                interval = "15s"
                timeout = "15s"

                check_restart {
                    limit = 3
                    grace = "90s"
                }
            }
        }

        task "default" {
            driver = "docker"

            config {
                image = "jwoglom/alpine-qbittorrent-openvpn:0.1.8"
                ports = ["http"]
                cap_add = ["net_admin"]
                privileged = true
            }

            kill_timeout = "60s"

            env {
                # Substitute with values from https://haugene.github.io/docker-transmission-openvpn/supported-providers/
                OPENVPN_PROVIDER = "PIA"
                OPENVPN_CONFIG = "us_new_york"
                OPENVPN_USERNAME = "XXXXX"
                OPENVPN_PASSWORD = "XXXXX"
                PUID = "998" # nomad user
                GUID = "998" # nomad user
                LAN = "192.168.0.0/16"
                HEALTH_CHECK_HOST = "google.com"


                # qbittorrent randomly disconnects from the PIA
                # SOCKS proxy and then can no longer download
                RESTART_SECONDS = "21600" # 21600 seconds = 6 hours
            }

            resources {
                cpu = 3000
                memory_max = 2048
            }

            volume_mount {
                volume = "config_qbittorrent"
                destination = "/config/qBittorrent"
            }

            volume_mount {
                volume = "downloads"
                destination = "/downloads"
            }
        }
    }
}
