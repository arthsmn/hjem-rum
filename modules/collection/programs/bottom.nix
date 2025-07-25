{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;

  toml = pkgs.formats.toml {};

  cfg = config.rum.programs.bottom;
in {
  options.rum.programs.bottom = {
    enable = mkEnableOption "bottom";

    package = mkPackageOption pkgs "bottom" {nullable = true;};

    settings = mkOption {
      type = toml.type;
      default = {};
      example = {
        flags = {
          battery = true;
          tree = true;
        };
        styles.battery.high_battery_color = "Pink";
      };
      description = ''
        The configuration converted into TOML and written to
        {file}`$HOME/.config/bottom/bottom.toml`.

        Please reference [bottom's config file documentation]
        for config options.

        [bottom's config file documentation]: https://bottom.pages.dev/stable/configuration/config-file
      '';
    };
  };

  config = mkIf cfg.enable {
    packages = mkIf (cfg.package != null) [cfg.package];
    files.".config/bottom/bottom.toml".source = mkIf (cfg.settings != {}) (
      toml.generate "bottom.toml" cfg.settings
    );
  };
}
