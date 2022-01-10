# @summary Apply kernel updates via cron
#
# @param enabled
#   state of whether kernel updates via cron are enabled
#
# @param random_delay
#   Maximum number of minutes to random delay before applying kernel updates
#
# @param update_day_of_week
#   Contains day of week abbreviation for kernel update cron
#   e.g. "Sun", "Mon", "Tue", etc.
#   If not defined day of week is calculated from hostname
#
# @param update_hour
#   Hour for kernel update cron
#   There is a random delay before the kernel update occurs
#
# @param update_minute
#   Minute for kernel update cron
#   There is a random delay before the kernel update occurs
#
# @param update_months
#   Names of months (as 3 letter abbreviations) for kernel update cron
#   Empty array implies to run every month
#
# @param update_week_of_month
#   Week of the month for kernel update cron, e.g. "1"-"5" or "any"
#   If not defined cron runs every week
#
# @example
#   include profile_update_os::kernel_upgrade
class profile_update_os::kernel_upgrade (
  Boolean       $enabled,
  Integer       $random_delay,
  String        $update_day_of_week,
  Integer       $update_hour,
  Integer       $update_minute,
  Array[String] $update_months,
  String        $update_week_of_month,
) {

  if $enabled {

    if empty($update_day_of_week) {
      $day_of_week = profile_update_os::calculate_day_of_week($facts['hostname'])
    } else {
      $day_of_week = $update_day_of_week
    }
    if empty($update_week_of_month) {
      $week_num = profile_update_os::calculate_week_of_month($facts['hostname'])
    } else {
      $week_num = $update_week_of_month
    }

    if empty($update_months) {
      $cron_update_months = '*'
      $motd_months = 'each month'
    } else {
      $cron_update_months = $update_months
      $months_3char_abr = $update_months.map |$m| { $m[0,3] }
      $motd_months = join( capitalize( $months_3char_abr ), '/' )
    }

    if ( $random_delay > 5 ) {
      $script_options="--waitmax ${random_delay}"
    } elsif ( $random_delay <= 5 ) {
      $script_options="--waitmin 0 --waitmax ${random_delay}"
    } else {
      $script_options=''
    }

    Cron {
      hour    => $update_hour,
      minute  => $update_minute,
      month   => $cron_update_months,
      user    => 'root',
      weekday => '*',
    }

    cron { 'kernel_upgrade':
      command => "( ${profile_update_os::root_cron_scripts_dir}/run-if-today.sh ${week_num} ${day_of_week} \
&& ${profile_update_os::root_cron_scripts_dir}/kernel_upgrade.sh ${script_options} )",
      require => [
        File['kernel_upgrade.sh'],
      ],
    }
    $notice_of_upgrade_text = "This server (${::fqdn}) will be updated and rebooted in"
    cron { '48_hour_notice_of_upgrade':
      command => "( ${profile_update_os::root_cron_scripts_dir}/run-if-today.sh ${week_num} ${day_of_week} 2 \
&& /usr/bin/wall -n '${notice_of_upgrade_text} 48 hours.' )",
    }
    cron { '24_hour_notice_of_upgrade':
      command => "( ${profile_update_os::root_cron_scripts_dir}/run-if-today.sh ${week_num} ${day_of_week} 1 \
&& /usr/bin/wall -n '${notice_of_upgrade_text} 24 hours.' )",
    }
    $update_one_hour_earlier = $update_hour - 1
    cron { '1_hour_notice_of_upgrade':
      command => "( ${profile_update_os::root_cron_scripts_dir}/run-if-today.sh ${week_num} ${day_of_week} \
&& /usr/bin/wall -n '${notice_of_upgrade_text} 1 hour.' )",
      hour    => $update_one_hour_earlier,
    }

    ## UPDATE MOTD
    ## CURRENTLY THIS ONLY DISPLAYS FOR RHEL >=8 SYSTEMS
    case $week_num {
      /1/:  {
        $weeks = 'the 1st'
        $month_prefix = ' of'
      }
      /2/:  {
        $weeks = 'the 2nd'
        $month_prefix = ' of'
      }
      /3/:  {
        $weeks = 'the 3rd'
        $month_prefix = ' of'
      }
      /4/:  {
        $weeks = 'the 4th'
        $month_prefix = ' of'
      }
      /5/:  {
        $weeks = 'the 5th'
        $month_prefix = ' of'
      }
      /any/: {
        $weeks = 'all'
        $month_prefix = 's of'
      }
      default: {
        $weeks = 'unknown'
        $month_prefix = ' of'
      }
    }
    case $day_of_week {
      /Sun/:  { $day = 'Sunday' }
      /Mon/:  { $day = 'Monday' }
      /Tue/:  { $day = 'Tuesday' }
      /Wed/:  { $day = 'Wednesday' }
      /Thu/:  { $day = 'Thursday' }
      /Fri/:  { $day = 'Friday' }
      /Sat/:  { $day = 'Saturday' }
      default:  { $day = 'unknown' }
    }
    if ( $update_hour < 10 ) {
      $hour = "0${update_hour}"
    } else {
      $hour = $update_hour
    }
    if ( $update_minute < 10 ) {
      $minute = "0${update_minute}"
    } else {
      $minute = $update_minute
    }

    $motdcontent = @("EOF")
      This system updates and reboots ${weeks} ${day}${month_prefix} ${motd_months} at ${hour}:${minute} ${::timezone}.
      | EOF
    ensure_resource( 'file', '/etc/motd.d', { 'ensure' => 'directory', 'mode' => '0755', })
    file { '/etc/motd.d/kernel_upgrade':
      ensure  => file,
      mode    => '0644',
      content => $motdcontent,
    }

    file { 'kernel_upgrade.sh':
      ensure => 'file',
      path   => "${profile_update_os::root_cron_scripts_dir}/kernel_upgrade.sh",
      source => "puppet:///modules/${module_name}/root/cron_scripts/kernel_upgrade.sh",
      owner  => 'root',
      group  => 'root',
      mode   => '0700',
    }

  }
  else
  {
    cron { 'kernel_upgrade':
      ensure => absent,
    }
    cron { '48_hour_notice_of_upgrade':
      ensure => absent,
    }
    cron { '24_hour_notice_of_upgrade':
      ensure => absent,
    }
    cron { '1_hour_notice_of_upgrade':
      ensure => absent,
    }
    file { '/etc/motd.d/kernel_upgrade':
      ensure => absent,
    }
    file { 'kernel_upgrade.sh':
      ensure => absent,
      path   => "${profile_update_os::root_cron_scripts_dir}/kernel_upgrade.sh",
    }

  }

}
