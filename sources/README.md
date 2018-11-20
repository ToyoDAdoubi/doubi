
# 一些 Debian 系统软件包镜像源(sources)

本页面是一些Debian系统的 apt-get 软件包镜像源(sources)。  
> 注意：本页面仅针对 Debian 7 / Debian 8 系统，Debian 9 请不要执行下面代码更换！

----

目前很多服务器的Debian系统所使用的 apt-get 软件包镜像源都是上一个Debian发布的 apt-get 稳定源： **wheezy** 。  
而目前最新的稳定源是 **jessie** ，**wheezy** 已经是旧稳定源了，很多软件包的版本都很老，一些新的软件包也没有，所以建议更换为 新稳定源： **jessie** 。

### 一键更换:
假设你的服务器是美国，例如选择镜像源： `us.sources.list` 。  
如果是其他地区，请更换下面代码中的 `us.sources.list` 中的 `us` 。
```
mv /etc/apt/sources.list /etc/apt/sources.list.bak && wget -N --no-check-certificate -O "/etc/apt/sources.list" "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/sources/us.sources.list"
```
上面代码的意思是，把原源文件重命名为 `sources.list.bak` ，然后下载新的源文件。  
如果下载失败，或者新的源文件使用有问题，可以通过这个命令恢复：
```
rm -rf /etc/apt/sources.list && mv /etc/apt/sources.list.bak /etc/apt/sources.list
```

### 手动更换:
打开你的 apt-get 镜像源文件，
```
vi /etc/apt/sources.list
```
然后按 `I键` 进入编辑模式，如果你没有安装vim，也无法通过 `apt-get install vim -y` 安装，那么你就只能通过 *SFTP* 下载这个文件本地编辑了。
```
deb http://ftp.us.debian.org/debian/ jessie main
deb-src http://ftp.us.debian.org/debian/ jessie main
 
deb http://security.debian.org/ jessie/updates main contrib
deb-src http://security.debian.org/ jessie/updates main contrib
 
# jessie-updates, previously known as 'volatile'
deb http://ftp.us.debian.org/debian/ jessie-updates main contrib
deb-src http://ftp.us.debian.org/debian/ jessie-updates main contrib
```
修改完毕之后，按 `ESC键` 退出编辑模式，然后输入 `:wq` (英文小写，包括引号)保存并退出，然后再试一试 `apt-get update` 是否正常。

### 其他问题：

如果你在执行 `apt-get update` 时，提示类似以下信息：
``` 
Media change：please insert the disc labeled‘Debian GNU/Linux X.x.x Wheezy — Official amd64 CD
```
那么说明你的 apt-get 镜像源文件(sources)里面设置了需要插入CD的内容。  
解决方法很容易，用上面的一键更换，或者手动更换打开文件后，注释掉提示错误的那几行即可。
