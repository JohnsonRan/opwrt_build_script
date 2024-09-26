# mihomo
if curl -s "https://$mirror/openwrt/23-config-common" | grep -q "^CONFIG_PACKAGE_luci-app-mihomo=y"; then
git clone https://$github/morytyann/OpenWrt-mihomo  package/new/openwrt-mihomo
mkdir -p files/etc/mihomo/run/ui
curl -Lso files/etc/mihomo/run/Country.mmdb https://$github/NobyDa/geoip/raw/release/Private-GeoIP-CN.mmdb
curl -Lso files/etc/mihomo/run/GeoIP.dat https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.dat
curl -Lso files/etc/mihomo/run/GeoSite.dat https://$github/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat
curl -Lso metacubexd-gh-pages.tar.gz https://$github/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.tar.gz
tar zxf metacubexd-gh-pages.tar.gz
mv metacubexd-gh-pages files/etc/mihomo/run/ui/metacubexd
fi

# sysupgrade keep files
echo "/etc/hotplug.d/iface/*.sh" >> files/etc/sysupgrade.conf
echo "/opt" >> files/etc/sysupgrade.conf
echo "/etc/init.d/nezha-service" >> files/etc/sysupgrade.conf

# add MihomoTProxy feed
# echo "src/gz mihomo https://morytyann.github.io/OpenWrt-mihomo/x86_64/mihomo" >> "/etc/opkg/customfeeds.conf"
# sed -i '/# opkg mirror/a echo -e '\''untrusted comment: MihomoTProxy\\nRWSrAXyIqregizvXvG9kJI/JoTkaCCPDy6CQrrVQ4IZ8Qgu+iWMql0UW'\'' > /etc/opkg/keys/ab017c88aab7a08b' package/new/default-settings/default/zzz-default-settings

# add UE-DDNS
curl -skLo ue-ddns.sh ddns.03k.org
chmod +x ue-ddns.sh
mkdir -p files/usr/bin
mv ue-ddns.sh files/usr/bin/ue-ddns

# change golang to amd64-v2 microarchitecture
sed -i 's/GO_AMD64:=v1/GO_AMD64:=v2/g' feeds/packages/lang/golang/golang-values.mk

# remove mkbuild patch
# rm -rf target/linux/generic/hack-6.6/991-mkbuild.patch
# rm -rf target/linux/generic/hack-6.11/991-mkbuild.patch

# from pmkol/openwrt-plus
# configure natflow
sed -i 's|\[\ \$(grep\ -c\ shortcut_fe\ /etc/config/firewall)\ -eq\ '\''0'\''\ \]\ \&\&\ uci\ set\ firewall.@defaults\[0\].flow_offloading='\''1'\''|\[\ \$(grep\ -c\ shortcut_fe\ /etc/config/firewall)\ -eq\ '\''0'\''\ \]\ \&\&\ \[\ \$(grep\ -c\ natflow_delay_pkts\ /etc/config/firewall)\ -eq\ '\''0'\''\ \]\ \&\&\ uci\ set\ firewall.@defaults\[0\].flow_offloading='\''1'\''|g' package/new/default-settings/default/zzz-default-settings
# configure default-settings
sed -i 's/openwrt\/luci/JohnsonRan\/opwrt_build_script/g' feeds/luci/themes/luci-theme-bootstrap/ucode/template/themes/bootstrap/footer.ut
sed -i 's/mirrors.pku.edu.cn/mirrors.cernet.edu.cn/g' package/new/default-settings/default/zzz-default-settings
sed -i '/# opkg mirror/a case $(uname -m) in\n    x86_64)\n        echo -e '\''src/gz immortalwrt_luci https://mirrors.cernet.edu.cn/openwrt/releases/packages-23.05/x86_64/luci\nsrc/gz immortalwrt_packages https://mirrors.cernet.edu.cn/openwrt/releases/packages-23.05/x86_64/packages'\'' >> /etc/opkg/distfeeds.conf\n        ;;\nesac' package/new/default-settings/default/zzz-default-settings
sed -i '/# opkg mirror/a echo -e '\''untrusted comment: Public usign key for 23.05 release builds\\nRWRoKXAGS4epF5gGGh7tVQxiJIuZWQ0geStqgCkwRyviQCWXpufBggaP'\'' > /etc/opkg/keys/682970064b87a917' package/new/default-settings/default/zzz-default-settings
# comment out the following line to restore the full description
sed -i '/# timezone/i grep -q '\''/tmp/sysinfo/model'\'' /etc/rc.local || sudo sed -i '\''/exit 0/i [ "$(cat /sys\\/class\\/dmi\\/id\\/sys_vendor 2>\\/dev\\/null)" = "Default string" ] \&\& echo "x86_64" > \\/tmp\\/sysinfo\\/model'\'' /etc/rc.local\n' package/new/default-settings/default/zzz-default-settings
sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''OpenWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''OpenWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI openwrt-23.05\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"v'$(date +%Y%m%d)'\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''v'$(date +%Y%m%d)'\'\'', branch = '\''LuCI openwrt-23.05'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/new/default-settings/default/zzz-default-settings