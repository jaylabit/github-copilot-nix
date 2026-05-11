{
  description = "Nix package for GitHub Copilot CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      overlay = final: prev: {
        github-copilot-cli = final.callPackage ./package.nix { };
      };

      forEachSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f (
            import nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = [ overlay ];
            }
          )
        );
    in
    {
      packages = forEachSystem (pkgs: {
        default = pkgs.github-copilot-cli;
        github-copilot-cli = pkgs.github-copilot-cli;
      });

      apps = forEachSystem (pkgs: {
        default = {
          type = "app";
          program = "${pkgs.github-copilot-cli}/bin/copilot";
          meta.description = "Run GitHub Copilot CLI";
        };
        github-copilot-cli = {
          type = "app";
          program = "${pkgs.github-copilot-cli}/bin/copilot";
          meta.description = "Run GitHub Copilot CLI";
        };
      });

      formatter = forEachSystem (pkgs: pkgs.nixfmt);

      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            curl
            gh
            jq
            nixfmt
          ];
        };
      });

      overlays.default = overlay;
    };
}
