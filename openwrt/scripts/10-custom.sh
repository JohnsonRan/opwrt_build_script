#!/bin/bash

# nikki
if curl -s "$mirror/openwrt/24-config-common" | grep -q "^CONFIG_PACKAGE_luci-app-nikki=y"; then
    git clone https://github.com/morytyann/OpenWrt-nikki package/new/openwrt-nikki --depth=1
    mkdir -p files/etc/opkg/keys
    curl -skL https://nikkinikki.pages.dev/key-build.pub >files/etc/opkg/keys/ab017c88aab7a08b
    echo "src/gz nikki https://nikkinikki.pages.dev/openwrt-24.10/$arch/nikki" >>files/etc/opkg/customfeeds.conf
    mkdir -p files/etc/nikki/run/ui
    curl -skLo files/etc/nikki/run/Country.mmdb https://github.com/NobyDa/geoip/raw/release/Private-GeoIP-CN.mmdb
    curl -skLo files/etc/nikki/run/GeoIP.dat https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.dat
    curl -skLo files/etc/nikki/run/GeoSite.dat https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat
    curl -skLo gh-pages.zip https://github.com/Zephyruso/zashboard/archive/refs/heads/gh-pages.zip
    unzip -qq gh-pages.zip
    mv zashboard-gh-pages files/etc/nikki/run/ui/zashboard
    rm -rf gh-pages.zip
    # make sure nikki is always latest
    nikki_version=$(curl -skL https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt)
    sed -i "s/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:=Alpha/" package/new/openwrt-nikki/nikki/Makefile
    sed -i "s/PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/" package/new/openwrt-nikki/nikki/Makefile
    sed -i "/PKG_BUILD_FLAGS/i PKG_BUILD_VERSION:=$nikki_version" package/new/openwrt-nikki/nikki/Makefile
    sed -i 's|GO_PKG_LDFLAGS_X:=$(GO_PKG)/constant.Version=$(PKG_SOURCE_VERSION)|GO_PKG_LDFLAGS_X:=$(GO_PKG)/constant.Version=$(PKG_BUILD_VERSION)|g' package/new/openwrt-nikki/nikki/Makefile
    # don't reserve this CIDR6
    sed -i "/list reserved_ip6 '2001:db8::\/32'/d" package/new/openwrt-nikki/nikki/files/nikki.conf
    sed -i "/uci add_list nikki.proxy.reserved_ip6=2001:db8::\/32/d" package/new/openwrt-nikki/nikki/files/uci-defaults/migrate.sh
fi

if curl -s "$mirror/openwrt/24-config-common" | grep -q "^CONFIG_PACKAGE_luci-app-momo=y"; then
    git clone https://github.com/nikkinikki-org/OpenWrt-momo package/new/luci-app-momo --depth=1
    echo "src/gz momo https://momomomo.pages.dev/openwrt-24.10/$arch/momo" >>files/etc/opkg/customfeeds.conf
    mkdir -p files/etc/momo/run/ui
    curl -skLo files/etc/momo/run/ui/gh-pages.zip https://github.com/Zephyruso/zashboard/archive/refs/heads/gh-pages.zip
    unzip -qq gh-pages.zip
    mv zashboard-gh-pages files/etc/momo/run/ui/zashboard
    rm -rf gh-pages.zip
fi

