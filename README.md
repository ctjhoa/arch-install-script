arch-install-script
===================

My archlinux install script

## Additional config

- Touchpad

```
# /etc/X11/xorg.conf.d/30-touchpad.conf

Section "InputClass"
  Identifier "Elantech Touchpad"
  Driver "libinput"
  MatchIsTouchpad "on"
  Option "DisableWhileTyping" "on"
  Option "MiddleEmulation" "on"
  Option "Tapping" "on"
  Option "TappingButtonMap" "lmr"
EndSection
```
