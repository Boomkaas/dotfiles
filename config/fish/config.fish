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
    set -gx EDITOR zed-wait
    set -gx VISUAL zed-wait
    set -gx IDE zeditor
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
    abbr st 'setting'
    abbr wf 'wifi'
    abbr bt 'bluetooth'
    abbr au 'audio'
    abbr cp 'clip'
    abbr popup 'tui-popup'
    abbr nc 'sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +3 && sudo nix-store --gc'
    abbr nrb 'sudo nixos-rebuild switch'
    abbr nd 'cd /etc/nixos'

    # NixOS & Custom Shortcuts
    # Note: awake, nixreb, epic, twitch, gfn, roblox are managed by Nix wrappers — use them directly.
    abbr addchans '/home/peng/Code/Dotfiles/nixos/scripts/channels.sh'
    abbr tdrops 'twitch'  # alias to the twitch Nix wrapper
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


    # Claude Code wrapper: remote-control sessions default to bypassPermissions
    function claude --description "Claude Code; 'rc' runs with all permissions allowed"
        if contains -- "$argv[1]" rc remote-control; and not string match -q -- '--permission-mode*' $argv
            command claude $argv --permission-mode bypassPermissions
        else
            command claude $argv
        end
    end

    # Smart LazyGit: opens current repo directly, or presents project selector if in $HOME / outside git
    function lazygit --description "Smart LazyGit: opens current repo, or presents project selector"
        if test (count $argv) -gt 0
            command lazygit $argv
            return
        end

        set -l inside_git (command git rev-parse --is-inside-work-tree 2>/dev/null)
        if test "$inside_git" = "true" -a "$PWD" != "$HOME"
            command lazygit
            return
        end

        if command -v repo >/dev/null 2>&1
            repo lazy
        else
            command lazygit
        end
    end
end
