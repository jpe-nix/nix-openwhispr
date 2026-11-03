# Home Manager module for OpenWhispr. It takes this flake so that the default
# application and model packages resolve to the flake's own outputs without an
# overlay: `import ./modules/home-manager { inherit self; }`.
{ self }:
{
  imports = [
    (import ./options.nix { inherit self; })
    ./env.nix
    ./models.nix
    ./service.nix
    ./compat.nix
  ];
}
