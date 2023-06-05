{
  description = "ExpidusOS File Manager";

  nixConfig = rec {
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
    substituters = [ "https://cache.nixos.org" "https://cache.garnix.io" ];
    trusted-substituters = substituters;
    fallback = true;
    http2 = false;
  };

  inputs.expidus-sdk = {
    url = github:ExpidusOS/sdk;
    inputs.nixpkgs.follows = "nixpkgs";
  };

  inputs.nixpkgs.url = github:ExpidusOS/nixpkgs;

  outputs = { self, expidus-sdk, nixpkgs }:
    with expidus-sdk.lib;
    flake-utils.eachSystem flake-utils.allSystems (system:
      let
        pkgs = expidus-sdk.legacyPackages.${system};
      in {
        packages.default = pkgs.flutter.buildFlutterApplication {
          pname = "expidus-file-manager";
          version = "0.1.1-${self.shortRev or "dirty"}";

          src = cleanSource self;

          depsListFile = ./deps.json;
          vendorHash = "sha256-AVDqx2ZQmGBh7I5+bjC79GK+gWfCYL+y3u4uR0anyeQ=";

          postInstall = ''
            rm $out/bin/file_manager
            ln -s $out/app/file_manager $out/bin/expidus-file-manager

            mkdir -p $out/share/applications
            mv $out/app/data/com.expidusos.file_manager.desktop $out/share/applications

            mkdir -p $out/share/icons
            mv $out/app/data/com.expidusos.file_manager.png $out/share/icons

            mkdir -p $out/share/metainfo
            mv $out/app/data/com.expidusos.file_manager.metainfo.xml $out/share/metainfo

            substituteInPlace "$out/share/applications/com.expidusos.file_manager.desktop" \
              --replace "Exec=file_manager" "Exec=$out/bin/expidus-file-manager" \
              --replace "Icon=com.expidusos.file_manager" "Icon=$out/share/icons/com.expidusos.file_manager.png"
          '';

          nativeBuildInputs = with pkgs; [
            removeReferencesTo
          ];

          disallowedReferences = with pkgs; [
            flutter
            flutter.unwrapped
          ];

          meta = {
            description = "ExpidusOS File Manager";
            homepage = "https://expidusos.com";
            license = licenses.gpl3;
            maintainers = with maintainers; [ RossComputerGuy ];
            platforms = [ "x86_64-linux" "aarch64-linux" ];
          };
        };
      });
}
