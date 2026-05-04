{
  description = "Nix package for GitHub Copilot CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      overlay = final: prev: {
        github-copilot-cli = final.callPackage ./package.nix { };
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ overlay ];
        };
      in
      {
        packages = {
          default = pkgs.github-copilot-cli;
          github-copilot-cli = pkgs.github-copilot-cli;
        };

        apps = {
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
        };

        formatter = pkgs.nixfmt;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            curl
            gh
            jq
            nixfmt
          ];
        };
      }
    )
    // {
      overlays.default = overlay;
    };
}
