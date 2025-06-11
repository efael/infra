{ lib, config, ... }:
with lib;
let cfg = config.services.efael-server;
in {
  imports = [
    (import ./auth.nix)
    (import ./synapse.nix)
    (import ./call.nix)
    (import ./mail.nix)
    (import ./turn.nix)
  ];

  options.services.efael-server = {
    enable = mkEnableOption "efael server";

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

    secrets = { realm = mkOption { type = types.str; }; };

    keys = {
      call = mkOption { type = types.path; };
      livekit = mkOption { type = types.path; };
    };
  };
}
