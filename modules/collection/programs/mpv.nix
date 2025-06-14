{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs mapAttrs' nameValuePair;
  inherit (lib.generators) mkKeyValueDefault;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption mkPackageOption literalExpression;
  inherit (lib.types) path attrsOf;

  # TODO: testes

  mpvConf = pkgs.formats.keyValue {
    mkKeyValue = mkKeyValueDefault {} "="; # TODO: consertar geração de perfis (attrs -> ini)
  };

  mpvInputConf = pkgs.formats.keyValue {mkKeyValue = mkKeyValueDefault {} " ";};

  cfg = config.rum.programs.mpv;
in {
  options.rum.programs.mpv = {
    enable = mkEnableOption "mpv";

    package = mkPackageOption pkgs "mpv" {nullable = true;};

    settings = mkOption {
      type = mpvConf.type;
      default = {};
      example = {
        hwdec = "auto";
        save-position-on-quit = true;
        volume-max = 125;
      };
      description = ''
        Configuration written to {file}`$HOME/.config/mpv/mpv.conf`.
        Please reference [mpv's documentation] for configuration options.

        [mpv's documentation]: https://mpv.io/manual/stable/#options
      '';
    };

    scripts = mkOption {
      type = attrsOf path;
      default = {};
      example = literalExpression ''
        {inherit (pkgs.mpvScripts) sponsorblock_minimal thumbfast uosc mpris;}
      '';
      description = ''
        Scripts to be bundled with mpv. These scripts are located in `pkgs.mpvScripts`.
        If you want to package your own scripts, take a look at [nixpkgs' examples].

        [nixpkgs' examples]: https://github.com/NixOS/nixpkgs/tree/master/pkgs/applications/video/mpv/scripts
      '';
    };

    scriptOpts = mkOption {
      type = attrsOf mpvConf.type;
      default = {};
      example = {
        "sponsorblock_minimal" = {
          categories = "'sponsor','intro','outro','interaction'";
        };
      };
      description = ''
        Scripts configuration's options written to {file}`$HOME/.config/mpv/script-opts`.
      '';
    };

    inputs = mkOption {
      type = mpvInputConf.type;
      default = {};
      example = {
        "[" = "add speed -0.25";
        "]" = "add speed 0.25";
      };
      description = ''
        Input configuration written to {file}`$HOME/.config/mpv/input.conf`.
        Please reference [mpv's documentation] for configuration options.

        [mpv's documentation]: https://mpv.io/manual/stable/#command-interface
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [
      (
        if cfg.scripts != {}
        then
          (
            cfg.package.override
            {
              scripts = cfg.scripts;
            }
          )
        else cfg.package
      )
    ];

    files =
      {
        ".config/mpv/mpv.conf".source = mkIf (cfg.settings != {}) (
          mpvConf.generate "mpv.conf" (
            cfg.settings
          )
        );

        ".config/mpv/input.conf".source = mkIf (cfg.inputs != {}) (
          mpvInputConf.generate "mpv-input.conf" (
            cfg.inputs
          )
        );
      }
      // optionalAttrs (cfg.scriptOpts != {})
      (mapAttrs'
        (
          name: value:
            nameValuePair ".config/mpv/script-opts/${name}.conf" {source = mpvConf.generate "mpv-${name}.conf" value;}
        )
        cfg.scriptOpts);
  };
}
