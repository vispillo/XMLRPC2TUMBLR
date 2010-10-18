#!/usr/bin/perl -w

use strict;

package XML2TMBLR;

use LWP::UserAgent;
use XMLRPC::Transport::HTTP;
use XML::Simple;
use HTTP::Request::Common;

if ($ENV{'REQUEST_METHOD'} eq 'GET') {
  open(TMPL,'template.html') or die $!;
  print "Content-type: text/html\n\n";
  while (my $line = <TMPL>) {
    print $line;
  }
  close(TMPL);
  exit 0;
}
my $server = XMLRPC::Transport::HTTP::CGI->dispatch_to('metaWeblog')->handle;

sub newPost
{
   my ($class, $appkey, $blogid, $username, $password, $content, $struct);
   my %parts = ();

   $class = shift;

   ($blogid, $username, $password, $struct) = @_;

   my $ua = LWP::UserAgent->new;
   my $par_ref = [
      type => 'regular',
      generator => 'vispillo\'s XML-RPC2TUMBLR gateway',
      group => $blogid.'.tumblr.com',
      email => $username,
      password => $password,
      title => $struct->{'title'},
      body => $struct->{'description'}
   ];      
   my $resp = $ua->request(POST 'http://tumblr.com/api/write', $par_ref);
   return ($resp->decoded_content);
}

sub getUsersBlogs {
   my ($class, $appkey, $username, $password) = @_;

   my $ua = LWP::UserAgent->new;
   my $resp = $ua->request(POST 'http://tumblr.com/api/authenticate', [email => $username, password => $password]);
   return 0 if ($resp->decoded_content eq 'Invalid credentials.');
   my $ref = XMLin($resp->decoded_content);
   my @res = ();
   if (defined $ref->{'tumblelog'}->{'name'}) {
     return [ { url => $ref->{'tumblelog'}->{'url'},blogid => $ref->{'tumblelog'}->{'name'},blogName => $ref->{'tumblelog'}->{'title'} }];
   }
   else {
     my @logs = keys %{$ref->{'tumblelog'}};
     my $id = 0;   
     foreach (@logs) {
        push (@res,{
          url     => $ref->{'tumblelog'}->{$_}->{'url'},
          blogid  => $_,
          blogName => $ref->{'tumblelog'}->{$_}->{'title'}
        });
        $id++;
     }
     return \@res;
   }
}

package metaWeblog;
BEGIN { @metaWeblog::ISA = qw( XML2TMBLR ); }