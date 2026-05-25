{
  description = "squat's talks";

  inputs = {
    kilo.url = "github:squat/kilo";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, ... }@inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.git-hooks-nix.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        {
          pkgs,
          config,
          system,
          ...
        }:
        {
          pre-commit = {
            check.enable = true;
            settings = {
              src = ./.;
              hooks = {
                actionlint.enable = true;
                nixfmt.enable = true;
              };
            };
          };

          devShells = {
            default = pkgs.mkShell {
              inherit (config.pre-commit.devShell) shellHook;
              packages = config.pre-commit.settings.enabledPackages;
            };

            cozysummit = pkgs.mkShell {
              inherit (config.pre-commit.devShell) shellHook;
              packages = with pkgs; [
                chafa
                curl
                graph-easy
                inputs.kilo.packages.${system}.kgctl
                kind
                kubectl
                presenterm
                python313Packages.weasyprint
              ];
            };
          };
        };
    };
}
