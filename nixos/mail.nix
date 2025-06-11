{ lib, config, inputs, ... }:
with lib;
let
  cfg = config.services.efael-server;
  domain = cfg.domains.main;
in {
  imports = [ inputs.simple-nixos-mailserver.nixosModule ];

  options.services.efael-server.mail = {
    enable = mkOption {
      default = true;
      example = true;
      description = "Whether to enable mail server for matrix.";
      type = lib.types.bool;
    };
    loginAccounts = mkOption { type = types.attrsOf types.inferred; };
  };

  config = mkIf (cfg.enable && cfg.mail.enable) {
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
  };
}
