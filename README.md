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
| MosDNS | 网速测试 |
| Watchcat | WireGuard |
| Mihomo |  |

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
