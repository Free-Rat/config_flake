{ inputs, pkgs, ... }:
let
  domain = "free-rat.dev";

  # Every subresource the site loads is same-origin (checked against the built
  # package). Pages carry inline <style> blocks, hence 'unsafe-inline' for
  # styles only; scripts stay restricted to /animations.js and friends.
  # Blog posts may contain raw HTML (site/lib/markdown.nix) — this CSP is the
  # backstop if one ever smuggles a <script> or an off-site embed.
  csp = builtins.concatStringsSep "; " [
    "default-src 'self'"
    "script-src 'self'"
    "style-src 'self' 'unsafe-inline'"
    "img-src 'self' data:"
    "font-src 'self'"
    "connect-src 'self'"
    "object-src 'none'"
    "base-uri 'self'"
    "form-action 'none'"
    "frame-ancestors 'none'"
  ];
in
{
  imports = [
    inputs.personal-website.nixosModules.website
  ];

  services.personal-website = {
    enable = true;
    inherit domain;
    package = inputs.personal-website.packages.${pkgs.stdenv.hostPlatform.system}.website;
  };

  # Appended to the upstream module's `root` + `file_server` block
  # (extraConfig is types.lines, so the two merge; Caddy orders directives itself).
  services.caddy.virtualHosts.${domain}.extraConfig = ''
    # Compresses text types (HTML, CSS, JS, SVG, XML); PDFs/fonts/PNGs are skipped.
    encode zstd gzip

    header {
      Content-Security-Policy "${csp}"
      X-Content-Type-Options "nosniff"
      Referrer-Policy "strict-origin-when-cross-origin"
      Permissions-Policy "camera=(), microphone=(), geolocation=()"
      -Server
    }

    # URLs aren't content-hashed and files come from the Nix store (mtime 1970),
    # so keep lifetimes modest rather than `immutable`.
    @heavy path *.pdf *.woff2 *.png *.jpg *.jpeg *.webp *.svg
    header @heavy Cache-Control "public, max-age=86400"

    @light path *.html *.css *.js *.xml / */
    header @light Cache-Control "public, max-age=300"
  '';
}
