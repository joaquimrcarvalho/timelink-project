# Script to finish setup to devcontainer

# Clean CRLF see https://stackoverflow.com/questions/48692741/how-can-i-make-all-line-endings-eols-in-all-files-in-visual-studio-code-unix
# fix permission on mhk-home
sudo chown vscode:vscode -R mhk-home
cd mhk-home

. ./app/scripts/host/manager-init.sh
echo "Open a new terminal and do 'mhk --help'"