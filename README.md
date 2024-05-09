# opwrt_build_script    

### x86_64 固件下载:

https://github.com/JohnsonRan/opwrt_build_script/releases

```
【首次登陆】
地址：172.16.1.1（默认）
用户：root
密码：空

【分区挂载】
系统 -> 磁盘管理 -> 磁盘 -> 编辑
系统 -> 挂载点
```

---------------

#### 存档来自：https://init2.cooluc.com

- 优化系统内核
  - [x] Full Cone NAT
  - [x] TCP BBRv3
  - [x] TCP Brutal
  - [x] eBPF
  - [x] Shortcut-FE
  - [x] RTC 时钟
  - [x] O3、LTO、MOLD、LRNG

| ⚓ 服务 |  🩺 网络  |
|  :----  | :----  |
| Watchcat | 网速测试 |
| Mihomo | WireGuard |
| | UPnP |

------

### RTC 硬件时钟

**本固件支持 RTC 硬件时钟读取/同步，当设备断电时，重新通电启动系统时间不会错乱** *（注意：设备需要安装 RTC 电池后使用）*

**首次安装 RTC 电池写入时间命令**

```shell
hwclock -w -f /dev/rtc0
```

**测试时间读取（返回当前时间表示正常）**

```shell
hwclock -f /dev/rtc0
```


## 本地编译

### 环境安装（需要 `backports` 源）
```shell
sudo apt-get update
sudo apt-get install -y build-essential flex bison g++ gawk gcc-multilib g++-multilib gettext git libfuse-dev libncurses5-dev libssl-dev python3 python3-pip python3-ply python3-distutils python3-pyelftools rsync unzip zlib1g-dev file wget subversion patch upx-ucl autoconf automake curl asciidoc binutils bzip2 lib32gcc-s1 libc6-dev-i386 uglifyjs msmtp texinfo libreadline-dev libglib2.0-dev xmlto libelf-dev libtool autopoint antlr3 gperf ccache swig coreutils haveged scons libpython3-dev jq
```

### 安装 [LLVM/CLANG](https://github.com/sbwml/redhat-llvm-project)

```shell
# 下载并解压
sudo mkdir -p /opt/clang
curl -LO https://github.com/sbwml/redhat-llvm-project/releases/download/18.1.8/clang-18.1.8-x86_64-redhat-linux.tar.xz
sudo tar --strip-components=1 -C /opt/clang -xf clang-18.1.8-x86_64-redhat-linux.tar.xz
rm -rf clang-18.1.8-x86_64-redhat-linux.tar.xz

# 添加 BIN 到系统变量
export PATH="/opt/clang/bin:$PATH"

# clang 版本验证
clang --version

 clang version 18.1.8 (https://github.com/llvm/llvm-project 3b5b5c1ec4a3095ab096dd780e84d7ab81f3d7ff)
 Target: x86_64-redhat-linux-gnu
 Thread model: posix
 InstalledDir: /opt/clang/bin
```

### 开始构建
#### 下载源码
```shell
git clone https://github.com/JohnsonRan/opwrt_build_script
cd opwrt_build_script
```
#### 修改构建脚本文件：`openwrt/build.sh`

```diff
 # script url
 if [ "$isCN" = "CN" ]; then
-    export mirror=init.cooluc.com
+    export mirror=raw.githubusercontent.com/JohnsonRan/opwrt_build_script/master
 else
-    export mirror=init2.cooluc.com
+    export mirror=raw.githubusercontent.com/JohnsonRan/opwrt_build_script/master
 fi
```
#### 启动！
```shell
export LAN=172.16.1.1 KERNEL_CLANG_LTO=y USE_GCC15=y ENABLE_LTO=y ENABLE_MOLD=y ENABLE_BPF=y ENABLE_LRNG=y
bash openwrt/build.sh rc2 x86_64
```