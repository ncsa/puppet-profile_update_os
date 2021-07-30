# @summary Common functionality needed across the profile_update_os module
#
# @example
#   include profile_update_os::common
class profile_update_os::common {

  file { '/root/scripts/run-if-today.sh':
    ensure => 'file',
    source => "puppet:///modules/${module_name}/root/scripts/run-if-today.sh",
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
    #require => File['/root/scripts'],
  }

}
