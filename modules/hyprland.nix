# Hyprland desktop — the full graphical user environment, usable from first boot.
#
# Stack (all verified against the pinned nixpkgs, hyprland 0.55 / NixOS 26.05):
#   greetd + tuigreet   TTY login manager — lists sessions, remembers the choice
#   Hyprland (UWSM)     compositor as a systemd user session: uwsm binds it to
#                       graphical-session.target, XDG autostart, clean shutdown.
#                       ALWAYS pick the "Hyprland (UWSM)" session in the greeter.
#   pipewire            audio (+ pulse/alsa compat), wireplumber session manager
#   waybar/mako/fuzzel  bar, notifications, launcher
#   hyprlock/hypridle   lock screen + idle management (lock 5 min, screen off 10)
#
# Config strategy — same philosophy as neovim.nix, no home-manager:
# every dotfile lives in /etc (this repo), pinned by the system generation.
# Hyprland insists on ~/.config/hypr/hyprland.conf, so a tmpfiles "L" rule
# plants a SYMLINK there pointing at /etc/hypr/hyprland.conf. "L" never
# overwrites: the day you want an imperative config, replace the symlink with
# a real file and the system stops managing it. Everything else (waybar, mako,
# hypridle, hyprlock) is passed an explicit --config/-c flag, so there is no
# ambiguity about which file is live. After a rebuild run `hyprctl reload` —
# the /etc symlink flips atomically but Hyprland's file watch may not fire.
{ config, lib, pkgs, ... }:

