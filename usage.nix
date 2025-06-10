_:
let
  domains = rec {
    main = "efael.net";
    client = "chat.${main}";
    call = "call.${main}";
    server = "matrix.${main}";
    auth = "auth.${main}";
    realm = "turn.${main}";
    mail = "mail.${main}";
    livekit = "livekit.${main}";
    livekit-jwt = "livekit-jwt.${main}";
  };

  # Various temporary keys
  keys = {
    realm = "the most niggerlicious thing is to use javascript and python :(";
  };
in {
  imports = [ ./module.nix ];

  services.efael-server = {
    enable = true;

    domains = domains;
    keys = keys;

    server = {
      enable = true;
      extraConfigFiles = "";
    };

    mail = (let domain = domains.main;
    in {
      enable = true;
      loginAccounts = {
        # "admin@${domain}" = {
        #   hashedPasswordFile = config.sops.secrets."matrix/mail/admin".path;
        #   aliases = [ "postmaster@${domain}" "orzklv@${domain}" ];
        # };
        # "support@${domain}" = {
        #   hashedPasswordFile = config.sops.secrets."matrix/mail/support".path;
        # };
        # "noreply@${domain}" = {
        #   sendOnly = true;
        #   hashedPasswordFile = config.sops.secrets."matrix/mail/support".path;
        # };
      };
    });
  };
}
