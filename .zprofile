# allow cursor movement when `dash -l`
if [ "$0" = "-dash" ] || [ "$0" = "dash" ];
then
  set -o emacs
fi;

export PATH="$PATH":"$HOME"/.local/bin:/bin
export SUDO_EDITOR="/usr/bin/nvim -u NONE"
export EDITOR="/usr/bin/nvim"
export VISUAL="$EDITOR"
export BROWSER="/usr/bin/qutebrowser"
export TERMINAL="/usr/local/bin/st"
export XCURSOR_THEME="BMZ-cursor"
export MOZ_USE_XINPUT2=1
# export MOZ_ENABLE_WAYLAND=1

# export PYTHONSTARTUP=~/.pythonrc
# export SAL_USE_VCLPLUGIN=gtk # libreoffice
# export _JAVA_AWT_WM_NONREPARENTING=1 # pycharm
# export WINIT_X11_SCALE_FACTOR=1

# # autostart venv in new tmux window
# if [ -f ./env/bin/activate ]; then
#     source ./env/bin/activate
# fi

# auto start xorg on tty1 when logging in
[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && sx && [ $? = 0 ] && exit;

