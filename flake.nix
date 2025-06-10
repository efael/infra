{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    simple-nixos-mailserver.url =
      "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.05";
  };

  outputs = _:
    let efael-server-module = import ./.;
    in {
      nixosModules = rec {
        efael-server = efael-server-module;
        default = efael-server;
      };

      # nixosModule = self.nixosModules.default;
    };
}
