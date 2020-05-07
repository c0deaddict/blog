---
date: "2020-05-07T16:30:22+02:00"
draft: false
title: "Zsh abbrev-alias"
tags: ["zsh", "nixos"]
topics: ["zsh", "nixos"]
---

About a year ago I read [this article about
`abbr`](https://www.sean.sh/log/when-an-alias-should-actually-be-an-abbr/)
by Sean Henderson. He makes some good points that one should not use
`alias` for shortcuts but `abbr`:

- Increased performance.
- Clean history: the full command is logged, not some non-sense shortcut like `gs`.
- Less conflicts: shortcuts get expanded, if you want to run another
  program with the same name as the shortcut you can edit the text
  after expansion.

[Fish shell](https://fishshell.com/) has `abbr` build in. Fish looks
really nice... but it is not POSIX compatible. I don't want to get
used to Fish syntax, and then log into a server and having to use
Bash/Zsh. Although I must say that the syntax look nicer than
POSIX/Bash/Zsh.

Recently I stumbled upon the
[zsh-abbrev-alias](https://github.com/momo-lab/zsh-abbrev-alias)
plugin by `momo-lab` which mimics Fish's `abbr` in Zsh. This is wonderful!

One thing that was not clear to me from the docs is how you can *NOT*
select an abbr. `momo-lab` quickly helped me with that: `C-x space` or
`C-x RET` does that.

Here is part of my NixOS config of Zsh with `abbrev-alias`:

``` nix
let

  abbrev-alias = pkgs.fetchFromGitHub {
    owner = "momo-lab";
    repo = "zsh-abbrev-alias";
    rev = "079a254143f8ab7907d6aceb25e86d5a804d0704";
    sha256 = "1ksf57zfrbfigi9mz3r9vrbmr6bw55nlgbzs5h9qcgszavgi7nvl";
  };

  abbrevs = {
    static = {
      gs="git status";
      gc="git commit -m";
      gf="git fetch";
      gm="git merge --no-ff --no-edit";
      gdd="git diff develop";
      gd="git diff";
      ga="git add";
      gaa="git add -A";
      gco="git checkout";
      gb="git --no-pager branch";
      gr="git remote";
      grh="git reset HEAD";
      grb="git rebase";
      gri="git rebase -i";
      grc="git rebase --continue";
      gra="git rebase --abort";

      db="docker build .";
      dc="docker-compose";
      dri="docker run -it --rm ";
      dei="docker-exec-fix-tty";
      rc="rancher-compose";

      sc="sudo systemctl";
      scu="systemctl --user";
      jc="journalctl";
      jcu="journalctl --user";

      serve="python3 -m http.server";
      open="xdg-open";

      clj="clojure -A:rebel";
      wi="whereis";

      ip4="ip -4 a";
      ip6="ip -6 a";

      k="kubectl";
      tf="terraform";

      dmesg="dmesg -wT";

      nb="nix-build";
      nbe="nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'";
      nbe32="nix-build -E 'with import <nixpkgs> {}; pkgsi686Linux.callPackage ./default.nix {}'";
      nba="nix-build '<nixpkgs>' -A";
      ns="nix-shell --command zsh -p";
      nsq="nix-store --query --references";
      nsqq="nix-store --query --referrers";
      nix-roots="nix-store --gc --print-roots";

      branch="git rev-parse --abbrev-ref HEAD";

      G="| grep";
    };

    eval = {
      B="$(git symbolic-ref --short HEAD 2> /dev/null)";
      build-me="nixos-deploy $(hostname) build";
      switch-me="nixos-deploy $(hostname) switch";
    };
  };

in

xdg.configFile.".zshrc".text = ''
  # .. zsh init ...

  # Load abbrev alias.
  source ${abbrev-alias}/abbrev-alias.plugin.zsh

  # Set up abbrevations.
  ${concatStringsSep "\n" (attrValues
    (mapAttrs (k: v: "abbrev-alias -g ${k}=\"${v}\"") abbrevs.static))}
  ${concatStringsSep "\n" (attrValues
    (mapAttrs (k: v: "abbrev-alias -ge ${k}=\"${v}\"") abbrevs.eval))}
''
```
