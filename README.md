# timelink-project

 A timelink-mhk home with dev container. 

 This is a quick way to create a timelink-mhk instalation 
 to be run with docker.

## How to use

### Step one: download the Timelink installations files

1. Open VS CODE with a new window.
2. If on windows, we need to prevent conversion of line endings:

    2.1 Open a terminal in VS Code with CTRL+J or menu Terminal - New Terminal

    2.2 Type

        ```
        
        git config --global core.autocrlf false

        ```

3. Click on "Clone Git Repository..."

![Clone Git Repository...](img/vs-code-clone-git-project-1.png)

3. Click on "Clone from GitHub"

![](img/vs-code-clone-git-project-2.png)

4. Type "joaquimrcarvalho/timelink-project" 

5 . Create a folder for the new project.

![](img/vs-code-clone-git-project-3.png)

Click on "Select as Repository Destination"

6. When the download is finished click the 
"Open button" to confirm and open the project.

![](img/vs-code-clone-git-project-4.png)


## Step two: generate the container to run timelink-mhk

The project contains a specification of a
"Container" to run timelink-mhk.

A "Container" is like a virtual computer 
that is created in your machine.

VS Code detects the Container configuration file
and offers to reopen the project inside the "Container"

![Reopen project in container](img/vs-code-clone-git-project-5.png)

The first time this is done it will take 
a long time as VS-Code (actually Docker behind
the scenes) creates the virtual machine.


# TODO
- [ ] quando estabilizar remover .git e renomear repo para timelink-mhk-install
- [ ] caddy e portainer should no start by default (not easy to do). Uma maneira seria parar depois de mhk start except se var: expose-web=true
- [ ] a use tag deve ser latest
- [ ] o set host deve ser o nome que no noip está ligado a a local host local.timelink-server.net (not sure about this)
- [ ] copiar a demo-sources para o project mhk para estarem no build initial
- [ ] verificar que os links das listas de urls do mhk apontam correctamente para o vs code
- [ ] testar como se comporta o git numa instalação quando o repositório
de origem é atualizado
