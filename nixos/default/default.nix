{ self, ... }:

{
  imports = [ self.nixosModules.wrappers ];
}
