{
  description = "Creal";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-25.05/nixexprs.tar.xz";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        llvm = pkgs.llvmPackages;
        csmith = pkgs.callPackage ./csmith.nix { };
      in
      {
        formatter = pkgs.nixfmt-tree;
        devShells.default = pkgs.mkShell {
          name = "creal";

          hardeningDisable = [ "all" ];
          packages = with pkgs; [
            cacert
            csmith
            compcert
            cmake
            pkg-config
            gcc
            libgcc
            # required in both compiling profiler and running creal
            llvm.llvm
            llvm.clang
            llvm.libclang
            # required in compiling profiler
            libffi
            libxml2
            zlib
            # required in compiling function extractor
            nlohmann_json
          ];

          shellHook = ''
            export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH"
            export CSMITH_HOME="${csmith}"
            export YARPGEN_HOME=""
            export NIX_ENFORCE_NO_NATIVE=0
            export CREAL_GLIBC_INCLUDE_DIR="${pkgs.glibc.dev}/include"
            export CREAL_CLANG_RESOURCE_DIR="$(clang -print-resource-dir)/include"

            root=$(pwd)
            # build profiler
            mkdir -p ./profiler/build && cd ./profiler/build && cmake .. && make
            # build function extractor
            cd $root && mkdir -p ./databaseconstructor/functionextractor/build \
            && cd ./databaseconstructor/functionextractor/build && \
            cmake .. && make
            cd $root
          '';
        };
      }
    );
}
