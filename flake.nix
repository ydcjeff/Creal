{
  description = "creal";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
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
        llvm_21 = pkgs.llvmPackages;
        llvm_19 = pkgs.llvmPackages_19;
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
            gcc15
            # libgcc
            # running creal via LLVM 21
            llvm_21.llvm
            llvm_21.clang
            llvm_21.libclang
          ];

          shellHook = ''
            export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH"
            export CSMITH_HOME="${csmith}"
            export YARPGEN_HOME=""
            export NIX_ENFORCE_NO_NATIVE=0
            export CREAL_GLIBC_INCLUDE_DIR="${pkgs.glibc.dev}/include"
            export CREAL_CLANG_RESOURCE_DIR="${llvm_21.clang}/resource-root/include"
          '';
        };

        devShells.build = pkgs.mkShell {
          name = "creal-build";
          hardeningDisable = [ "all" ];
          packages = with pkgs; [
            cmake
            # required in compiling profiler & function extractor
            llvm_19.llvm
            llvm_19.clang
            llvm_19.libclang
            libffi
            libxml2
            zlib
            # required in compiling function extractor
            nlohmann_json
          ];

          shellHook = ''
            export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            export LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH"
            export NIX_ENFORCE_NO_NATIVE=0

            root=$(pwd)
            # build profiler
            mkdir -p ./profiler/build && cd ./profiler/build && cmake .. && make
            # build function extractor
            cd $root && mkdir -p ./databaseconstructor/functionextractor/build \
            && cd ./databaseconstructor/functionextractor/build && \
            cmake .. && make
            cd $root
            exit
          '';
        };
      }
    );
}
