{
  config,
  pkgs,
  modulesPath,
  lib ? pkgs.lib,
  ...
}:
with lib; let
  cfg = config.services.jkbx;
  defaultUser = "jkbx";
in {
  ###### interface
  options = {
    services.jkbx = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to run jkbx on boot.
        '';
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.callPackage ../package.nix {};
        description = "jkbx package";
      };

      user = mkOption {
        default = defaultUser;
        example = "john";
        type = types.str;
        description = ''
          The name of an existing user account to use to own the jkbx server
          process. If not specified, a default user will be created.
        '';
      };

      group = mkOption {
        default = defaultUser;
        example = "users";
        type = types.str;
        description = ''
          Group to own the jkbx process.
        '';
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/jkbx";
        description = ''
          Where jkbx should store its files.
        '';
      };

      logLevel = mkOption {
        type = types.str;
        default = "debug";
        description = ''
          Rust log level: https://docs.rs/env_logger/latest/env_logger/#enabling-logging
        '';
      };

      userFile = mkOption {
        type = types.path;
        description = ''
          Auth file for admin users.
          Create by running `jkbx useradd`.
        '';
      };

      nginx = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable nginx virtual host management.
            Further nginx configuration can be done by adapting <literal>services.nginx.virtualHosts.&lt;name&gt;</literal>.
            See <xref linkend="opt-services.nginx.virtualHosts"/> for further information.
          '';
        };
        virtualHost = mkOption {
          type = types.submodule (
            recursiveUpdate (import (modulesPath + "/services/web-servers/nginx/vhost-options.nix") {
              inherit config lib;
            }) {}
          );
          example = literalExpression ''
            {
              serverName = "jkbx.example.org";
              forceSSL = true;
              enableACME = true;
            }
          '';
          description = ''
            Nginx configuration can be done by adapting `services.nginx.virtualHosts.<name>`.
            See [](#opt-services.nginx.virtualHosts) for further information.
          '';
        };
      };
    };
  };

  ###### implementation

  config = mkIf cfg.enable {
    systemd.services.jkbx = {
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      description = "Music host for pokebot";
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "always";
        RestartSec = 10;

        User = cfg.user;
        Group = cfg.group;
        Environment = [
          "RUST_BACKTRACE=1"
          "RUST_LOG=${cfg.logLevel}"
          "USER_FILE=${cfg.userFile}"
        ];
        WorkingDirectory = cfg.dataDir;

        LockPersonality = true;
        ProtectSystem = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RemoveIPC = true;
        RestrictAddressFamilies = [];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
      };
    };

    users.users = optionalAttrs (cfg.user == defaultUser) {
      ${defaultUser} = {
        description = "jkbx server owner";
        group = defaultUser;
        home = cfg.dataDir;
        createHome = true;
        isSystemUser = true;
      };
    };

    users.groups = optionalAttrs (cfg.user == defaultUser) {
      ${defaultUser} = {
        members = [defaultUser];
      };
    };

    services.nginx = mkIf cfg.nginx.enable {
      enable = true;
      virtualHosts.${cfg.nginx.virtualHost.serverName} = lib.mkMerge [
        cfg.nginx.virtualHost
        {
          locations."/" = {
            proxyPass = "http://127.0.0.1:8089";
            recommendedProxySettings = true;
          };
        }
      ];
    };
  };
}
