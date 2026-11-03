{
  pkgs,
  home-manager,
  self,
}:
# NixOS VM test for x86_64-linux. The system module installs the application and
# sets up uinput and the ydotool group for alice; alice's Home Manager module
# runs the application through its systemd user service after autologin. Needs
# KVM, so CI runs it in the linux-vm job rather than on the local host.
pkgs.testers.runNixOSTest {
  name = "openwhispr-nixos";

  nodes.machine =
    { ... }:
    {
      imports = [
        self.nixosModules.default
        home-manager.nixosModules.home-manager
      ];

      virtualisation.memorySize = 4096;
      services.xserver = {
        enable = true;
        windowManager.twm.enable = true;
      };
      services.displayManager = {
        defaultSession = "none+twm";
        autoLogin = {
          enable = true;
          user = "alice";
        };
      };

      users.users.alice = {
        isNormalUser = true;
      };

      programs.openwhispr = {
        enable = true;
        users = [ "alice" ];
      };

      home-manager.users.alice = {
        imports = [ self.homeManagerModules.default ];
        home.stateVersion = "26.05";
        programs.openwhispr.enable = true;
        # Fixture-only: see checks/hm-defaults.nix for why the manual is off.
        manual = {
          manpages.enable = false;
          json.enable = false;
        };
      };
    };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.succeed("command -v openwhispr")
    machine.succeed("test -e /dev/uinput")
    machine.wait_for_unit("home-manager-alice.service")
    machine.succeed("systemctl --user -M alice@ cat openwhispr.service")
    machine.wait_for_x()
    machine.wait_until_succeeds("pgrep -f -i openwhispr")
  '';
}
