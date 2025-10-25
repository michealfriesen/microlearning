{
  description = "Micro learning";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
			pnpm
            nodejs_20
            nodePackages.typescript
            nodePackages.typescript-language-server
          ];

          shellHook = ''
            echo "React + Express + Node development environment"
            echo "Node version: $(node --version)"
            echo "npm version: $(npm --version)"
          '';
        };
      }
    );
}
