    services.dae.config = ''
      global {
        # 判断各网卡(包括物理网卡和虚拟网卡) 要不要加到 LAN interface 的标准是: 要不要走代理
        lan_interface: "${builtins.concatStringsSep "," config.inner.interfacesNeedsProxy}"
        wan_interface: "${builtins.concatStringsSep "," config.wanInterfaces}" # 使用 "auto" 自动侦测 WAN 接口。

        check_interval: 60s
        check_tolerance: 50ms  # Group will switch node only when new_latency <= old_latency - tolerance.

        log_level: info
        allow_insecure: true
        auto_config_kernel_parameter: true

        tls_implementation: utls  # imitate browser's Client Hello.
        utls_imitate: chrome_auto
      }

      subscription {
        #官网 https://www.tianhang.lol/auth/register?code=DYSYsO
        tianhang_v2ray: '${subscribe_url.tianhang_v2ray}'

        #官网 https://www2.gardenparty.me
        # stc_v2ray: '${subscribe_url.stc_v2ray}'
      }

      node {
        # Ref: https://github.com/daeuniverse/dae/blob/main/docs/en/proxy-protocols.md
        ${extra_node_config}
      }

      group {
        proxy {
          filter: subtag(tianhang_v2ray) && name(regex:'JP 2.*x1.0') [add_latency: +0.1s]
          filter: subtag(tianhang_v2ray) && name(regex:'JP 1.*x1.0') [add_latency: +0.2s]
          filter: subtag(tianhang_v2ray) && name(regex:'JP .*x1.5') [add_latency: +0.5s]

          #filter: subtag(tianhang_v2ray) && name(regex:'HK 3.*x1.0')
          filter: subtag(tianhang_v2ray) && name(regex:'HK 2.*x1.0')
          filter: subtag(tianhang_v2ray) && name(regex:'HK 1.*x1.0') [add_latency: +0.1s]
          filter: subtag(tianhang_v2ray) && name(regex:'HK .*x1.5') [add_latency: +0.3s]

          filter: subtag(stc_v2ray) [add_latency: +1s]
          policy: min_moving_avg
        }
        proxy_usa {
          filter: subtag(tianhang_v2ray) && name(regex:'US 11.*x1.0')
          filter: subtag(tianhang_v2ray) && name(regex:'.*US1 x1.0')

          #filter: subtag(tianhang_v2ray) && name(regex:'US.*OpenAI')
          #filter: subtag(tianhang_v2ray) && name(keyword:'US') [add_latency: +0.2s]
          #filter: subtag(tianhang_v2ray) && name(regex:'UK.*HOME') [add_latency: +1s]

          filter: subtag(stc_v2ray) && name(keyword:'US') [add_latency: +1s]
          policy: min_moving_avg
        }
      }

      dns {
        ipversion_prefer: 4 #${if config.networking.enableIPv6 then "6" else "4"}

        upstream {
          #googledns: 'tcp+udp://dns.google.com:53'
          #alidns: 'udp://dns.alidns.com:53'
          router: 'udp://10.40.0.1:53'
          smartdns: 'udp://127.0.0.163:53'
        }

        routing {
          request {
            qname(geosite:category-ads) -> reject
            qname(geosite:cn) -> router
            qname(geosite:category-games@cn) -> router
            qname(geosite:china-list) -> router  #Need asserts: https://github.com/Loyalsoldier/v2ray-rules-dat
            qname(geosite:apple-cn) -> router
            qname(geosite:google-cn) -> router
            fallback: smartdns
          }
          response {
            upstream(smartdns) -> accept
            upstream(router) && ip(geoip:private) -> smartdns
            fallback: accept
          }
        }
      }

      routing {
        # Ref: https://github.com/v2fly/domain-list-community
        # Ref More: https://github.com/Loyalsoldier/v2ray-rules-dat
        #  which depends on this to set geodata: https://github.com/daeuniverse/dae/pull/84
        # Doc: https://github.com/daeuniverse/dae/blob/main/docs/en/configuration/external-dns.md#external-dns-on-localhost

        pname(NetworkManager, transmission-da, transmission-dae, transmission-daemon) -> must_direct
        pname(dig) -> must_direct
        pname(systemd-resolved, dnsmasq, smartdns, AdGuardHome) && l4proto(udp) && dport(53) -> must_direct
        domain(suffix: local) -> must_direct   # for mDNS LAN hosts

        #domain(geosite:category-ads) -> block

        # 避免撞上机场审计策略
        domain(keyword: dafahao, keyword: minghui, keyword: dongtaiwang, keyword: epochtimes, keyword: ntdtv, keyword: falundafa, keyword: wujieliulan, keyword: architectureenperspective) -> block
        domain(keyword: tracker, keyword: xunlei, keyword: thunder, keyword: xlliveud, keyword: torrent, keyword: info_hash, keyword: get_peers, keyword: find_node, keyword: bittorrent, keyword: announce_peer, keyword: announce, keyword: joker) -> must_direct

        # for ChatGPT / Claude / New Bing ...
        domain(geosite:category-ai-chat-!cn) -> proxy_usa

        # for Quizlet Q-Chat
        domain(suffix: quizlet.com) -> proxy_usa

        # blacklist (for some LAN devices)
        sip(${lan-devices-use-blacklist}) && domain(geosite:category-porn) -> block
        sip(${lan-devices-use-blacklist}) && domain(geosite:geolocation-!cn) -> proxy
        sip(${lan-devices-use-blacklist}) -> must_direct

        # whitelist
        domain(geosite:cn) -> must_direct
        domain(geosite:category-games@cn) -> must_direct
        domain(geosite:china-list) -> must_direct  #Need asserts: https://github.com/Loyalsoldier/v2ray-rules-dat
        domain(geosite:apple-cn) -> must_direct
        domain(geosite:google-cn) -> must_direct

        dip(geoip:private) -> direct
        dip(224.0.0.0/3, 'ff00::/8') -> direct   # for Multicast
        dip(geoip:cn) -> direct

        fallback: proxy
      }
    '';