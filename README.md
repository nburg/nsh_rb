# nsh
Network shell. Command line program to run commands on groups of servers in parallel using ssh.

## Install
Install ruby via the normal means. Requires 1.9.3 or higher.
```bash
git clone git://github.com/nburg/nsh_rb.git
cd nsh_rb
bundle install
mkdir -p ~/.nsh/groups
```

## Usage
```bash
echo -e 'server1\nserver2' >> ~/.nsh/groups/fakegroup
bin/nsh -c uptime -g fakegroup
bin/nsh.rb -h
```

## TODO
+ allow for username per host
+ add configuration file
+ build some tests
+ need to set required flags for cli
+ autocreate default config directories in home
+ add option to do all groups
