# @summary Apply kernel updates via cron
#
# @param enabled
#   state of whether kernel updates via cron are enabled
#
# @param message
#   Message broadcast to users before update and reboot
#
# @param random_delay
#   Maximum number of minutes to random delay before applying kernel updates
#
# @param reboot_always
#   Always trigger reboot even if no updates require it
#
# @param reboot_num_pkgs_updated_since_reboot
#   Minimum number of packages updated since reboot to trigger reboot
#   Negative value means to ignore and use script default value
#
# @param reboot_num_pkgs_updated_today
#   Minimum number of packages updated today to trigger reboot
#   Negative value means to ignore and use script default value
#
# @param reboot_pkgs_list
#   List of updated packages that should always trigger reboot
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
  String        $message,
  Integer       $random_delay,
  Boolean       $reboot_always,
  Integer       $reboot_num_pkgs_updated_since_reboot,
  Integer       $reboot_num_pkgs_updated_today,
  Array[String] $reboot_pkgs_list,
  String        $update_day_of_week,
  Integer       $update_hour,
  Integer       $update_minute,
  Array[String] $update_months,
  String        $update_week_of_month,
) {
  if $enabled {
    if empty($update_day_of_week) {
      $day_of_week = profile_update_os::calculate_day_of_week($facts['networking']['hostname'])
    } else {
      $day_of_week = $update_day_of_week
    }
    if empty($update_week_of_month) {
      $week_num = profile_update_os::calculate_week_of_month($facts['networking']['hostname'])
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
      $delay_options="--waitmax ${random_delay}"
    } elsif ( $random_delay <= 5 ) {
      $delay_options="--waitmin 0 --waitmax ${random_delay}"
    } else {
      $delay_options=''
    }

    if ! empty($message) {
      $message_option="--message '${message}'"
    } else {
      $message_option=''
    }

    if ( $reboot_always ) {
      $reboot_option='--reboot'
    } else {
      $reboot_option=''
    }

    if ( $reboot_num_pkgs_updated_since_reboot > -1 ) {
      $updates_reboot_option="--updates_reboot ${reboot_num_pkgs_updated_since_reboot}"
    } else {
      $updates_reboot_option=''
    }

    if ( $reboot_num_pkgs_updated_today > -1 ) {
      $updates_today_option="--updates_today ${reboot_num_pkgs_updated_today}"
    } else {
      $updates_today_option=''
    }

    if ! empty($reboot_pkgs_list) {
      $reboot_pkgs_list_regex = join( $reboot_pkgs_list, '|' )
      $reboot_pkgs_option="--reboot_pkgs '${reboot_pkgs_list_regex}'"
    } else {
      $reboot_pkgs_option=''
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
&& ${profile_update_os::root_cron_scripts_dir}/kernel_upgrade.sh ${delay_options} ${message_option} \
${reboot_option} ${updates_reboot_option} ${updates_today_option} ${reboot_pkgs_option} )",
      require => [
        File['kernel_upgrade.sh'],
      ],
    }
    $notice_of_upgrade_text = "This server (${facts['networking']['fqdn']}) will be updated and rebooted in"
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
        $weeks = 'each'
        $month_prefix = ' of'
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
      This system updates and reboots ${weeks} ${day}${month_prefix} ${motd_months} at ${hour}:${minute} ${facts['timezone']}.
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
  else {
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
