## st  
  
### st README  
  
#### Requires scripts to be installed

```shell
sudo bash -c "$(curl -LSs "https://github.com/dfmgr/installer/raw/main/install.sh")" && sudo dfmgr install installer
```

### Automatic install/update

```shell
dfmgr install st
```

OR

```shell
bash -c "$(curl -LSs "https://github.com/dfmgr/st/raw/main/install.sh")"
```
  
requirements:
  
Debian based:

```shell
apt install st
```  

Fedora Based:

```shell
yum install st
```  

Arch Based:

```shell
pacman -S st
```  

MacOS:  

```shell
brew install st
```
  
Manual install:  

  ```shell
APPDIR="$HOME/.local/share/CasjaysDev/dfmgr/st"
mv -fv "$HOME/.config/st" "$HOME/.config/st.bak"
git clone https://github.com/dfmgr/st "$APPDIR"
cp -Rfv "$APPDIR/etc/." "$HOME/.config/st/"
[ -d "$APPDIR/bin" ] && cp -Rfv "$APPDIR/bin/." "$HOME/.local/bin/"
```
  
<p align=center>
   <a href="https://travis-ci.com/github/dfmgr/st" target="_blank" rel="noopener noreferrer">
     <img src="https://travis-ci.com/dfmgr/st.svg?branch=master" alt="Build Status"></a><br />
  <a href="https://wiki.archlinux.org/index.php/st" target="_blank" rel="noopener noreferrer">st wiki</a>  |  
  <a href="st" target="_blank" rel="noopener noreferrer">st site</a>
</p>  
