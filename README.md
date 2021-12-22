# NetWatchdog
NetWatchdog is a simple tool to keep Unix-based systems to stay connected to the network.

## Setup instructions

#### 1) Place the NetWatchdog folder into home directory

#### 2) Make shell script NetWatchdog.sh executable
Open a terminal, go to `~/NetWatchdog` directory and type
  
  `sudo chmod +x NetWatchdog.sh`

#### 3) Add the task into crontab
Type `crontab -e` into terminal.

Add these blocks into the opened file:

  `*\1 * * * * ~/NetWatchdog/NetWatchdog.sh`
  `0 0 * * 1 sudo rm netLogs_verbose.txt`

It will make the shell script work in every 1 minute.
Additionally, the script deletes the verbose logs every Monday, at 00:00.

Time interval can be changed through the "*" regions.

Useful sources for understanding cronjobs & crontab:

[Cronmaker](http://www.cronmaker.com)

[Crontab Guru](https://crontab.guru)

Now it's all done!
