{ lib, config, ... }:
with lib;
let cfg = config.services.efael-server;
in {
  options.services.efael-server.call = {
    enable = mkOption {
      default = true;
      example = true;
      description = "Whether to enable element call service.";
      type = lib.types.bool;
    };
    livekitPort = mkOption {
      type = types.int;
      default = 7880;
    };
    rtcPort = mkOption {
      type = types.int;
      default = 7881;
    };
    lkJwtPort = mkOption {
      type = types.int;
      default = 8192;
    };
  };

  config = mkIf (cfg.enable && cfg.call.enable) {
    services.livekit = {
      enable = true;
      keyFile = cfg.keys.call;

      settings = {
        port = cfg.call.livekitPort;

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
      port = cfg.call.lkJwtPort;
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
  };
}
