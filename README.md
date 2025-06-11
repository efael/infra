# Efael - server nixos

how to use:

1. put as input in your flakes

```
_: {
  inputs = {
    efael-server.url = "github:efael/server-nix";
  };

  # ...
}
```

2. import nixos module inside configuration.nix and use

```
{ inputs, ... }: {
  imports = [
    inputs.efael-server.nixosModules.default;
  ];

  services.efael-server = {
    enable = true;
    domains.main = "efael.net";
    secrets.realm = "i am super secret key";
    keys = {
      call = ./call.key;
      livekit = ./livekit.key;
    };
  };
}
```
