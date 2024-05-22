#!/usr/bin/env fish

set stripe_cli_version $argv[1]
if set -q argv[2]
    set stripe_cli_rel $argv[2]
else
    set stripe_cli_rel 1
end

echo "Making a new release of stripe-cli $stripe_cli_version"

echo "Getting checksum..."
set checksum (curl -L https://github.com/stripe/stripe-cli/releases/download/v$stripe_cli_version/stripe-linux-checksums.txt | grep linux_x86_64.tar.gz | awk '{print $1}')

echo "Building PKGBUILD..."
sed "s/VERSION/$stripe_cli_version/g;s/REL/$stripe_cli_rel/g;s/CHECKSUM/$checksum/g" PKGBUILD.template >PKGBUILD

echo "Making and installing package locally..."
makepkg -i; or exit

echo "Generating .SRCINFO..."
makepkg --printsrcinfo >.SRCINFO

echo "Testing that the new version works with stripe -v..."
if not stripe -v
    echo "Failed to run stripe!"
    exit 1
end

read -p 'echo "Ready to commit/push? [Y/n] "' ok
if test $ok = y -o $ok = ""
    echo "Committing to git..."
    git commit -am "Release of $stripe_cli_version-$stripe_cli_rel"

    echo "Pushing..."
    git push origin master
    git push aur master
else
    echo "Exiting without pushing!"
    exit 1
end
