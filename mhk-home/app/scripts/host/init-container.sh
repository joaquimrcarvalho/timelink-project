# Script to finish setup to devcontainer
# It cleans CRLF added by git clone on windows
# And calls manager-init.sh
# 
# Note that the script changes files in the user 
# home directory

# Clean CRLF see https://stackoverflow.com/questions/48692741/how-can-i-make-all-line-endings-eols-in-all-files-in-visual-studio-code-unix
git config core.autocrlf false
git rm --cached -r .         # Don’t forget the dot at the end
git reset --hard
cd mhk-home

. ./app/scripts/host/manager-init.sh