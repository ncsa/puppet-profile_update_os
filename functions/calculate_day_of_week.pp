# Select the default day of the week that a host applies os updates.
# Wed is default to avoid holidays, long weekends, etc.
# dev/test nodes update the day before the default for testing.
function profile_update_os::calculate_day_of_week(String $hostname) >> String {
  case $hostname {
    /dev$/, /\-dev/, /test$/, /\-test/: { 'Tue' }
    default: { 'Wed' }
  }
}