{
  ############################
  # Session: Hyprland under UWSM, greetd/tuigreet to log in
  ############################
  programs.hyprland = {
    enable = true;
    withUWSM = true;      # systemd-managed session; provides "Hyprland (UWSM)"
    # xwayland.enable defaults to true — keep it for the odd X11-only app
  };

  services.greetd = {
    enable = true;
    useTextGreeter = true;   # tuigreet is a TUI; stops boot logs trampling it
    settings.default_session.command = lib.concatStringsSep " " [
      (lib.getExe pkgs.tuigreet)
      "--time"
      "--remember"                # pre-fill last username
      "--remember-user-session"   # re-select last session per user (F3 to change)
      "--asterisks"
      # uwsm's pathsToLink exposes every session desktop entry here:
      "--sessions /run/current-system/sw/share/wayland-sessions"
    ];
  };

  # Electron/Chromium apps: run native Wayland instead of XWayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  ############################
  # Hardware enablement the desktop needs
  ############################
  hardware.graphics.enable = true;   # Mesa/EGL; Intel iGPU needs nothing more

  # Audio — pipewire replaces pulseaudio, keeps pulse+alsa app compat
  security.rtkit.enable = true;      # realtime scheduling for the audio daemon
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;    # blueman-applet autostarts via XDG autostart

  # polkit: GUI apps need an agent to ask for privilege escalation
  security.polkit.enable = true;

  # Screen sharing / file pickers. programs.hyprland already wires the hyprland
  # portal; the GTK portal supplies FileChooser, which hyprland's doesn't implement.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  ############################
  # Fonts — one good mono (with icons for waybar), Noto for everything else
  ############################
  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
    ];
    fontconfig.defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  ############################
  # Desktop toolkit — everything the binds/exec-once below reference
  ############################
  environment.systemPackages = with pkgs; [
    kitty                  # terminal ($mod+Return)
    fuzzel                 # launcher ($mod+D) + dmenu for clipboard history
    waybar                 # status bar
    mako                   # notifications
    libnotify              # notify-send (screenshot feedback)
    hyprlock               # lock screen
    hypridle               # idle daemon (locks, screen off)
    hyprpolkitagent        # polkit auth dialogs
    wl-clipboard           # wl-copy / wl-paste
    cliphist               # clipboard history ($mod+Shift+V)
    grim                   # screenshot: capture
    slurp                  # screenshot: region select
    brightnessctl          # XF86MonBrightness keys
    playerctl              # XF86Audio media keys
    pavucontrol            # audio mixer GUI
    networkmanagerapplet   # nm-applet tray icon
    adwaita-icon-theme     # icons + cursor theme
    xdg-utils              # xdg-open
  ];

  ############################
  # ~/.config/hypr/hyprland.conf → /etc/hypr/hyprland.conf (see header)
  ############################
  systemd.tmpfiles.rules = [
    "d /home/dkopka/.config 0755 dkopka users -"
    "d /home/dkopka/.config/hypr 0755 dkopka users -"
    "L /home/dkopka/.config/hypr/hyprland.conf - - - - /etc/hypr/hyprland.conf"
  ];

  environment.etc."hypr/hyprland.conf".text = ''
    # Managed by nixos-config modules/hyprland.nix — edit there, rebuild,
    # then `hyprctl reload`. To go imperative: replace the ~/.config/hypr
    # symlink with a real file.

    monitor = , preferred, auto, 1   # laptop panel; scale to 2 on HiDPI

    $mod = SUPER
    $terminal = uwsm app -- kitty
    $menu = fuzzel --launch-prefix='uwsm app -- '

    # Session services. `uwsm app` puts each in its own systemd scope in
    # app-graphical.slice, so a crashing bar can never take the compositor down.
    exec-once = uwsm app -- waybar -c /etc/xdg/waybar/config -s /etc/xdg/waybar/style.css
    exec-once = uwsm app -- mako --config /etc/xdg/mako/config
    exec-once = uwsm app -- hypridle --config /etc/hypr/hypridle.conf
    exec-once = uwsm app -- ${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent
    exec-once = uwsm app -- nm-applet
    exec-once = uwsm app -- wl-paste --type text --watch cliphist store
    exec-once = uwsm app -- wl-paste --type image --watch cliphist store

    env = XCURSOR_THEME,Adwaita
    env = XCURSOR_SIZE,24

    input {
        kb_layout = pl               # matches console.keyMap = pl2
        follow_mouse = 1
        touchpad {
            natural_scroll = true
            tap-to-click = true
            disable_while_typing = true
        }
    }

    # three-finger horizontal swipe switches workspaces
    gesture = 3, horizontal, workspace

    general {
        gaps_in = 4
        gaps_out = 8
        border_size = 2
        col.active_border = rgba(7aa2f7ee)
        col.inactive_border = rgba(3b4261aa)
        resize_on_border = true
        layout = dwindle
    }

    decoration {
        rounding = 8
        blur {
            enabled = true
            size = 6
            passes = 2
        }
    }

    animations {
        enabled = true               # stock animation set; tune later if desired
    }

    dwindle {
        pseudotile = true
        preserve_split = true
    }

    misc {
        force_default_wallpaper = 0  # plain background; add hyprpaper when wanted
    }

    ####################
    # Keybinds — $mod = Super. hjkl everywhere (you live in vim anyway).
    ####################
    bind = $mod, Return, exec, $terminal
    bind = $mod, D, exec, $menu
    bind = $mod, Q, killactive,
    bind = $mod, F, fullscreen,
    bind = $mod, V, togglefloating,
    bind = $mod, T, togglesplit,
    bind = $mod, Escape, exec, loginctl lock-session
    bind = $mod SHIFT, E, exec, uwsm stop     # clean logout, never kill Hyprland

    # focus
    bind = $mod, H, movefocus, l
    bind = $mod, L, movefocus, r
    bind = $mod, K, movefocus, u
    bind = $mod, J, movefocus, d

    # move window
    bind = $mod SHIFT, H, movewindow, l
    bind = $mod SHIFT, L, movewindow, r
    bind = $mod SHIFT, K, movewindow, u
    bind = $mod SHIFT, J, movewindow, d

    # resize
    bind = $mod CTRL, H, resizeactive, -40 0
    bind = $mod CTRL, L, resizeactive, 40 0
    bind = $mod CTRL, K, resizeactive, 0 -40
    bind = $mod CTRL, J, resizeactive, 0 40

    # workspaces
    bind = $mod, 1, workspace, 1
    bind = $mod, 2, workspace, 2
    bind = $mod, 3, workspace, 3
    bind = $mod, 4, workspace, 4
    bind = $mod, 5, workspace, 5
    bind = $mod, 6, workspace, 6
    bind = $mod, 7, workspace, 7
    bind = $mod, 8, workspace, 8
    bind = $mod, 9, workspace, 9
    bind = $mod, 0, workspace, 10
    bind = $mod, Tab, workspace, previous

    bind = $mod SHIFT, 1, movetoworkspace, 1
    bind = $mod SHIFT, 2, movetoworkspace, 2
    bind = $mod SHIFT, 3, movetoworkspace, 3
    bind = $mod SHIFT, 4, movetoworkspace, 4
    bind = $mod SHIFT, 5, movetoworkspace, 5
    bind = $mod SHIFT, 6, movetoworkspace, 6
    bind = $mod SHIFT, 7, movetoworkspace, 7
    bind = $mod SHIFT, 8, movetoworkspace, 8
    bind = $mod SHIFT, 9, movetoworkspace, 9
    bind = $mod SHIFT, 0, movetoworkspace, 10

    # scratchpad
    bind = $mod, S, togglespecialworkspace, magic
    bind = $mod SHIFT, S, movetoworkspace, special:magic

    # mouse: drag to move/resize, wheel over the bar/desktop to switch ws
    bindm = $mod, mouse:272, movewindow
    bindm = $mod, mouse:273, resizewindow
    bind = $mod, mouse_down, workspace, e+1
    bind = $mod, mouse_up, workspace, e-1

    # clipboard history
    bind = $mod SHIFT, V, exec, cliphist list | fuzzel --dmenu | cliphist decode | wl-copy

    # screenshots → clipboard
    bind = , Print, exec, grim -g "$(slurp)" - | wl-copy && notify-send "Screenshot" "region copied to clipboard"
    bind = SHIFT, Print, exec, grim - | wl-copy && notify-send "Screenshot" "screen copied to clipboard"

    # laptop function keys (bindel repeats while held, bindl works when locked)
    bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
    bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    bindl = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
    bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
    bindl = , XF86AudioPlay, exec, playerctl play-pause
    bindl = , XF86AudioNext, exec, playerctl next
    bindl = , XF86AudioPrev, exec, playerctl previous
  '';

  ############################
  # Idle: lock at 5 min, screen off at 10. NO idle-suspend — this machine
  # doubles as a lid-closed server (services.nix ignores the lid on AC);
  # an idle suspend would kill SSH sessions. Suspend stays a deliberate act.
  ############################
  environment.etc."hypr/hypridle.conf".text = ''
    general {
        lock_cmd = pidof hyprlock || hyprlock --config /etc/hypr/hyprlock.conf
        before_sleep_cmd = loginctl lock-session
        after_sleep_cmd = hyprctl dispatch dpms on
    }

    listener {
        timeout = 300
        on-timeout = loginctl lock-session
    }

    listener {
        timeout = 600
        on-timeout = hyprctl dispatch dpms off
        on-resume = hyprctl dispatch dpms on
    }
  '';

  environment.etc."hypr/hyprlock.conf".text = ''
    background {
        color = rgba(26, 27, 38, 1.0)
    }

    input-field {
        size = 300, 48
        outline_thickness = 2
        outer_color = rgba(122, 162, 247, 1.0)
        inner_color = rgba(36, 40, 59, 1.0)
        font_color = rgba(192, 202, 245, 1.0)
        placeholder_text = <i>password…</i>
        fade_on_empty = true
        position = 0, -40
        halign = center
        valign = center
    }

    label {
        text = $TIME
        color = rgba(192, 202, 245, 1.0)
        font_size = 64
        font_family = JetBrainsMono Nerd Font
        position = 0, 120
        halign = center
        valign = center
    }
  '';

  ############################
  # Waybar — workspaces left, window title center, system state right
  ############################
  environment.etc."xdg/waybar/config".text = ''
    {
        "layer": "top",
        "position": "top",
        "height": 28,
        "modules-left": ["hyprland/workspaces"],
        "modules-center": ["hyprland/window"],
        "modules-right": ["tray", "pulseaudio", "network", "bluetooth", "battery", "clock"],

        "hyprland/workspaces": {
            "format": "{id}"
        },
        "hyprland/window": {
            "max-length": 60
        },
        "tray": {
            "spacing": 8
        },
        "pulseaudio": {
            "format": "vol {volume}%",
            "format-muted": "vol mute",
            "on-click": "pavucontrol"
        },
        "network": {
            "format-wifi": "wifi {signalStrength}%",
            "format-ethernet": "eth",
            "format-disconnected": "offline",
            "tooltip-format": "{ifname}: {ipaddr}"
        },
        "bluetooth": {
            "format": "bt {status}",
            "format-connected": "bt {num_connections}",
            "on-click": "blueman-manager"
        },
        "battery": {
            "states": { "warning": 25, "critical": 10 },
            "format": "bat {capacity}%",
            "format-charging": "chr {capacity}%"
        },
        "clock": {
            "format": "{:%a %d %b  %H:%M}",
            "tooltip-format": "<tt>{calendar}</tt>"
        }
    }
  '';

  environment.etc."xdg/waybar/style.css".text = ''
    * {
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 13px;
        min-height: 0;
    }
    window#waybar {
        background: rgba(26, 27, 38, 0.9);
        color: #c0caf5;
    }
    #workspaces button {
        padding: 0 8px;
        color: #565f89;
        background: transparent;
        border: none;
        border-radius: 0;
    }
    #workspaces button.active {
        color: #7aa2f7;
        border-bottom: 2px solid #7aa2f7;
    }
    #workspaces button.urgent {
        color: #f7768e;
    }
    #tray, #pulseaudio, #network, #bluetooth, #battery, #clock {
        padding: 0 10px;
    }
    #battery.warning {
        color: #e0af68;
    }
    #battery.critical {
        color: #f7768e;
    }
  '';

  ############################
  # Mako notifications
  ############################
  environment.etc."xdg/mako/config".text = ''
    font=JetBrainsMono Nerd Font 11
    background-color=#24283bee
    text-color=#c0caf5
    border-color=#7aa2f7
    border-radius=8
    default-timeout=6000
    max-visible=5

    [urgency=critical]
    border-color=#f7768e
    default-timeout=0
  '';
}
