if status is-interactive
    # Starship custom prompt
    command -v starship &> /dev/null && starship init fish | source

    # Direnv + Zoxide (--cmd cd makes 'cd' smart; provides z/zi aliases too)
    command -v direnv &> /dev/null && direnv hook fish | source
    command -v zoxide &> /dev/null && zoxide init fish --cmd cd | source

    # Better ls
    command -v eza &> /dev/null && alias ls='eza --icons --group-directories-first -1'

    # Path
    fish_add_path ~/.local/bin
    fish_add_path ~/.cargo/bin
    fish_add_path ~/go/bin

    # Env
    set -gx EDITOR nvim
    set -gx VISUAL nvim
    set -gx GTK_USE_PORTAL 1
    set -gx MOZ_ENABLE_WAYLAND 1
    set -gx QT_QPA_PLATFORMTHEME gtk3
    set -gx DOTNET_ROOT $HOME/.dotnet

    # Abbrs
    abbr lg 'lazygit'
    abbr gd 'git diff'
    abbr ga 'git add .'
    abbr gc 'git commit -am'
    abbr gl 'git log'
    abbr gs 'git status'
    abbr gst 'git stash'
    abbr gsp 'git stash pop'
    abbr gp 'git push'
    abbr gpl 'git pull'
    abbr gsw 'git switch'
    abbr gsm 'git switch main'
    abbr gb 'git branch'
    abbr gbd 'git branch -d'
    abbr gco 'git checkout'
    abbr gsh 'git show'

    abbr l 'ls'
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'

    abbr c 'clear'
    abbr h 'history'
    abbr haku '~/.local/bin/haku.sh'
    abbr menu 'rofi -show drun'
    abbr openconfig '~/.local/bin/open_config.sh'
    abbr nc 'sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +3 && sudo nix-store --gc'
    abbr nrb 'sudo nixos-rebuild switch'
    abbr nd 'cd /etc/nixos'

    # NixOS & Custom Shortcuts
    # Note: awake, nixreb, epic, twitch, gfn, roblox are managed by Nix wrappers — use them directly.
    abbr addchans '/home/peng/Code/Dotfiles/nixos/scripts/channels.sh'
    abbr tdrops 'twitch'  # alias to the twitch Nix wrapper
    abbr tokens '/home/peng/Code/Dotfiles/nixos/scripts/agy-tokens.py'
    abbr agy-tokens '/home/peng/Code/Dotfiles/nixos/scripts/agy-tokens.py'
    abbr pet 'wayland-vpet'
    abbr delgar 'sudo nix-collect-garbage --delete-older-than 1d'

    # Tmux Shortcuts
    abbr t 'tmux'
    abbr ta 'tmux attach -t'
    abbr tls 'tmux ls'
    abbr tn 'tmux new-session -s'
    abbr tk 'tmux kill-session -t'

    # Yazi File Manager Wrapper (cd on exit)
    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end

    # Interactive Shell Hotkey:
    # Ctrl-o to open Yazi from the prompt
    bind \co 'y; commandline -f repaint'


    # Antigravity wrapper function
    function agy
        if test (count $argv) -gt 0; and test "$argv[1]" = "tokens" -o "$argv[1]" = "token" -o "$argv[1]" = "quota"
            /home/peng/Code/Dotfiles/nixos/scripts/agy-tokens.py $argv[2..-1]
        else
            command agy --add-dir "$PWD" $argv
        end
    end
    alias antigravity='agy'
end
