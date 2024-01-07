# timelink-project

 A timelink-mhk instalation with dev container. 

## Run timelink-MHK directly in a Virtual Machine over the internet

 This is a quick way to run timelink-mhk directly in a github codespace, inside a browser, no extra software needed.

 1. Go to https://github.com/joaquimrcarvalho/timelink-project 
 2. Fork the project with a name like "myproject-mhk-install"
 3. In the forked project click on "Code"
 4. Go to the "codespaces" tab
 5. Click on "New codespace"
 6. Wait for the codespace to be created
 7. Open the terminal and type "mhk start mhk"
 8. In the ports section of the terminal window click on http://localhost:8080 (or type `mhk version` and ctrl/commd+click on the MHK URL) 
 9. Login with username `demo` and password `timelink`
   

## Run the codespace in VS Code instead of the browser

 1. Install VS Code
 2. Install the "Codespaces" extension
 3. Follow instruction to login in Github
 4. Select the codespace created before
 5. In the terminal type "mhk start mhk"
 6. MHK can be accessed in the browser at http://localhost:8080 (or type `mhk version` and ctrl/commd+click on the MHK URL)
 7. Login with username `demo` and password `timelink`


## Run timelink-MHK in a Virtual Machine in your computer

The instructions above require internet connection and are subject to the limitations of the codespace environment, namely limit
number of hours per month in free github accounts. 

To run timelink-mhk in a virtual machine in your computer, with no limitations, follow the instructions below.

 1. Install VS Code
 2. Install the "Remote - Containers" extension
 3. Install Docker
 4. Install git
 5. Clone the project
 6. Open the project in VS Code
 7. Click on "Reopen in Container"
 8. Wait for the container to be created
 9. Open the terminal and type "mhk start mhk"
 10. Open http://localhost:8080 (or type mhk version and ctrl/commd+click on the MHK URL)
 11. Login with username `demo` and password `timelink`


On windows you might get an error related to the line endings. To fix this open a terminal in VS Code with CTRL+J or menu Terminal - New Terminal and type:

``` 
git config --global core.autocrlf false
```
and repeat the steps 5-10.

## Add a sources repository

For a repository with sources to be added
like

    https://github.com/joaquimrcarvalho/dehergne-locations.git 


Add it to mhk-home/sources with:

1. Open a terminal with (ctrl + j / cmd + j)
2. git subtree add --prefix mhk-home/sources/dehergne-locations https://github.com/joaquimrcarvalho/dehergne-locations.git  main --squash

To pull changes from the source repository do:

3. git subtree pull --prefix mhk-home/sources/dehergne-locations https://github.com/joaquimrcarvalho/dehergne-locations.git  main --squash

To push local changes to the local repository 
do

4. git subtree push --prefix mhk-home/sources/dehergne-locations https://github.com/joaquimrcarvalho/dehergne-locations.git  main --squash