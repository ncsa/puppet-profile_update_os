# @summary Apply kernel updates via cron
#
# @param enabled
#   Boolean of whether kernel updates via cron are enabled
#
# @param nowait
#   Boolean of whether to wait before applying kernel updates
#
# @param update_day_of_week
#   String containing day of week abbreviation for kernel update cron
#   e.g. "Sun", "Mon", "Tue", etc.
#   If not defined day of week is calculated from hostname
#
# @param update_hour
#   Hour for kernel update cron
#   There is a random delay of up to 30 minutes before the kernel update occurs
#   The random delay can be disabled by setting $nowait = true
#
# @param update_minute
#   Minute for kernel update cron
#   There is a random delay of up to 30 minutes before the kernel update occurs
#   The random delay can be disabled by setting $nowait = true
#
# @param update_month
#   Array of strings containing months for kernel update cron
#
# @param update_week_of_month
#   Strings containing week of the month for kernel update cron, e.g. "1"-"5" or "any"
#   If not defined cron runs every week
#
# @example
#   include profile_update_os::kernel_upgrade
class profile_update_os::kernel_upgrade (
  Boolean       $enabled,
  Boolean       $nowait,
  String        $update_day_of_week,
                $update_hour,
                $update_minute,
  Array[String] $update_month,
  String        $update_week_of_month,
) {

  if $enabled {

    if ( ! empty($update_day_of_week) ) {
      $day_of_week = $update_day_of_week
    }
    else
    {
      $day_of_week = profile_update_os::calculate_day_of_week($facts['hostname'])
    }
    if ( ! empty($update_week_of_month) ) {
      $week_num = $update_week_of_month
    }
    else
    {
      $week_num = profile_update_os::calculate_week_of_month($facts['hostname'])
    }

    if $nowait {
      $script_options='-n'
    }
    else
    {
      $script_options=''
    }

    cron { 'kernel_upgrade':
      command => "( /root/scripts/run-if-today.sh ${week_num} ${day_of_week} && /root/scripts/kernel_upgrade.sh ${script_options} )",
      hour    => $update_hour,
      minute  => $update_minute,
      month   => $update_month,
      require => [
        File['/root/scripts/kernel_upgrade.sh'],
      ],
    }
  }
  else
  {
    cron { 'kernel_upgrade':
      ensure => absent,
    }

  }

  file { '/root/scripts/kernel_upgrade.sh':
    ensure => 'file',
    source => "puppet:///modules/${module_name}/root/scripts/kernel_upgrade.sh",
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
    #require => File['/root/scripts'],
  }
  ## /root/scripts ALREADY DEFINED IN ELSEWHERE?
  #file { '/root/scripts':
  #  ensure => 'directory',
  #  owner  => 'root',
  #  group  => 'root',
  #  mode   => '0700',
  #}

#  cron { 'run_puppet_after_reboot':
#    command => '( /usr/bin/sleep 10s; /opt/puppetlabs/bin/puppet agent -t )',
#    user    => 'root',
#    special => 'reboot',
#    require => Package['puppet'],
#  }

}
