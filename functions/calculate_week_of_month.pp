# Select the default week of the month that a host applies os updates.
# Calculated to be the modulus 4 of the last character of the short hostname.
function profile_update_os::calculate_week_of_month(String $hostname) >> String {
  case $hostname {
    /[159]$/, /(?i-mx:[aeimquy]$)/: { '1' }
    /[26]$/, /(?i-mx:[bfjnrvz]$)/:  { '2' }
    /[37]$/, /(?i-mx:[cgkosw]$)/:   { '3' }
    /[048]$/, /(?i-mx:[dhlptx]$)/:  { '4' }
    # THINKING ON '2' IS TO KEEP THEM AWAY FROM MOST HOLIDAYS
    default: { '2' }
  }
}
