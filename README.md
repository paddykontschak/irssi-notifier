Simple script for irssi to trigger Mac OS X 10.8's Notification Center
===

Requirements
---
* Mac OS X 10.8 or higher
* [terminal-notifier](https://github.com/alloy/terminal-notifier)

Installation
---
Place notifier.pl in `~/.irssi/scripts/`.

    /script load notifier.pl

Configuration
---
    /SET notifier_on_regex [regex]
    /SET notifier_channel_regex [regex]
    /SET notifier_on_privmsg <0|1>

Usage
---
 notifier on mynickname

    /SET notifier_on_regex mynickname

 notifier on everything

    /SET notifier_on_regex .*

 everything but jdewey

    /SET notifier_on_regex (?=^(?:(?!jdewey).)*$).*

 only notifier things for mychannel1 and mychannel2

    /SET notifier_channel_regex (mychannel1|mychannel2)

 by default we don't send notifications for privmsgs you can enable this by setting this flag to 1

    /SET notifier_on_privmsg 1 

Didn't irssi-growl let me choose an icon?
---
Yes, it did and still does, that is if you choose to use growl. But Mountain Lion's Notification Center doesn't let you specify a custom icon for a notification. To quote terminal-notifier's repository:

> The Notification Center always uses the application’s own icon, there’s currently no way to specify a custom icon for a notification. The only way to use this tool with your own icon is to include a build of terminal-notifier with your icon instead.

I will keep track of terminal-notifier's commits and if someone does find a way to specify an icon I will update this script as soon as possible.

Author
---
Patrick Kontschak `<patrick.kontschak@gmail.com>` 2012

Forked from Nate Murray's [irssi-growl](https://github.com/jashmenn/irssi-growl).
