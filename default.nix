{ config, lib, inputs, ... }:
with lib;
let cfg = config.services.efael-server;
in {
  imports = [ inputs.simple-nixos-mailserver.nixosModule import ./mas.nix ];

  options.services.efael-server = {
    enable = mkEnableOption "this enables efael server";

    domains = {
      main = mkOption { type = types.str; };
      server = mkOption {
        type = types.str;
        default = "server.${cfg.domains.main}";
      };
      client = mkOption {
        type = types.str;
        default = "chat.${cfg.domains.main}";
      };
      call = mkOption {
        type = types.str;
        default = "call.${cfg.domains.main}";
      };
      mail = mkOption {
        type = types.str;
        default = "mail.${cfg.domains.main}";
      };
      auth = mkOption {
        type = types.str;
        default = "auth.${cfg.domains.main}";
      };
      realm = mkOption {
        type = types.str;
        default = "turn.${cfg.domains.main}";
      };
      livekit = mkOption {
        type = types.str;
        default = "livekit.${cfg.domains.main}";
      };
      livekit-jwt = mkOption {
        type = types.str;
        default = "livekit-jwt.${cfg.domains.main}";
      };
    };

    keys = {
      realm = mkOption { type = types.str; };
      call = mkOption { type = types.str; };
      livekit = mkOption { type = types.str; };
    };

    synapse = {
      enable = mkEnableOption "this enables element synapse - matrix server";
      port = mkOption {
        type = types.int;
        default = 8008;
      };
      extraConfigFiles = mkOption { type = types.listOf types.inferred; };
    };

    mail = {
      enable = mkEnableOption "this enables mail server for matrix";
      loginAccounts = mkOption { type = types.attrsOf types.inferred; };
    };

    auth = {
      enable = mkEnableOption "this enables matrix authentication service";
      webPort = mkOption {
        type = types.int;
        default = 8080;
      };
      healthPort = mkOption {
        type = types.int;
        default = 8081;
      };
      extraConfigFiles = mkOption { type = types.listOf types.inferred; };
    };

    turn = { enable = mkEnableOption "this enables TURN server"; };

    call = {
      enable = mkEnableOption "this enables element call service";
      port = mkOption {
        type = types.int;
        default = 7880;
      };
      rtcPort = mkOption {
        type = types.int;
        default = 7881;
      };
      livekitPort = mkOption {
        type = types.int;
        default = 8192;
      };
    };
  };

  config = mkIf cfg.enable mkMerge [
    # MATRIX SERVER
    (mkIf cfg.synapse.enable {
      services.postgresql = {
        enable = lib.mkDefault true;

        # initialScript = pkgs.writeText "synapse-init.sql" ''
        #   CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD '${temp}';
        #   CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
        #     TEMPLATE template0
        #     LC_COLLATE = "C"
        #     LC_CTYPE = "C";
        # '';
      };

      services.matrix-synapse = {
        enable = true;
        log.root.level = "WARNING";

        configureRedisLocally = true;

        extraConfigFiles = cfg.synapse.extraConfigFiles;

        extras = lib.mkForce [
          "oidc" # OpenID Connect authentication
          "postgres" # PostgreSQL database backend
          "redis" # Redis support for the replication stream between worker processes
          "systemd" # Provide the JournalHandler used in the default log_config
          "url-preview" # Support for oEmbed URL previews
          "user-search" # Support internationalized domain names in user-search
        ];

        settings = {
          server_name = cfg.domains.main;
          public_baseurl = "https://${cfg.domains.server}";

          turn_allow_guests = true;
          turn_uris = [
            "turn:${cfg.domains.realm}:3478?transport=udp"
            "turn:${cfg.domains.realm}:3478?transport=tcp"
          ];
          turn_shared_secret = cfg.keys.realm;
          turn_user_lifetime = "1h";

          suppress_key_server_warning = true;
          allow_guest_access = true;
          enable_set_displayname = true;
          enable_set_avatar_url = true;

          admin_contact = "mailto:support@${cfg.domains.main}";

          listeners = [{
            port = cfg.server.ports;
            bind_addresses = [ "127.0.0.1" "::1" ];
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [{
              names = [
                "client"
                "federation"
                "keys"
                "media"
                "openid"
                "replication"
                "static"
              ];
            }];
          }];

          account_threepid_delegates.msisdn = "";
          alias_creation_rules = [{
            action = "allow";
            alias = "*";
            room_id = "*";
            user_id = "*";
          }];
          allow_public_rooms_over_federation = true;
          allow_public_rooms_without_auth = false;
          auto_join_rooms =
            [ "#community:${cfg.domains.main}" "#general:${cfg.domains.main}" ];
          autocreate_auto_join_rooms = true;
          default_room_version = "10";
          disable_msisdn_registration = true;
          enable_media_repo = true;

          enable_registration = false;
          enable_registration_captcha = false;
          enable_registration_without_verification = false;
          enable_room_list_search = true;
          encryption_enabled_by_default_for_room_type = "off";
          event_cache_size = "100K";
          caches.global_factor = 10;

          # Based on https://github.com/spantaleev/matrix-docker-ansible-deploy/blob/37a7af52ab6a803e5fec72d37b0411a6c1a3ddb7/docs/maintenance-synapse.md#tuning-caches-and-cache-autotuning
          # https://element-hq.github.io/synapse/latest/usage/configuration/config_documentation.html#caches-and-associated-values
          cache_autotuning = {
            max_cache_memory_usage = "4096M";
            target_cache_memory_usage = "2048M";
            min_cache_ttl = "5m";
          };

          # The maximum allowed duration by which sent events can be delayed, as
          # per MSC4140.
          max_event_delay_duration = "24h";

          federation_rr_transactions_per_room_per_second = 50;
          federation_client_minimum_tls_version = "1.2";
          forget_rooms_on_leave = true;
          include_profile_data_on_invite = true;
          limit_profile_requests_to_users_who_share_rooms = false;

          max_spider_size = "10M";
          max_upload_size = "50M";
          media_storage_providers = [ ];

          password_config = {
            enabled = false;
            localdb_enabled = false;
            pepper = "";
          };

          presence.enabled = true;
          push.include_content = false;

          redaction_retention_period = "7d";
          forgotten_room_retention_period = "7d";
          registration_requires_token = false;
          registrations_require_3pid = [ "email" ];
          report_stats = false;
          require_auth_for_profile_requests = false;
          room_list_publication_rules = [{
            action = "allow";
            alias = "*";
            room_id = "*";
            user_id = "*";
          }];

          user_directory = {
            prefer_local_users = false;
            search_all_users = false;
          };
          user_ips_max_age = "28d";

          rc_message = {
            # This needs to match at least e2ee key sharing frequency plus a bit of headroom
            # Note key sharing events are bursty
            per_second = 0.5;
            burst_count = 30;
          };
          rc_delayed_event_mgmt = {
            # This needs to match at least the heart-beat frequency plus a bit of headroom
            # Currently the heart-beat is every 5 seconds which translates into a rate of 0.2s
            per_second = 1;
            burst_count = 20;
          };

          withJemalloc = true;
        };
      };
    })

    # MAIL
    (mkIf cfg.mail.enable (let domain = cfg.domains.main;
    in {
      mailserver = {
        enable = true;
        fqdn = cfg.domains.mail;
        domains = [ domain ];

        localDnsResolver = false;

        fullTextSearch = {
          enable = true;
          # index new email as they arrive
          autoIndex = true;
          # forcing users to write body
          enforced = "body";
        };

        # Generating hashed passwords:
        # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
        loginAccounts = cfg.mail.loginAccounts;

        # Use Let's Encrypt certificates. Note that this needs to set up a stripped
        # down nginx and opens port 80.
        certificateScheme = "acme-nginx";
      };
    }))

    # AUTH
    (mkIf cfg.auth.enable {
      services.matrix-authentication-service = {
        enable = true;
        createDatabase = true;
        extraConfigFiles = cfg.auth.extraConfigFiles;

        settings = {
          http = {
            public_base = "https://${cfg.domains.auth}";
            issuer = "https://${cfg.domains.auth}";
            listener = [
              {
                name = "web";
                resources = [
                  { name = "discovery"; }
                  { name = "human"; }
                  { name = "oauth"; }
                  { name = "compat"; }
                  { name = "graphql"; }
                  {
                    name = "assets";
                    path =
                      "${config.services.matrix-authentication-service.package}/share/matrix-authentication-service/assets";
                  }
                ];
                binds = [{
                  host = "0.0.0.0";
                  port = cfg.auth.webPort;
                }];
                proxy_protocol = false;
              }
              {
                name = "internal";
                resources = [{ name = "health"; }];
                binds = [{
                  host = "0.0.0.0";
                  port = cfg.auth.healthPort;
                }];
                proxy_protocol = false;
              }
            ];
          };

          account = {
            email_change_allowed = true;
            displayname_change_allowed = true;
            password_registration_enabled = true;
            password_change_allowed = true;
            password_recovery_enabled = true;
          };

          passwords = {
            enabled = true;
            minimum_complexity = 3;
            schemes = [
              {
                version = 1;
                algorithm = "argon2id";
              }
              {
                version = 2;
                algorithm = "bcrypt";
              }
            ];
          };
        };
      };
    })

    # TURN
    (mkIf cfg.turn.enable {
      services.coturn = rec {
        realm = cfg.domains.realm;
        enable = true;
        no-cli = true;
        no-tcp-relay = true;
        min-port = 48000;
        max-port = 49000;
        use-auth-secret = true;
        static-auth-secret = cfg.keys.realm;
        cert = "${config.security.acme.certs.${realm}.directory}/full.pem";
        pkey = "${config.security.acme.certs.${realm}.directory}/key.pem";
        extraConfig = ''
          # for debugging
          verbose
          # ban private IP ranges
          no-multicast-peers
          external-ip=65.109.74.214
          external-ip=2a01:4f9:3071:31ce::
          denied-peer-ip=0.0.0.0-0.255.255.255
          denied-peer-ip=10.0.0.0-10.255.255.255
          denied-peer-ip=100.64.0.0-100.127.255.255
          denied-peer-ip=127.0.0.0-127.255.255.255
          denied-peer-ip=169.254.0.0-169.254.255.255
          denied-peer-ip=172.16.0.0-172.31.255.255
          denied-peer-ip=192.0.0.0-192.0.0.255
          denied-peer-ip=192.0.2.0-192.0.2.255
          denied-peer-ip=192.88.99.0-192.88.99.255
          denied-peer-ip=192.168.0.0-192.168.255.255
          denied-peer-ip=198.18.0.0-198.19.255.255
          denied-peer-ip=198.51.100.0-198.51.100.255
          denied-peer-ip=203.0.113.0-203.0.113.255
          denied-peer-ip=240.0.0.0-255.255.255.255
          denied-peer-ip=::1
          denied-peer-ip=64:ff9b::-64:ff9b::ffff:ffff
          denied-peer-ip=::ffff:0.0.0.0-::ffff:255.255.255.255
          denied-peer-ip=100::-100::ffff:ffff:ffff:ffff
          denied-peer-ip=2001::-2001:1ff:ffff:ffff:ffff:ffff:ffff:ffff
          denied-peer-ip=2002::-2002:ffff:ffff:ffff:ffff:ffff:ffff:ffff
          denied-peer-ip=fc00::-fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
          denied-peer-ip=fe80::-febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff
        '';
      };

      networking.firewall = {
        interfaces.eth0 = let
          range = with config.services.coturn; [{
            from = min-port;
            to = max-port;
          }];
        in {
          allowedUDPPortRanges = range;
          allowedUDPPorts = [ 3478 5349 ];
          allowedTCPPortRanges = [ ];
          allowedTCPPorts = [ 3478 5349 ];
        };
      };

      users.users.nginx.extraGroups = [ config.users.groups.turnserver.name ];

      security.acme.certs.${config.services.coturn.realm} = {
        postRun = "systemctl restart coturn.service";
        group = lib.mkForce "turnserver";
      };

      services.www.hosts = {
        ${cfg.domains.realm} = {
          addSSL = true;
          enableACME = true;
        };
      };
    })

    # CALL
    (mkIf cfg.call.enable {
      services.livekit = {
        enable = true;
        keyFile = cfg.keys.call;

        settings = {
          port = cfg.call.port;

          rtc = {
            tcp_port = cfg.call.rtcPort;
            port_range_start = 50000;
            port_range_end = 60000;
            use_external_ip = false;
          };
        };
      };

      services.lk-jwt-service = {
        enable = true;
        port = cfg.call.livekitPort;
        livekitUrl = "wss://${cfg.domains.livekit}";
        keyFile = cfg.keys.livekit;
      };

      networking.firewall = {
        interfaces.eth0 = let
          range = with config.services.livekit.settings.rtc; [{
            from = port_range_start;
            to = port_range_end;
          }];
        in {
          allowedUDPPortRanges = range;
          allowedUDPPorts = [ cfg.call.rtcPort ];
          allowedTCPPortRanges = range;
          allowedTCPPorts = [ cfg.call.rtcPort ];
        };
      };
    })
  ];
}
