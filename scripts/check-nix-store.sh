echo "store optimising"
nix-store --optimise

echo "printing haviest"
nix-store --query --requisites /run/current-system | xargs du -sh | sort -rh | head -n 50

