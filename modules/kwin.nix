{ config, lib, ... }:

with lib;

let
  cfg = config.programs.plasma;
  validTitlebarButtons = {
    longNames = [
      "more-window-actions"
      "application-menu"
      "on-all-desktops"
      "minimize"
      "maximize"
      "close"
      "help"
      "shade"
      "keep-below-windows"
      "keep-above-windows"
    ];
    shortNames = [
      "M"
      "N"
      "S"
      "I"
      "A"
      "X"
      "H"
      "L"
      "B"
      "F"
    ];
  };

  # Gets a list with long names and turns it into short names
  getShortNames = wantedButtons:
    lists.forEach
      (
        lists.flatten (
          lists.forEach wantedButtons (currentButton:
            lists.remove null (
              lists.imap0
                (index: value:
                  if value == currentButton then "${toString index}" else null
                )
                validTitlebarButtons.longNames
            )
          )
        )
      )
      getShortNameFromIndex;

  # Gets the index and returns the short name in that position
  getShortNameFromIndex = position: builtins.elemAt validTitlebarButtons.shortNames (strings.toInt position);

  virtualDesktopNameAttrs = names:
    builtins.listToAttrs
      (imap1 (i: v: (nameValuePair "Name_${builtins.toString i}" v)) names);
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "plasma" "kwin" "virtualDesktops" "animation" ]
      [ "programs" "plasma" "kwin" "effects" "desktopSwitching" "animation" ])
  ];

  options.programs.plasma.kwin = {
    titlebarButtons.right = mkOption {
      type = with types; nullOr (listOf (enum validTitlebarButtons.longNames));
      default = null;
      example = [ "help" "minimize" "maximize" "close" ];
      description = ''
        Title bar buttons to be placed on the right.
      '';
    };
    titlebarButtons.left = mkOption {
      type = with types; nullOr (listOf (enum validTitlebarButtons.longNames));
      default = null;
      example = [ "on-all-desktops" "keep-above-windows" ];
      description = ''
        Title bar buttons to be placed on the left.
      '';
    };

    effects = {
      shakeCursor.enable = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = "Enable the shake cursor effect.";
      };
      translucency.enable = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = "Make windows translucent under different conditions.";
      };
      minimization = {
        animation = mkOption {
          type = with types; nullOr (enum [ "squash" "magiclamp" ]);
          default = null;
          example = "magiclamp";
          description = "The effect when windows are minimized.";
        };
        duration = mkOption {
          type = with types; nullOr ints.positive;
          default = null;
          example = 50;
          description = ''
            The duration of the minimization effect in milliseconds. Only
            available when the minimization effect is magic lamp.
          '';
        };
      };
      wobblyWindows.enable = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = "Deform windows while they are moving.";
      };
      fps.enable = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = "Display KWin's fps in the corner of the screen;";
      };
      cube.enable = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = "Arrange desktops in a virtual cube.";
      };
      desktopSwitching.animation = mkOption {
        type = with types; nullOr (enum [ "fade" "slide" ]);
        default = null;
        example = "fade";
        description = "The animation used when switching virtual desktop.";
      };
      windowOpenClose = {
        animation = mkOption {
          type = with types; nullOr (enum [ "fade" "glide" "scale" ]);
          default = null;
          example = "glide";
          description = "The animation used when opening/closing windows.";
        };
      };
      fallApart.enable = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = "Closed windows fall into pieces.";
      };
      blur = {
        enable = mkOption {
          type = with types; nullOr bool;
          default = null;
          description = "Blurs the background behind semi-transparent windows.";
        };
      };
      snapHelper.enable = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = "Helps locate the center of the screen when moving a window.";
      };
      dimInactive.enable = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = "Darken inactive windows.";
      };
      dimAdminMode.enable = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = "Darken the entire when when requesting root privileges.";
      };
      slideBack.enable = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = "Slide back windows when another window is raised.";
      };
    };

    virtualDesktops = {
      rows = mkOption {
        type = with types; nullOr ints.positive;
        default = null;
        example = 2;
        description = "The amount of rows for the virtual desktops.";
      };
      names = mkOption {
        type = with types; nullOr (listOf str);
        default = null;
        example = [ "Desktop 1" "Desktop 2" "Desktop 3" "Desktop 4" ];
        description = ''
          The names of your virtual desktops. When set, the number of virtual
          desktops is automatically detected and doesn't need to be specified.
        '';
      };
      number = mkOption {
        type = with types; nullOr ints.positive;
        default = null;
        example = 8;
        description = ''
          The amount of virtual desktops. If the names attribute is set as
          well the number of desktops must be the same as the length of the
          names list.
        '';
      };
    };
  };

  config.assertions = [
    {
      assertion =
        cfg.kwin.virtualDesktops.number == null ||
        cfg.kwin.virtualDesktops.names == null ||
        cfg.kwin.virtualDesktops.number == (builtins.length cfg.kwin.virtualDesktops.names);
      message = "programs.plasma.virtualDesktops.number doesn't match the length of programs.plasma.virtualDesktops.names.";
    }
    {
      assertion =
        cfg.kwin.virtualDesktops.rows == null ||
        (cfg.kwin.virtualDesktops.names == null && cfg.kwin.virtualDesktops.number == null) ||
        (cfg.kwin.virtualDesktops.number != null && cfg.kwin.virtualDesktops.number >= cfg.kwin.virtualDesktops.rows) ||
        (cfg.kwin.virtualDesktops.names != null && (builtins.length cfg.kwin.virtualDesktops.names) >= cfg.kwin.virtualDesktops.rows);
      message = "KWin cannot have more rows virtual desktops.";
    }
    {
      assertion = cfg.kwin.effects.minimization.duration == null || cfg.kwin.effects.minimization.animation == "magiclamp";
      message = "programs.plasma.kwin.effects.minimization.duration is only supported for the magic lamp effect";
    }
  ];

  config.programs.plasma.configFile."kwinrc" = mkIf (cfg.enable)
    (mkMerge [
      # Titlebar buttons
      (
        mkIf (cfg.kwin.titlebarButtons.left != null) {
          "org.kde.kdecoration2".ButtonsOnLeft = strings.concatStrings (getShortNames cfg.kwin.titlebarButtons.left);
        }
      )
      (
        mkIf (cfg.kwin.titlebarButtons.right != null) {
          "org.kde.kdecoration2".ButtonsOnRight = strings.concatStrings (getShortNames cfg.kwin.titlebarButtons.right);
        }
      )

      # Effects
      (mkIf (cfg.kwin.effects.shakeCursor.enable != null) {
        Plugins.shakecursorEnabled = cfg.kwin.effects.shakeCursor.enable;
      })
      (mkIf (cfg.kwin.effects.minimization.animation != null) {
        Plugins = {
          magiclampEnabled = cfg.kwin.effects.minimization.animation == "magiclamp";
          squashEnabled = cfg.kwin.effects.minimization.animation == "squash";
        };
      })
      (mkIf (cfg.kwin.effects.minimization.duration != null) {
        Effect-magiclamp.AnimationDuration = cfg.kwin.effects.minimization.duration;
      })
      (mkIf (cfg.kwin.effects.wobblyWindows.enable != null) {
        Plugins.wobblywindowsEnabled = cfg.kwin.effects.wobblyWindows.enable;
      })
      (mkIf (cfg.kwin.effects.translucency.enable != null) {
        Plugins.translucencyEnabled = cfg.kwin.effects.translucency.enable;
      })
      (mkIf (cfg.kwin.effects.windowOpenClose.animation != null) {
        Plugins = {
          glideEnabled = cfg.kwin.effects.windowOpenClose.animation == "glide";
          fadeEnabled = cfg.kwin.effects.windowOpenClose.animation == "fade";
          scaleEnabled = cfg.kwin.effects.windowOpenClose.animation == "scale";
        };
      })
      (mkIf (cfg.kwin.effects.fps.enable != null) {
        Plugins.showfpsEnabled = cfg.kwin.effects.fps.enable;
      })
      (mkIf (cfg.kwin.effects.cube.enable != null) {
        Plugins.cubeEnabled = cfg.kwin.effects.cube.enable;
      })
      (mkIf (cfg.kwin.effects.desktopSwitching.animation != null) {
        Plugins.slideEnabled = cfg.kwin.effects.desktopSwitching.animation == "slide";
        Plugins.fadedesktopEnabled = cfg.kwin.effects.desktopSwitching.animation == "fade";
      })
      (mkIf (cfg.kwin.effects.fallApart.enable != null) {
        Plugins.fallapartEnabled = cfg.kwin.effects.fallApart.enable;
      })
      (mkIf (cfg.kwin.effects.snapHelper.enable != null) {
        Plugins.snaphelperEnabled = cfg.kwin.effects.snapHelper.enable;
      })
      (mkIf (cfg.kwin.effects.blur.enable != null) {
        Plugins.blurEnabled = cfg.kwin.effects.blur.enable;
      })
      (mkIf (cfg.kwin.effects.dimInactive.enable != null) {
        Plugins.diminactiveEnabled = cfg.kwin.effects.dimInactive.enable;
      })
      (mkIf (cfg.kwin.effects.dimAdminMode.enable != null) {
        Plugins.dimscreenEnabled = cfg.kwin.effects.dimAdminMode.enable;
      })
      (mkIf (cfg.kwin.effects.slideBack.enable != null) {
        Plugins.slidebackEnabled = cfg.kwin.effects.slideBack.enable;
      })

      # Virtual Desktops
      (mkIf (cfg.kwin.virtualDesktops.number != null) {
        Desktops.Number = cfg.kwin.virtualDesktops.number;
      })
      (mkIf (cfg.kwin.virtualDesktops.rows != null) {
        Desktops.Rows = cfg.kwin.virtualDesktops.rows;
      })
      (mkIf (cfg.kwin.virtualDesktops.names != null) {
        Desktops = mkMerge [
          {
            Number = builtins.length cfg.kwin.virtualDesktops.names;
          }
          (virtualDesktopNameAttrs cfg.kwin.virtualDesktops.names)
        ];
      })
    ]);
}
