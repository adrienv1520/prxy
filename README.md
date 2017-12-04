# prxy

A bash proxy manager. No more clear passwords in .bashrc or bash_profile files. Manage proxy host, port, username and aliases that need proxy settings to be run like apt-get, wget, curl.

### Init host, port and username to use for proxy:
`$ prxy init`

### Set/update host to use:
`$ prxy set-host hostname`

### Set/update port to use:
`$ prxy set-port port_number`

### Set/update username to use:
`$ prxy set-username username`

### Export proxy environment variables to the current shell:
`$ prxy set`

### Unset proxy environment variables to the current shell:
`$ prxy unset`

### Show credentials used for proxy:
`$ prxy credentials | -c`

### Show proxy environment variables:
`$ prxy show`

### Show aliases configuration:
`$ prxy aliases`

### Activate a proxy alias (eg. apt-get). By default all aliases are activated:
`$ prxy on aliasname | all`

### Deactivate a proxy alias (eg. apt-get). Let you manually set and unset proxy environment variables when running a specific command that needs proxy credentials and vars:
`$ prxy off aliasname | all`

### Help:
`$ prxy help | ''`
