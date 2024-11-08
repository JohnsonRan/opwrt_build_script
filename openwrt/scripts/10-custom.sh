#!/bin/bash

# mihomo
if curl -s "$mirror/openwrt/24-config-common" | grep -q "^CONFIG_PACKAGE_luci-app-mihomo=y"; then
    git clone https://$github/morytyann/OpenWrt-mihomo package/new/openwrt-mihomo
    echo -e "untrusted comment: MihomoTProxy\nRWSrAXyIqregizvXvG9kJI/JoTkaCCPDy6CQrrVQ4IZ8Qgu+iWMql0UW" > /etc/opkg/keys/ab017c88aab7a08b
    echo "src/gz mihomo https://raw.e11z.net/$github/morytyann/OpenWrt-mihomo/raw/gh-pages/$branch/$arch/mihomo" >> /etc/opkg/customfeeds.conf
    mkdir -p files/etc/mihomo/run/ui
    curl -skLo files/etc/mihomo/run/Country.mmdb https://$github/NobyDa/geoip/raw/release/Private-GeoIP-CN.mmdb
    curl -skLo files/etc/mihomo/run/GeoIP.dat https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.dat
    curl -skLo files/etc/mihomo/run/GeoSite.dat https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat
    curl -skLo gh-pages.tar.gz https://$github/Zephyruso/zashboard/archive/refs/heads/gh-pages.zip
    tar zxf gh-pages.tar.gz
    mv gh-pages files/etc/mihomo/run/ui/zashboard
fi

# tailscale
if curl -s "$mirror/openwrt/24-config-common" | grep -q "^CONFIG_PACKAGE_luci-app-tailscale=y"; then
    git clone https://$github/asvow/luci-app-tailscale package/new/luci-app-tailscale
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
    git clone https://$github/hudra0/qosmate package/new/qosmate
    git clone https://$github/hudra0/luci-app-qosmate package/new/luci-app-qosmate
fi

# sysupgrade keep files
echo "/etc/hotplug.d/iface/*.sh" >>files/etc/sysupgrade.conf

# add UE-DDNS
mkdir -p files/usr/bin
curl -skLo files/usr/bin/ue-ddns ddns.03k.org
chmod +x files/usr/bin/ue-ddns

# https://github.com/prometheus/node_exporter
mkdir -p files/etc/init.d
ne_version=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/^v//')
if [ "$platform" = "x86_64" ]; then
    curl -skLo ne.tar.gz https://$github/prometheus/node_exporter/releases/download/v$ne_version/node_exporter-$ne_version.linux-amd64.tar.gz
    tar zxf ne.tar.gz
    mv node_exporter-$ne_version.linux-amd64/node_exporter files/usr/bin
else
    curl -skLo ne.tar.gz https://$github/prometheus/node_exporter/releases/download/v$ne_version/node_exporter-$ne_version.linux-arm64.tar.gz
    tar zxf ne.tar.gz
    mv node_exporter-$ne_version.linux-arm64/node_exporter files/usr/bin
fi
curl -skLo files/etc/init.d/node_exporter  $mirror/openwrt/files/node_exporter/node_exporter.init
chmod +x files/etc/init.d/node_exporter

# ghp.ci might not stable
sed -i 's/ghp.ci/raw.e11z.net/g' package/new/default-settings/default/zzz-default-settings

# defaults
mkdir -p files/etc/uci-defaults
mkdir -p files/etc/board.d
curl -skLo files/etc/board.d/03_model $mirror/openwrt/files/etc/board.d/03_model
curl -skLo files/etc/uci-defaults/99-led $mirror/openwrt/files/etc/uci-defaults/99-led
curl -skLo files/etc/uci-defaults/99-mihomo $mirror/openwrt/files/etc/uci-defaults/99-mihomo
curl -skLo files/etc/uci-defaults/99-watchcat $mirror/openwrt/files/etc/uci-defaults/99-watchcat

# from pmkol/openwrt-plus
# configure default-settings
sed -i 's/openwrt\/luci/JohnsonRan\/opwrt_build_script/g' package/new/luci-theme-argon/luci-theme-argon/luasrc/view/themes/argon/footer.htm
sed -i 's/openwrt\/luci/JohnsonRan\/opwrt_build_script/g' package/new/luci-theme-argon/luci-theme-argon/luasrc/view/themes/argon/footer_login.htm
sed -i 's/openwrt\/luci/JohnsonRan\/opwrt_build_script/g' feeds/luci/themes/luci-theme-bootstrap/ucode/template/themes/bootstrap/footer.ut
sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''OpenWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''OpenWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI openwrt-24.10\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"v'$(date +%Y%m%d)'\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''v'$(date +%Y%m%d)'\'\'', branch = '\''LuCI openwrt-24.10'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/new/default-settings/default/zzz-default-settings
