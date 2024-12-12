#!/bin/bash

# nikki
if curl -s "$mirror/openwrt/24-config-common" | grep -q "^CONFIG_PACKAGE_luci-app-nikki=y"; then
    git clone https://$github/morytyann/OpenWrt-nikki package/new/openwrt-nikki --depth=1
    mkdir -p files/etc/opkg/keys
    curl -skL https://github.com/nikkinikki-org/OpenWrt-nikki/raw/gh-pages/key-build.pub >files/etc/opkg/keys/ab017c88aab7a08b
    echo "src/gz nikki https://nikkinikki.pages.dev/openwrt-24.10/$arch/nikki" >>files/etc/opkg/customfeeds.conf
    mkdir -p files/etc/nikki/run/ui
    curl -skLo files/etc/nikki/run/Country.mmdb https://$github/NobyDa/geoip/raw/release/Private-GeoIP-CN.mmdb
    curl -skLo files/etc/nikki/run/GeoIP.dat https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.dat
    curl -skLo files/etc/nikki/run/GeoSite.dat https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat
    curl -skLo gh-pages.zip https://$github/Zephyruso/zashboard/archive/refs/heads/gh-pages.zip
    unzip gh-pages.zip
    mv zashboard-gh-pages files/etc/nikki/run/ui/zashboard
    rm -rf gh-pages.zip
    # make sure nikki is always latest
    git clone -b Alpha --depth=1 https://github.com/metacubex/mihomo --depth=1 nikki
    nikki_sha=$(git -C nikki rev-parse HEAD)
    nikki_short_sha=$(git -C nikki rev-parse --short HEAD)
    git -C nikki config tar.xz.command "xz -c"
    git -C nikki archive --output=nikki.tar.xz HEAD
    nikki_checksum=$(sha256sum nikki/nikki.tar.xz | cut -d ' ' -f 1)
    sed -i "s/PKG_SOURCE_DATE:=.*/PKG_SOURCE_DATE:=$(git -C nikki log -n 1 --format=%cs)/" package/new/openwrt-nikki/nikki/Makefile
    sed -i "s/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:=$nikki_sha/" package/new/openwrt-nikki/nikki/Makefile
    sed -i "s/PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=$nikki_checksum/" package/new/openwrt-nikki/nikki/Makefile
    sed -i "s/PKG_BUILD_VERSION:=.*/PKG_BUILD_VERSION:=alpha-$nikki_short_sha/" package/new/openwrt-nikki/nikki/Makefile
    rm -rf nikki
fi

