self:
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.holesail;
  defaultPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.holesail;

  tunnelOpts = { name, config, ... }: {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable this holesail tunnel.";
      };

      role = mkOption {
        type = types.enum [ "server" "client" "filemanager" ];
        description = "Tunnel role: server exposes a local port, client connects to a remote tunnel, filemanager shares a directory.";
      };

      port = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = "Port number. Required for server (local port to expose). Default 5409 for filemanager. Optional for client (auto-detect from key).";
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Bind address. Server: local address of service to expose. Client: local address for the tunnel endpoint.";
      };

      keyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing the connection key (>= 32 chars or hs:// URL). Read at runtime. Required for client. Optional for server/filemanager (auto-generates if unset).";
      };

      udp = mkOption {
        type = types.bool;
        default = false;
        description = "Use UDP instead of TCP. Cannot combine with filemanager role.";
      };

      public = mkOption {
        type = types.bool;
        default = false;
        description = "Server/filemanager only: announce to DHT (disables private mode). Not valid for client role (auto-detected from hs:// URL).";
      };

      log = mkOption {
        type = types.nullOr (types.ints.between 0 3);
        default = null;
        description = "Log level: 0=DEBUG 1=INFO 2=WARN 3=ERROR. null disables logging.";
      };

      directory = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Directory to share. Required when role is filemanager.";
      };

      username = mkOption {
        type = types.str;
        default = "admin";
        description = "Filemanager login username.";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing the filemanager password. Read at runtime. Required for filemanager role.";
      };

      filemanagerRole = mkOption {
        type = types.enum [ "admin" "user" ];
        default = "user";
        description = "Role assigned to the filemanager user account.";
      };

      user = mkOption {
        type = types.str;
        default = "holesail";
        description = "User account to run the service as.";
      };

      group = mkOption {
        type = types.str;
        default = "holesail";
        description = "Group to run the service as.";
      };

      package = mkOption {
        type = types.package;
        default = defaultPackage;
        description = "The holesail package to use.";
      };
    };
  };

  enabledTunnels = filterAttrs (_: t: t.enable) cfg.tunnels;

  mkCommand = name: t:
    let
      keySource =
        if t.keyFile != null then ''"$(cat ${t.keyFile})"''
        else ''"$(cat /var/lib/holesail-${name}/key)"'';
      port = if t.port != null then t.port else 5409;
    in
    if t.role == "server" then
      lib.concatStringsSep " " (lib.filter (s: s != "") [
        "${lib.getExe t.package} --live ${toString t.port}"
        "--host ${t.host}"
        "--key ${keySource}"
        (lib.optionalString t.udp "--udp")
        (lib.optionalString t.public "--public")
        (lib.optionalString (t.log != null) "--log ${toString t.log}")
      ])
    else if t.role == "client" then
      lib.concatStringsSep " " (lib.filter (s: s != "") [
        "${lib.getExe t.package} --connect ${keySource}"
        (lib.optionalString (t.port != null) "--port ${toString t.port}")
        "--host ${t.host}"
        (lib.optionalString t.udp "--udp")
        (lib.optionalString t.public "--public")
        (lib.optionalString (t.log != null) "--log ${toString t.log}")
      ])
    else # filemanager
      lib.concatStringsSep " " (lib.filter (s: s != "") [
        "${lib.getExe t.package} --filemanager ${t.directory}"
        "--port ${toString port}"
        "--host ${t.host}"
        "--key ${keySource}"
        "--username ${t.username}"
        ''--password "$(cat ${t.passwordFile})"''
        "--role ${t.filemanagerRole}"
        (lib.optionalString t.public "--public")
        (lib.optionalString (t.log != null) "--log ${toString t.log}")
      ]);

in {
  options.services.holesail.tunnels = mkOption {
    type = types.attrsOf (types.submodule tunnelOpts);
    default = {};
    description = "Holesail tunnel instances.";
  };

  config = mkIf (enabledTunnels != {}) {
    assertions = concatLists (mapAttrsToList (name: t: [
      {
        assertion = t.role == "server" -> t.port != null;
        message = "services.holesail.tunnels.${name}: server role requires 'port' to be set.";
      }
      {
        assertion = t.role == "client" -> t.keyFile != null;
        message = "services.holesail.tunnels.${name}: client role requires 'keyFile' to be set.";
      }
      {
        assertion = t.role == "filemanager" -> t.directory != null;
        message = "services.holesail.tunnels.${name}: filemanager role requires 'directory' to be set.";
      }
      {
        assertion = t.role == "filemanager" -> t.passwordFile != null;
        message = "services.holesail.tunnels.${name}: filemanager role requires 'passwordFile' to be set.";
      }
      {
        assertion = t.role == "filemanager" -> !t.udp;
        message = "services.holesail.tunnels.${name}: filemanager role cannot use UDP.";
      }
      {
        assertion = !(t.public && t.keyFile != null);
        message = "services.holesail.tunnels.${name}: 'public' and 'keyFile' are mutually exclusive.";
      }
      {
        assertion = t.directory != null -> t.role == "filemanager";
        message = "services.holesail.tunnels.${name}: 'directory' is only valid for filemanager role.";
      }
      {
        assertion = t.passwordFile != null -> t.role == "filemanager";
        message = "services.holesail.tunnels.${name}: 'passwordFile' is only valid for filemanager role.";
      }
      {
        assertion = t.role == "client" -> !t.public;
        message = "services.holesail.tunnels.${name}: 'public' on client role is auto-detected from the hs:// URL. Remove it.";
      }
    ]) enabledTunnels);

    systemd.services = mapAttrs' (name: t:
      nameValuePair "holesail-${name}" {
        description = "Holesail ${t.role} tunnel (${name})";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = [ t.package ];

        preStart = lib.optionalString (t.keyFile == null && t.role != "client") ''
          if [ ! -f /var/lib/holesail-${name}/key ]; then
            head -c 1024 /dev/urandom | tr -dc 'ybndrfg8ejkmcpqxot1uwisza345h769' | head -c 52 > /var/lib/holesail-${name}/key
            chmod 600 /var/lib/holesail-${name}/key
          fi
        '';

        script = mkCommand name t;

        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = 10;
          User = t.user;
          Group = t.group;
          StateDirectory = "holesail-${name}";

          # Hardening
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
        } // lib.optionalAttrs (t.keyFile != null) {
          ReadOnlyPaths = [ t.keyFile ]
            ++ lib.optional (t.passwordFile != null) t.passwordFile;
        } // lib.optionalAttrs (t.passwordFile != null && t.keyFile == null) {
          ReadOnlyPaths = [ t.passwordFile ];
        } // lib.optionalAttrs (t.role == "filemanager" && t.directory != null) {
          ReadWritePaths = [ t.directory ];
        };
      }
    ) enabledTunnels;

    users.users = mkIf (any (t: t.user == "holesail") (attrValues enabledTunnels)) {
      holesail = {
        isSystemUser = true;
        group = "holesail";
        home = "/var/lib/holesail";
        createHome = true;
      };
    };

    users.groups = mkIf (any (t: t.group == "holesail") (attrValues enabledTunnels)) {
      holesail = {};
    };

    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.holesail-status
    ];
  };
}
