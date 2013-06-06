# == WHAT
# Simple script for irssi to trigger Mac OS X 10.8's Notification Center
#
# == WHO
# Patrick Kontschak 2012
# 
# Forked from Nate Murray's irssi-growl: https://github.com/jashmenn/irssi-growl
# 
# == CONFIG
#   /SET notifier_on_regex [regex]
#   /SET notifier_channel_regex [regex]
#
# == EXAMPLES
#
#   notifier on mynickname
#   /SET notifier_on_regex mynickname
#
#   notifier on everything:
#   /SET notifier_on_regex .*
#
#   everything but jdewey
#   /SET notifier_on_regex (?=^(?:(?!jdewey).)*$).*
#
#   only notifier things for mychannel1 and mychannel2
#   /SET notifier_channel_regex (mychannel1|mychannel2)
# 
# == INSTALL
# Place notifier.pl in `~/.irssi/scripts/`.
# /script load notifier.pl
#

use strict;
use Irssi;
use vars qw($VERSION %IRSSI);
# use Config;

# Dev. info ^_^
$VERSION = "0.0";
%IRSSI = (
  authors     => "Patrick Kontschak",
  contact     => "patrick.kontschak\@gmail.com",
  name        => "Notifier",
  description => "Simple script that will trigger Mac OS X 10.8's Notification Center",
  license     => "GPL",
  url         => "http://www.codinggoat.com",
  changed     => "Wed  8 Aug 2012 14:40:15 EDT"
);

# All the works
sub do_notifier {
  my ($server, $title, $data, $sound) = @_;
  $data =~ s/["';]//g;
  my $note_path = Irssi::settings_get_str('notifier_path');
  # This is safer so someones name of "bob;rm -rf $HOME;" doesn't screw you over
  my @cmd = ($note_path, '-message', $data, '-title', $title);
  if (Irssi::settings_get_str('notifier_play_sound') == 1) {
    # You need to have terminal-notifier from here:
    # https://github.com/alloy/terminal-notifier/tree/878042f5b9a4a64b92d504ddc0ff2edfebd35737
    # with sound support
    push(@cmd, '-sound');
    push(@cmd, $sound);
  }
  # All in the name of security
  # Grab whatever stdout and stderr are right now, and store them
  open OLDOUT,">&STDOUT";
  open OLDERR,">&STDERR";
  # Set stdout/stderr to dev null
  open(STDOUT,">> /dev/null");
  open(STDERR,">&STDOUT");
  # Actually run our arg list here
  system(@cmd);
  # Close the /dev/null stdout/stderr here
  close(STDOUT);
  close(STDERR);
  # Reopen the originals
  open(STDERR, ">&OLDERR");
  open(STDOUT, ">&OLDOUT");
}

sub notifier_it {
  my ($server, $title, $data, $channel, $nick) = @_;

  my $filter = Irssi::settings_get_str('notifier_on_regex');
  my $channel_filter = Irssi::settings_get_str('notifier_channel_regex');
  my $notifier_on_nick = Irssi::settings_get_str('notifier_on_nick');
  my $sound = Irssi::settings_get_str('notifier_sound');

  my $do_it = 0;

  # We have a channel filter and doesn't match here
  if($channel_filter && $server->ischannel($channel)) {
    return 0 if $channel !~ /$channel_filter/;
  }

  # Notify if someone says our current nick and we have
  # notifier_on_nick on
  if($notifier_on_nick) {
    my $current_nick = $server->{nick};
    $do_it = 1 if $data =~ /^$current_nick:?\s/;
  }

  # Notify if someone says something else in our filter
  if($filter && !$do_it) {
    $do_it = 1 if $data =~ /$filter/;
  }

  $title = $title . " " . $channel;
  do_notifier($server, $title, $data, $sound) if $do_it == 1;

  # Catch-all
  return 0;
}

# All the works
sub notifier_message {
  my ($server, $data, $nick, $mask, $target) = @_;
  notifier_it($server, $nick, $data, $target, $nick);
  Irssi::signal_continue($server, $data, $nick, $mask, $target);
}

sub notifier_my_message {
  my ($server, $data, $nick, $mask, $target) = @_;
  if (Irssi::settings_get_str('notifier_on_self') == 1) {
    notifier_it($server, $nick, $data, $target, $nick); 
  }
  Irssi::signal_continue($server, $data, $nick, $mask, $target);
}

sub notifier_join {
  my ($server, $channel, $nick, $address) = @_;
  notifier_it($server, "Join", "$nick has joined", $channel, $nick);
  Irssi::signal_continue($server, $channel, $nick, $address);
}

sub notifier_part {
  my ($server, $channel, $nick, $address) = @_;
  notifier_it($server, "Part", "$nick has parted", $channel, $nick);
  Irssi::signal_continue($server, $channel, $nick, $address);
}

sub notifier_quit {
  my ($server, $nick, $address, $reason) = @_;
  notifier_it($server, "Quit", "$nick has quit: $reason", $server, $nick);
  Irssi::signal_continue($server, $nick, $address, $reason);
}

sub notifier_invite {
  my ($server, $channel, $nick, $address) = @_;
  notifier_it($server, "Invite", "$nick has invited you on $channel", $channel, $nick);
  Irssi::signal_continue($server, $channel, $address);
}

sub notifier_topic {
  my ($server, $channel, $topic, $nick, $address) = @_;
  notifier_it($server, "Topic: $topic", "$nick has changed the topic to $topic on $channel", $channel, $nick);
  Irssi::signal_continue($server, $channel, $topic, $nick, $address);
}

sub notifier_privmsg {
  # $server = server record where the message came
  # $data = the raw data received from server, with PRIVMSGs it is:
  #         "target :text" where target is either your nick or #channel
  # $nick = the nick who sent the message
  # $host = host of the nick who sent the message
  my ($server, $data, $nick, $host) = @_;
  my ($target, $text) = split(/ :/, $data, 2);
  # only notify if we're permitting notification on privmsg
  if (Irssi::settings_get_str('notifier_on_privmsg') == 1) {
      notifier_it($server, $nick, $data, $target, $nick); 
  }
  Irssi::signal_continue($server, $data, $nick, $host);
}

# Hook me up
Irssi::settings_add_str('misc', 'notifier_path',
  "/Applications/terminal-notifier.app/Contents/MacOS/terminal-notifier"); # default install path
Irssi::settings_add_str('misc', 'notifier_on_regex', 0);      # false
Irssi::settings_add_str('misc', 'notifier_channel_regex', 0); # false
Irssi::settings_add_str('misc', 'notifier_on_nick', 1);       # true
Irssi::settings_add_str('misc', 'notifier_on_self', 0);       # false
Irssi::settings_add_str('misc', 'notifier_on_privmsg', 0);    # false
Irssi::settings_add_str('misc', 'notifier_play_sound', 0);    # false
Irssi::settings_add_str('misc', 'notifier_sound', 'default'); # default system
Irssi::signal_add('message public', 'notifier_message');
Irssi::signal_add('message private', 'notifier_message');
Irssi::signal_add('message own_public', 'notifier_my_message');
Irssi::signal_add('message own_private', 'notifier_my_message');
Irssi::signal_add('message join', 'notifier_join');
Irssi::signal_add('message part', 'notifier_part');
Irssi::signal_add('message quit', 'notifier_quit');
Irssi::signal_add('message invite', 'notifier_invite');
Irssi::signal_add('message topic', 'notifier_topic');
Irssi::signal_add('event privmsg', 'notifier_privmsg');
