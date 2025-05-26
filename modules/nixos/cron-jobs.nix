{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {};

  config = {
    services.cron = {
      enable = true;
      systemCronJobs = [
        "0 0 */10 * * root nix-collect-garbage --delete-older-than 30d"
      ];
    };
  };
}
