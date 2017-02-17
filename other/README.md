# 一些脚本的依赖都放到这里

jq-1.5.tar.gz
======

- 说明：JQ是一个Linux平台上的 JSON 格式解析器。
- 依赖于此软件的脚本为：ssr.sh

### 下载安装:
Debian/Ubuntu系统：
``` bash
apt-get install -y build-essential
wget --no-check-certificate -N "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/other/jq-1.5.tar.gz"
tar -xzf jq-1.5.tar.gz && cd jq-1.5
./configure --disable-maintainer-mode && make && make install
ldconfig
cd .. && rm -rf jq-1.5.tar.gz && rm -rf jq-1.5
```
