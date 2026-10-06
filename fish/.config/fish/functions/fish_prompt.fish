# Synthwave prompt, kept light:  ~/…/opensource/dotfiles rice/niri* ❯
# folder in ice, git branch dim purple (only in a repo, * when dirty), ❯ magenta (red after a failure)
function fish_prompt
    set -l last $status
    set_color 76e6f2; printf '%s' (prompt_pwd --full-length-dirs 2)
    if set -l branch (command git symbolic-ref --short HEAD 2>/dev/null; or command git rev-parse --short HEAD 2>/dev/null)
        set_color 8b8bc7; printf ' %s' $branch
        command git status --porcelain --untracked-files=no --ignore-submodules 2>/dev/null | string length -q; and printf '*'
    end
    test $last -eq 0; and set_color e040fb; or set_color ff4f79
    printf ' ❯ '
    set_color normal
end
