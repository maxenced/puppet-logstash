# == Class: logstash_legacy::config
#
# This class exists to coordinate all configuration related actions,
# functionality and logical units in a central place.
#
#
# === Parameters
#
# This class does not provide any parameters.
#
#
# === Examples
#
# This class may be imported by other classes to use its functionality:
#   class { 'logstash_legacy::config': }
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard.pijnenburg@elasticsearch.com>
#
class logstash_legacy::config {
  File {
    owner => $logstash_legacy::logstash_user,
    group => $logstash_legacy::logstash_group,
  }

  $notify_service = $logstash_legacy::restart_on_change ? {
    true  => Class['logstash_legacy::service'],
    false => undef,
  }

  if ( $logstash_legacy::ensure == 'present' ) {
    file { $logstash_legacy::configdir:
      ensure  => directory,
      purge   => $logstash_legacy::purge_configdir,
      recurse => $logstash_legacy::purge_configdir,
    }

    file { "${logstash_legacy::configdir}/conf.d":
      ensure  => directory,
      require => File[$logstash_legacy::configdir],
    }

    file_concat { 'ls-config':
      ensure  => 'present',
      tag     => "LS_CONFIG_${::fqdn}",
      path    => "${logstash_legacy::configdir}/conf.d/logstash.conf",
      owner   => $logstash_legacy::logstash_user,
      group   => $logstash_legacy::logstash_group,
      mode    => '0644',
      notify  => $notify_service,
      require => File[ "${logstash_legacy::configdir}/conf.d" ],
    }

    $directories = [
      $logstash_legacy::patterndir,
      $logstash_legacy::plugindir,
      "${logstash_legacy::plugindir}/logstash",
      "${logstash_legacy::plugindir}/logstash/inputs",
      "${logstash_legacy::plugindir}/logstash/outputs",
      "${logstash_legacy::plugindir}/logstash/filters",
      "${logstash_legacy::plugindir}/logstash/codecs",
    ]

    file { $directories:,
      ensure  => directory,
    }
  }
  elsif ( $logstash_legacy::ensure == 'absent' ) {
    file { $logstash_legacy::configdir:
      ensure  => 'absent',
      recurse => true,
      force   => true,
    }
  }
}
