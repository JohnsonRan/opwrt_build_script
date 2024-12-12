#!/bin/bash

# nikki
if curl -s "$mirror/openwrt/25-config-common" | grep -q "^CONFIG_PACKAGE_luci-app-nikki=y"; then
    git clone https://github.com/morytyann/OpenWrt-nikki package/new/openwrt-nikki --depth=1
    mkdir -p files/etc/apk/keys
    mkdir -p files/etc/apk/repositories.d/
    curl -skL https://nikkinikki.pages.dev/public-key.pem >files/etc/apk/keys/nikki.pem
    echo "https://nikkinikki.pages.dev/SNAPSHOT/x86_64/nikki/packages.adb" >>files/etc/apk/repositories.d/customfeeds.list
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
fi

if curl -s "$mirror/openwrt/25-config-common" | grep -q "^CONFIG_PACKAGE_luci-app-momo=y"; then
    git clone https://github.com/nikkinikki-org/OpenWrt-momo package/new/openwrt-momo --depth=1
    curl -skL https://momomomo.pages.dev/public-key.pem >files/etc/apk/keys/momo.pem
    echo "https://momomomo.pages.dev/SNAPSHOT/x86_64/momo/packages.adb" >>files/etc/apk/repositories.d/customfeeds.list
    mkdir -p files/etc/momo/run/ui
    curl -skLo gh-pages.zip https://github.com/Zephyruso/zashboard/archive/refs/heads/gh-pages.zip
    unzip -qq gh-pages.zip
    mv zashboard-gh-pages files/etc/momo/run/ui/zashboard
    rm -rf gh-pages.zip
    curl -skL $mirror/openwrt/patch/sing-box/reF1nd.patch | git -C package/new/openwrt-momo/momo apply
fi

# tailscale
git clone --depth=1 https://github.com/Tokisaki-Galaxy/luci-app-tailscale-community
mv luci-app-tailscale-community/luci-app-tailscale-community package/new
rm -rf luci-app-tailscale-community
if curl -s "$mirror/openwrt/25-config-common" | grep -q "^CONFIG_PACKAGE_luci-app-tailscale-community=y"; then
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

# enable services
curl -skLo package/base-files/files/etc/rc.local $mirror/openwrt/files/etc/rc.local

# extra packages
git clone https://github.com/JohnsonRan/packages_utils_boltbrowser package/new/boltbrowser
git clone https://github.com/JohnsonRan/packages_net_speedtest-ex package/new/speedtest-ex
#git clone https://github.com/JohnsonRan/InfinityDuck package/new/InfinityDuck --depth=1
#rm -rf package/feeds/packages/v2ray-geodata
#git clone https://github.com/JohnsonRan/packages_net_v2ray-geodata package/new/v2ray-geodata --depth=1
#sed -i "s/GEOX_VER:=.*/GEOX_VER:=$(date +%Y%m%d%H%M)/" package/new/v2ray-geodata/Makefile

# latest golang version
rm -rf feeds/packages/lang/golang/golang
git clone https://github.com/JohnsonRan/packages_lang_golang feeds/packages/lang/golang/golang

# sysupgrade keep files
echo "/etc/hotplug.d/iface/*.sh" >>files/etc/sysupgrade.conf
echo "/etc/nikki/run/cache.db" >>files/etc/sysupgrade.conf
echo "/etc/momo/run/cache.db" >>files/etc/sysupgrade.conf
echo "/opt/komari" >>files/etc/sysupgrade.conf
echo "/etc/init.d/komari-agent" >>files/etc/sysupgrade.conf
echo "/etc/smartdns" >>files/etc/sysupgrade.conf

# add UE-DDNS
mkdir -p files/usr/bin
curl -skLo files/usr/bin/ue-ddns ddns.03k.org
chmod +x files/usr/bin/ue-ddns

# ghp.ci is NOT stable
sed -i 's|raw.githubusercontent.com|raw.ihtw.moe/raw.githubusercontent.com|g' package/new/default-settings/default/zzz-default-settings

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
curl -skLo files/etc/profile.d/advanced_banner.sh $mirror/openwrt/files/etc/profile.d/advanced_banner.sh
curl -skLo package/base-files/files/etc/banner $mirror/openwrt/files/etc/banner
curl -skLo files/usr/bin/advanced_banner $mirror/openwrt/files/usr/bin/advanced_banner
chmod +x files/usr/bin/advanced_banner

# FANTASTIC PACKAGES
git clone --depth 1 --branch master --single-branch --no-tags --recurse-submodules https://github.com/fantastic-packages/packages package/fantastic_packages
mv package/fantastic_packages/luci package/new
mv package/fantastic_packages/packages package/new
rm -rf package/new/packages/openwrt-fchomo
rm -rf package/new/luci/luci-app-netspeedtest
rm -rf package/fantastic_packages

# smartdns
rm -rf package/feeds/luci/luci-app-smartdns
rm -rf package/feeds/packages/smartdns
git clone --depth=1 -b master https://github.com/JohnsonRan/openwrt-smartdns package/feeds/packages/smartdns
# aurora theme
git clone --depth=1 -b master https://github.com/eamonxg/luci-theme-aurora package/new/luci-theme-aurora
git clone --depth=1 -b master https://github.com/eamonxg/luci-app-aurora-config package/new/luci-app-aurora-config

# from pmkol/openwrt-plus
# configure default-settings
#sed -i 's/openwrt\/luci/JohnsonRan\/opwrt_build_script/g' package/new/luci-theme-argon/luci-theme-argon/luasrc/view/themes/argon/footer.htm
#sed -i 's/openwrt\/luci/JohnsonRan\/opwrt_build_script/g' package/new/luci-theme-argon/luci-theme-argon/luasrc/view/themes/argon/footer_login.htm
sed -i 's/openwrt\/luci/JohnsonRan\/opwrt_build_script/g' feeds/luci/themes/luci-theme-bootstrap/ucode/template/themes/bootstrap/footer.ut
sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''OpenWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''OpenWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI openwrt-25.12\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"v'$(date +%Y%m%d)'\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''v'$(date +%Y%m%d)'\'\'', branch = '\''LuCI openwrt-25.12'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/new/default-settings/default/zzz-default-settings
