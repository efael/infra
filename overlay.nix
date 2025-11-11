final: prev: rec {
  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable = import inputs.nixpkgs-unstable {
    inherit (final) system;
    config.allowUnfree = true;
  };

  # Changes statix to the one that has pipe-operators support added.
  statix =
    final.unstable.statix.overrideAttrs
    (_o: rec {
      src = final.fetchFromGitHub {
        owner = "oppiliappan";
        repo = "statix";
        rev = "43681f0da4bf1cc6ecd487ef0a5c6ad72e3397c7";
        hash = "sha256-LXvbkO/H+xscQsyHIo/QbNPw2EKqheuNjphdLfIZUv4=";
      };

      cargoDeps = final.rustPlatform.importCargoLock {
        lockFile = src + "/Cargo.lock";
        allowBuiltinFetchGit = true;
      };
    });
}
