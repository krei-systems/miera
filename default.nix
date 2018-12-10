{ system ? builtins.currentSystem, pkgs ? import <nixpkgs> {} }:

with pkgs;

stdenv.mkDerivation {
  name = "shell";

  buildInputs = [
    rlwrap

    sbcl
    ccl
    cmucl_binary
    ecl
    clisp
    mkcl
    abcl

    racket
    gerbil-unstable
    guile
    chicken
    scsh
    chez
    bigloo
    scheme48

    ncurses
    libfixposix
    jdk10

    binutils-unwrapped
  ];

  LD_LIBRARY_PATH = stdenv.lib.makeLibraryPath [
    openssl
    mesa_noglu
    SDL2
    SDL2_image
    SDL2_ttf
    libffi
    ncurses
    freeglut
    cairo
    glib

    gnome2.pango
    gnome3.gtk
    gnome3.libsoup
    gnome3.webkitgtk

    alsaLib
    libpulseaudio
  ];

  shellHook = ''
    export PS1="\[\033[1;32m\][\u \h \w]\n>\[\033[0m\] "
    function rl () { rlwrap -s 1000000 -c -b "(){}[].,=&^%0\;|" $@; }
  '';
}
