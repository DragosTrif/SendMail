# SendMail

## Simple implementation of an Perl based email client

```perl 
use strict;
use warnings;

use SendMail;


my $mailer = SendMail->new(
  {
      sasl_username => $env->{cron_mail},
      sasl_password => $env->{cron_password},
      from          => $env->{cron_mail},
      to            =>
        [ 'email_1', 'email_2' ],
      email_body => 'lynis report!',
      atachments =>
        [ 'file_1', 'file_2' ],
      subject => 'lynis report test',
      name    => 'test'
  }
);

$mailer->send_email();
```