# tailscale
if curl -s "$mirror/openwrt/24-config-common" | grep -q "^CONFIG_PACKAGE_luci-app-tailscale=y"; then
    git clone https://$github/asvow/luci-app-tailscale package/new/luci-app-tailscale --depth=1
    mkdir -p files/etc/hotplug.d/iface
    curl -skLo files/etc/hotplug.d/iface/99-tailscale-needs $mirror/openwrt/files/etc/hotplug.d/iface/99-tailscale-needs
    # make sure tailscale is always latest
    ts_version=$(curl -s https://api.github.com/repos/tailscale/tailscale/releases/latest | grep -oP '(?<="tag_name": ")[^"]*' | sed 's/^v//')
    ts_tarball="tailscale-${ts_version}.tar.gz"
    curl -skLo "${ts_tarball}" "https://codeload.github.com/tailscale/tailscale/tar.gz/v${ts_version}"
    ts_hash=$(sha256sum "${ts_tarball}" | awk '{print $1}')
    rm -rf "${ts_tarball}"
    sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=${ts_version}/" package/feeds/packages/tailscale/Makefile
    sed -i "s/PKG_HASH:=.*/PKG_HASH:=${ts_hash}/" package/feeds/packages/tailscale/Makefile
fi

# qosmate
if curl -s "$mirror/openwrt/24-config-common" | grep -q "^CONFIG_PACKAGE_luci-app-qosmate=y"; then
    git clone https://$github/hudra0/qosmate package/new/qosmate --depth=1
    git clone https://$github/hudra0/luci-app-qosmate package/new/luci-app-qosmate --depth=1
fi

# extra packages
git clone https://$github/JohnsonRan/packages_utils_boltbrowser package/new/boltbrowser
git clone https://$github/JohnsonRan/packages_net_speedtest-ex package/new/speedtest-ex
git clone https://$github/JohnsonRan/packages_utils_neko-status package/new/neko
git clone https://$github/JohnsonRan/InfinityDuck package/new/InfinityDuck --depth=1
rm -rf package/feeds/packages/v2ray-geodata
git clone https://$github/JohnsonRan/packages_net_v2ray-geodata package/new/v2ray-geodata --depth=1
sed -i "s/GEOX_VER:=.*/GEOX_VER:=$(date +%Y%m%d%H%M)/" package/new/v2ray-geodata/Makefile

# custom feed
curl -skL https://opkg.ihtw.moe/key-build.pub >files/etc/opkg/keys/351925c1f1557850 >files/etc/opkg/keys/351925c1f1557850
echo "src/gz infsubs https://opkg.ihtw.moe/openwrt-24.10/$arch/InfinitySubstance" >>files/etc/opkg/customfeeds.conf

# latest golang version
rm -rf feeds/packages/lang/golang/golang
git clone https://github.com/JohnsonRan/packages_lang_golang feeds/packages/lang/golang/golang

# sysupgrade keep files
echo "/etc/hotplug.d/iface/*.sh" >>files/etc/sysupgrade.conf
echo "/etc/nikki/run/cache.db" >>files/etc/sysupgrade.conf

# add UE-DDNS
mkdir -p files/usr/bin
curl -skLo files/usr/bin/ue-ddns ddns.03k.org
chmod +x files/usr/bin/ue-ddns

# ghp.ci is NOT stable
sed -i 's|raw.githubusercontent.com|raw.ihtw.moe/raw.githubusercontent.com|g' package/new/default-settings/default/zzz-default-settings
# hey TUNA
sed -i 's/mirrors.aliyun.com/mirrors.tuna.tsinghua.edu.cn/g' package/new/default-settings/default/zzz-default-settings

# argon new bg
#curl -skLo package/new/luci-theme-argon/luci-theme-argon/htdocs/luci-static/argon/img/bg.webp $mirror/openwrt/files/bg/bg.webp

# defaults
mkdir -p files/etc/uci-defaults
mkdir -p files/etc/board.d
curl -skLo files/etc/board.d/03_model $mirror/openwrt/files/etc/board.d/03_model
curl -skLo files/etc/uci-defaults/99-led $mirror/openwrt/files/etc/uci-defaults/99-led
curl -skLo files/etc/uci-defaults/99-nikki $mirror/openwrt/files/etc/uci-defaults/99-nikki
curl -skLo files/etc/uci-defaults/99-watchcat $mirror/openwrt/files/etc/uci-defaults/99-watchcat
curl -skLo files/etc/uci-defaults/99-dae $mirror/openwrt/files/etc/uci-defaults/99-dae

# advanced banner
mkdir -p files/etc/profile.d
curl -skLo files/etc/profile.d/advanced_banner.sh https://github.com/JohnsonRan/opwrt_build_script/raw/master/openwrt/files/etc/profile.d/advanced_banner.sh
if cat .config | grep -q "^CONFIG_TARGET_x86_64=y"; then
curl -skLo package/base-files/files/etc/banner https://github.com/JohnsonRan/opwrt_build_script/raw/master/openwrt/files/etc/banner-x86
else
curl -skLo package/base-files/files/etc/banner https://github.com/JohnsonRan/opwrt_build_script/raw/master/openwrt/files/etc/banner
fi
curl -skLo files/usr/bin/advanced_banner https://github.com/JohnsonRan/opwrt_build_script/raw/master/openwrt/files/usr/bin/advanced_banner
chmod +x files/usr/bin/advanced_banner

# from pmkol/openwrt-plus
# configure default-settings
#sed -i 's/openwrt\/luci/JohnsonRan\/opwrt_build_script/g' package/new/luci-theme-argon/luci-theme-argon/luasrc/view/themes/argon/footer.htm
#sed -i 's/openwrt\/luci/JohnsonRan\/opwrt_build_script/g' package/new/luci-theme-argon/luci-theme-argon/luasrc/view/themes/argon/footer_login.htm
sed -i 's/openwrt\/luci/JohnsonRan\/opwrt_build_script/g' feeds/luci/themes/luci-theme-bootstrap/ucode/template/themes/bootstrap/footer.ut
sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''OpenWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''OpenWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI openwrt-24.10\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"v'$(date +%Y%m%d)'\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''v'$(date +%Y%m%d)'\'\'', branch = '\''LuCI openwrt-24.10'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/new/default-settings/default/zzz-default-settings
