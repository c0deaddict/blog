---
date: "2020-04-26T20:19:00Z"
draft: false
title: "Using Rofi to switch Pulseaudio default sink/source"
tags: ["rofi", "pulseaudio", "i3"]
topics: ["rofi", "Pulseaudio", "i3"]
---

Lately I have to video call a lot for work. From time to time it
happens that the default sink or source of Pulseaudio is not correctly
set resulting in no mic or no audio during a video call. The default
sink or source can be set via the `pactl` command line:

``` bash
pactl set-default-source alsa_input.usb-046d_0825_67D582F0-02.mono-fallback
```

However, that is a bit cumbersome, especially when you've just set up
a video call. Searching for better way I found [this
script](https://gist.github.com/Nervengift/844a597104631c36513c) which
uses [Rofi](https://github.com/davatorium/rofi) to switch the default
Pulseaudio sink.

I've made some modifications to the script:
- select a default source *or* sink
- have the current device selected in Rofi
- integrated it in my NixOS configuration
- bind it in i3 to `Cmd+Ctrl+i` for source and `Cmd+Ctrl+s` for sink

#### **`rofi-pulse.sh`**
``` bash
#!/usr/bin/env bash
#
# Choose pulseaudio sink/source via rofi.
# Changes default sink/source and moves all streams to that device.
#
# based on: https://gist.github.com/Nervengift/844a597104631c36513c
#

set -euo pipefail

readonly type="$1"
if [[ ! "$type" =~ (sink|source) ]]; then
    echo "error: unknown type: $type"
    exit 1
fi

function formatlist {
    awk "/^$type/ {s=\$1\" \"\$2;getline;gsub(/^ +/,\"\",\$0);print s\" \"\$0}"
}

list=$(ponymix -t $type list | formatlist)
default=$(ponymix defaults | formatlist)
# line number of default in list (note: row starts at 0)
default_row=$(echo "$list" | grep -nr "$default" - | cut -f1 -d: | awk '{print $0-1}')

device=$(
    echo "$list" \
        | rofi -dmenu -p "pulseaudio $type:" -selected-row $default_row \
        | grep -Po '[0-9]+(?=:)'
)

# Set device as default.
ponymix set-default -t $type -d $device

# Move all streams to the new sink/source.
case "$type" in
    sink)
        for input in $(ponymix list -t sink-input|grep -Po '[0-9]+(?=:)');do
            echo "moving stream sink $input -> $device"
            ponymix -t sink-input -d $input move $device
        done
        ;;

    source)
        for output in $(ponymix list -t source-output | grep -Po '[0-9]+(?=:)'); do
            echo "moving stream source $output <- $device"
            ponymix -t source-output -d $output move $device
        done
        ;;
esac
```

#### **`rofi-pulse.nix`**
``` nix
{ pkgs, ... }:

let

  # http://chriswarbo.net/projects/nixos/useful_hacks.html#wrapping-binaries
  wrap = { name, paths ? [], vars ? {}, file ? null, script ? null }:
    assert file != null || script != null ||
        abort "wrap needs 'file' or 'script' argument";
    let
      set  = n: v: "--set ${escapeShellArg (escapeShellArg n)} " +
                     "'\"'${escapeShellArg (escapeShellArg v)}'\"'";

      args = (map (p: "--prefix PATH : ${p}/bin") paths) ++
             (attrValues (mapAttrs set vars));

      scriptPkg = pkgs.writeScriptBin name (
        if script == null
        then builtins.readFile file
        else script
      );
    in
      pkgs.symlinkJoin {
        inherit name;
        paths = [ scriptPkg ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/${name} ${toString args}
        '';
      };

in

wrap {
  name = "rofi-pulse";
  paths = [ pkgs.ponymix ];
  file = ./rofi-pulse.sh;
}
```

#### **`i3_config.nix`**
```nix
xsession.windowManager.i3.config.keybindings = {
  "${mod}+Ctrl+i" = "exec ${rofi-pulse}/bin/rofi-pulse source";
  "${mod}+Ctrl+s" = "exec ${rofi-pulse}/bin/rofi-pulse sink";
};
```
