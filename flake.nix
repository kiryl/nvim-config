{
  description = "A Lua-natic's neovim flake, with extra cats! nixCats!";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";

    "plugins-telescope-recent-files" = {
      url = "github:smartpde/telescope-recent-files";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      inherit (inputs.nixCats) utils;
      luaPath = ./.;
      forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;
      dependencyOverlays = # (import ./overlays inputs) ++
        [
          (utils.standardPluginOverlay inputs)
        ];

      categoryDefinitions =
        { pkgs, ... }:
        {
          lspsAndRuntimeDeps = {
            # some categories of stuff.
            general = with pkgs; [
              universal-ctags
              ripgrep
              fd
              nix-doc
              lua-language-server
              nixd
              stylua
              clang-tools
            ];
          };

          # This is for plugins that will load at startup without using packadd:
          startupPlugins = {
            general = with pkgs.vimPlugins; [
              guess-indent-nvim
              lazy-nvim
              gitsigns-nvim
              which-key-nvim
              telescope-nvim
              telescope-fzf-native-nvim
              telescope-ui-select-nvim
              pkgs.neovimPlugins.telescope-recent-files
              nvim-web-devicons
              plenary-nvim
              nvim-lspconfig
              lazydev-nvim
              fidget-nvim
              conform-nvim
              luasnip
              blink-cmp
              kanagawa-nvim
              todo-comments-nvim
              mini-nvim
              nvim-treesitter.withAllGrammars
              indent-blankline-nvim
              comment-nvim
              whitespace-nvim
              flash-nvim
              ChatGPT-nvim
            ];
          };
        };

      packageDefinitions = {
        nixCats =
          { pkgs, ... }:
          {
            # these also recieve our pkgs variable
            # see :help nixCats.flake.outputs.packageDefinitions
            settings = {
              suffix-path = true;
              suffix-LD = true;
              wrapRc = true;
              aliases = [
                "nvim"
                "vim"
                "vi"
              ];

            };
            categories = {
              general = true;
            };
            extra = {
              nixdExtras = {
                nixpkgs = ''import ${pkgs.path} {}'';
              };
            };
          };
      };

      defaultPackageName = "nixCats";
    in
    forEachSystem (
      system:
      let
        nixCatsBuilder = utils.baseBuilder luaPath {
          inherit
            nixpkgs
            system
            dependencyOverlays
            ;
        } categoryDefinitions packageDefinitions;
        defaultPackage = nixCatsBuilder defaultPackageName;

        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = utils.mkAllWithDefault defaultPackage;

        devShells = {
          default = pkgs.mkShell {
            name = defaultPackageName;
            packages = [ defaultPackage ];
            inputsFrom = [ ];
            shellHook = '''';
          };
        };

      }
    )
    // (
      let
        nixosModule = utils.mkNixosModules {
          moduleNamespace = [ defaultPackageName ];
          inherit
            defaultPackageName
            dependencyOverlays
            luaPath
            categoryDefinitions
            packageDefinitions
            nixpkgs
            ;
        };
        homeModule = utils.mkHomeModules {
          moduleNamespace = [ defaultPackageName ];
          inherit
            defaultPackageName
            dependencyOverlays
            luaPath
            categoryDefinitions
            packageDefinitions
            nixpkgs
            ;
        };
      in
      {

        overlays = utils.makeOverlays luaPath {
          inherit nixpkgs dependencyOverlays;
        } categoryDefinitions packageDefinitions defaultPackageName;

        nixosModules.default = nixosModule;
        homeModules.default = homeModule;

        inherit utils nixosModule homeModule;
        inherit (utils) templates;
      }
    );
}
