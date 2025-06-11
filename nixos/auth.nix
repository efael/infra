{ lib, config, ... }:
with lib;
let cfg = config.services.efael-server;
in {
  imports = [ (import ./mas.nix) ];

  options.services.efael-server.auth = {
    enable = mkOption {
      default = true;
      example = true;
      description = "Whether to enable matrix authentication service.";
      type = lib.types.bool;
    };
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

  config = mkIf (cfg.enable && cfg.auth.enable) {
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
  };
}
