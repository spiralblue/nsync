{
  description = "A development shell with FHS environment containing Node.js, xz, and tar";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ];
        };
        fhsUserEnv = pkgs.buildFHSEnv {
          name = "nsync-env";
          targetPkgs = pkgs: with pkgs; [
            nodejs
            yarn
            xz
            gnutar
            hello
          ];
          runScript = "bash";
        };

        nrunBuiltFile = pkgs.mkYarnPackage {
          name = "nsync";
          src = ./.;
          packageJson = ./package.json;
          yarnLock = ./yarn.lock;

          buildInputs = [ pkgs.yarn ];
          buildPhase = ''
            ${pkgs.yarn}/bin/yarn build
          '';

          installPhase = ''
            mkdir $out
            mv deps/nix-sync/dist/main.js $out/main.js
          '';

          doFixup = false;
          distPhase = "true"; # There seems to be no other way to disable it. This just disables it.
        };

        nrun = pkgs.buildFHSEnv {
          name = "nsync-env";
          targetPkgs = pkgs: with pkgs; [
            nodejs
            yarn
            xz
            gnutar
            hello
          ];
          runScript = "node ${nrunBuiltFile}/main.js";
        };
      in
      {
        # Devshell
        devShell = fhsUserEnv.env;

        # Shells
        packages.default = nrun;
      });
}
