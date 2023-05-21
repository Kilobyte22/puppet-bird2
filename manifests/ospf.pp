# Configures an OSPF protocol
define bird::ospf (
  Enum['ipv4', 'ipv6'] $protocol,
  Optional[Enum['v2', 'v3']] $ospf_version = undef,
  String $export_filter = 'all',
  String $import_filter = 'all',
  Optional[String] $table = undef,
) {

  $act_table = $table ? {
    undef   => $protocol ? {
      'ipv4' => 'master4',
      'ipv6' => 'master6',
    },
    default => $table,
  }

  concat { "/etc/bird/conf.d/40_ospf_${title}.conf":
    ensure_newline => true,
    notify         => Service['bird'],
  }

  concat::fragment { "bird_ospf_${title}_header":
    target => "/etc/bird/conf.d/40_ospf_${title}.conf",
    source => 'puppet:///modules/bird/header.conf',
    order  => '00',
  }

  $use_ospf_version = $ospf_version ? {
    undef => $protocol ? {
      'ipv4' => 'v2',
      'ipv6' => 'v3',
    },
    default => $ospf_version,
  }

  concat::fragment { "bird_ospf_${title}_head":
    target  => "/etc/bird/conf.d/40_ospf_${title}.conf",
    order   => '01',
    content => epp(
      'bird/ospf.head.conf.epp',
      {
        id           => $title,
        ip_version   => $protocol,
        import       => $import_filter,
        export       => $export_filter,
        ospf_version => $use_ospf_version,
        table        => $act_table,
      }
    ),
  }

  concat::fragment { "bird_ospf_${title}_tail":
    target  => "/etc/bird/conf.d/40_ospf_${title}.conf",
    order   => '99',
    content => '}',
  }
}