# tailscale
git clone --depth=1 https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community
mv luci-app-tailscale-community/luci-app-tailscale-community package/new
rm -rf luci-app-tailscale-community
if curl -s "$mirror/openwrt/24-config-common" | grep -q "^CONFIG_PACKAGE_luci-app-tailscale-community=y"; then
    # make sure tailscale is always latest
    ts_version=$(curl -s https://api.github.com/repos/tailscale/tailscale/releases/latest | grep -oP '(?<="tag_name": ")[^"]*' | sed 's/^v//')
    ts_tarball="tailscale-${ts_version}.tar.gz"
    curl -skLo "${ts_tarball}" "https://codeload.github.com/tailscale/tailscale/tar.gz/v${ts_version}"
    ts_hash=$(sha256sum "${ts_tarball}" | awk '{print $1}')
    rm -rf "${ts_tarball}"
    sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=${ts_version}/" package/feeds/packages/tailscale/Makefile
    sed -i "s/PKG_HASH:=.*/PKG_HASH:=${ts_hash}/" package/feeds/packages/tailscale/Makefile
fi

# luci-app-3cat
git clone https://github.com/immortalwrt/luci immsource/immortalwrt_luci --depth=1
git clone https://github.com/immortalwrt/packages immsource/immortalwrt_packages --depth=1
mv immsource/immortalwrt_luci/applications/luci-app-3cat package/new
mv immsource/immortalwrt_packages/net/3proxy package/new
sed -i 's|../../luci.mk|$(TOPDIR)/feeds/luci/luci.mk|g' package/new/luci-app-3cat/Makefile
rm -rf immsource/

# enable iface gso
curl -skLo package/base-files/files/etc/rc.local $mirror/openwrt/files/etc/rc.local

# extra packages
git clone https://github.com/JohnsonRan/packages_utils_boltbrowser package/new/boltbrowser
git clone https://github.com/JohnsonRan/packages_net_speedtest-ex package/new/speedtest-ex
#git clone https://github.com/JohnsonRan/InfinityDuck package/new/InfinityDuck --depth=1
#rm -rf package/feeds/packages/v2ray-geodata
#git clone https://github.com/JohnsonRan/packages_net_v2ray-geodata package/new/v2ray-geodata --depth=1
#sed -i "s/GEOX_VER:=.*/GEOX_VER:=$(date +%Y%m%d%H%M)/" package/new/v2ray-geodata/Makefile

# custom feed
curl -skL https://opkg.ihtw.moe/key-build.pub >files/etc/opkg/keys/351925c1f1557850 >files/etc/opkg/keys/351925c1f1557850
echo "src/gz infsubs https://opkg.ihtw.moe/openwrt-24.10/$arch/InfinitySubstance" >>files/etc/opkg/customfeeds.conf

# latest golang version
rm -rf feeds/packages/lang/golang/golang
git clone https://github.com/JohnsonRan/packages_lang_golang feeds/packages/lang/golang/golang

# sysupgrade keep files
echo "/etc/hotplug.d/iface/*.sh" >>files/etc/sysupgrade.conf
echo "/etc/nikki/run/cache.db" >>files/etc/sysupgrade.conf
echo "/var/lib/vnstat/vnstat.db" >>files/etc/sysupgrade.conf
echo "/opt/komari" >>files/etc/sysupgrade.conf
echo "/etc/init.d/komari-agent" >>files/etc/sysupgrade.conf

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
curl -skLo files/etc/uci-defaults/99-nikki $mirror/openwrt/files/etc/uci-defaults/99-nikki
curl -skLo files/etc/uci-defaults/99-dae $mirror/openwrt/files/etc/uci-defaults/99-dae

# advanced banner
mkdir -p files/etc/profile.d
curl -skLo files/etc/profile.d/advanced_banner.sh https://github.com/JohnsonRan/opwrt_build_script/raw/master/openwrt/files/etc/profile.d/advanced_banner.sh
curl -skLo package/base-files/files/etc/banner https://github.com/JohnsonRan/opwrt_build_script/raw/master/openwrt/files/etc/banner
curl -skLo files/usr/bin/advanced_banner https://github.com/JohnsonRan/opwrt_build_script/raw/master/openwrt/files/usr/bin/advanced_banner
chmod +x files/usr/bin/advanced_banner

# erofs rootfs image generation
curl -skL https://github.com/openwrt/openwrt/pull/19244.patch | git apply --reject
curl -skL https://github.com/openwrt/openwrt/pull/19501.patch | git apply --reject
git clone https://github.com/openwrt/openwrt main_openwrt --depth=1
rm -rf package/system/fstools
mv main_openwrt/package/system/fstools package/system
rm -rf main_openwrt

# FANTASTIC PACKAGES
git clone --depth 1 --branch master --single-branch --no-tags --recurse-submodules https://github.com/fantastic-packages/packages package/fantastic_packages
mv package/fantastic_packages/luci package/new
mv package/fantastic_packages/packages package/new
rm -rf package/new/luci/luci-app-netspeedtest
rm -rf package/fantastic_packages

# from pmkol/openwrt-plus
# configure default-settings
#sed -i 's/openwrt\/luci/JohnsonRan\/opwrt_build_script/g' package/new/luci-theme-argon/luci-theme-argon/luasrc/view/themes/argon/footer.htm
#sed -i 's/openwrt\/luci/JohnsonRan\/opwrt_build_script/g' package/new/luci-theme-argon/luci-theme-argon/luasrc/view/themes/argon/footer_login.htm
sed -i 's/openwrt\/luci/JohnsonRan\/opwrt_build_script/g' feeds/luci/themes/luci-theme-bootstrap/ucode/template/themes/bootstrap/footer.ut
sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''OpenWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''OpenWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI openwrt-24.10\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"v'$(date +%Y%m%d)'\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''v'$(date +%Y%m%d)'\'\'', branch = '\''LuCI openwrt-24.10'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/new/default-settings/default/zzz-default-settings
