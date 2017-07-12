# Manage the installation of a Logstash plugin.
#
# By default, plugins are downloaded from RubyGems, but it is also possible
# to install from a local Gem, or one stored in Puppet.
#
# @example install a plugin
#   logstash_legacy::plugin { 'logstash-input-stdin': }
#
# @example remove a plugin
#   logstash_legacy::plugin { 'logstash-input-stout':
#     ensure => absent,
#   }
#
# @example install a plugin from a local file
#   logstash_legacy::plugin { 'logstash-input-custom':
#     source => 'file:///tmp/logstash-input-custom.gem',
#   }
#
# @example install a plugin from a Puppet module.
#   logstash_legacy::plugin { 'logstash-input-custom':
#     source => 'puppet:///modules/logstash-site-plugins/logstash-input-custom.gem',
#   }
#
# @param source [String] install from this file, not from RubyGems.
#
define logstash_legacy::plugin (
  $source = undef,
  $ensure = present,
)
{
  require logstash_legacy::package
  $exe = '/opt/logstash/bin/plugin'

  # Install plugin as logstash user and make
  # sure we find su on centos and debian
  Exec {
    path => '/bin:/usr/bin',
  }
  $exe_prefix = "su - '${::logstash_legacy::logstash_user}' -s /bin/bash -c '"
  $exe_suffix = "'"

  case $source { # Where should we get the plugin from?
    undef: {
      # No explict source, so search Rubygems for the plugin, by name.
      # ie. "/opt/logstash/bin/plugin install logstash-output-elasticsearch"
      $plugin = $name
    }

    /^\//: {
      # A gem file that is already available on the local filesystem.
      # Install from the local path.
      # ie. "/opt/logstash/bin/plugin install /tmp/logtash-filter-custom.gem"
      $plugin = $source
    }

    /^puppet:/: {
      # A 'puppet:///' URL. Download the gem from Puppet, then install
      # the plugin from the downloaded file.
      $downloaded_file = sprintf('/tmp/%s', basename($source))
      file { $downloaded_file:
        source => $source,
        before => Exec["install-${name}"],
      }
      $plugin = $downloaded_file
    }

    default: {
      fail('"source" should be a local path, a "puppet:///" url, or undef.')
    }
  }

  case $ensure {
    'present': {
      exec { "install-${name}":
        command => "${exe_prefix}${exe} install ${plugin}${exe_suffix}",
        unless  => "${exe_prefix}${exe} list ^${name}${exe_suffix}$",
        timeout => 1800,
      }
    }

    /^\d+\.\d+\.\d+/: {
      exec { "install-${name}":
        command => "${exe_prefix}${exe} install --version ${ensure} ${plugin}${exe_suffix}",
        unless  => "${exe_prefix}${exe} list --verbose ^${name}\$${exe_suffix} | grep --fixed-strings --quiet '(${ensure})'",
        timeout => 1800,
      }
    }

    'absent': {
      exec { "remove-${name}":
        command => "${exe_prefix}${exe} uninstall ${name}${exe_suffix}",
        onlyif  => "${exe_prefix}${exe} list${exe_suffix} | grep -q ^${name}$",
        timeout => 1800,
      }
    }

    default: {
      fail "'ensure' should be 'present' or 'absent'."
    }
  }
}
