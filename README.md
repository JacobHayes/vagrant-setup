vagrant-setup
=============

Hacked together bash script to install Vagrant (1.6.2) with vagrant-omnibus, vagrant-berkshelf (2.0.1), and vagrant-vbguest.

As stated in mitchellh/vagrant#3769, recent builds of nokogiri break installations of vagrant plugins that depend on it, so this also includs a fix to lock nokogiri at version < 1.6.2

Also includes installation of OS X Command Line Tools for posterity.
