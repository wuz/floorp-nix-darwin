{
  stdenv,
  pkgs,
  fetchurl,
  lib,
  policies ? { },
  ...
}:
let
  floorp = builtins.fromJSON (builtins.readFile ./floorp.json);
  isPoliciesEnabled = builtins.length (builtins.attrNames policies) > 0;
  policiesJson = builtins.toJSON { inherit policies; };
in
stdenv.mkDerivation rec {
  pname = "Floorp";
  version = floorp.version;
  buildInputs = [
    pkgs._7zz
    pkgs.undmg
  ];
  sourceRoot = ".";
  phases = [
    "unpackPhase"
    "installPhase"
  ];

  unpackPhase = ''
    runHook preUnpack

    undmg $src || 7zz x -snld $src

    runHook postUnpack
  '';

  installPhase =
    ''
      runHook preInstall

       mkdir -p "$out/Applications/${sourceRoot}"
      cp -R . "$out/Applications/${sourceRoot}"

        if [[ -e "$out/Applications/${sourceRoot}/Contents/MacOS/Floorp.app" ]]; then
          makeWrapper "$out/Applications/${sourceRoot}/Contents/MacOS/Floorp.app" $out/bin/Floorp.app
        elif [[ -e "$out/Applications/${sourceRoot}/Contents/MacOS/${lib.removeSuffix ".app" sourceRoot}" ]]; then
          makeWrapper "$out/Applications/${sourceRoot}/Contents/MacOS/${lib.removeSuffix ".app" sourceRoot}" $out/bin/Floorp.app
        fi

    ''
    + (
      if isPoliciesEnabled then
        ''
          mkdir -p "$out/Applications/Floorp.app/Contents/Resources/distribution"
          echo '${policiesJson}' > "$out/Applications/Floorp.app/Contents/Resources/distribution/policies.json"

          runHook postInstall
        ''
      else
        "runHook postInstall"
    );
  src = fetchurl {
    name = "Floorp-${version}.dmg";
    inherit (floorp) url sha256;
  };
  meta = {
    description = "Floorp is a new Firefox based browser from Japan with excellent privacy & flexibility.";
    homepage = "https://floorp.app/";
    platforms = lib.platforms.darwin;
  };
}
