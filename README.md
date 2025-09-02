# SendMail

## Simple implementation of an Perl based email client

```perl 
#!/user/bin/env perl

use strict;
use warnings;

use Data::Dumper;

use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use Email::MIME;
use Try::Tiny;
use Dotenv;
use DateTime;

use lib 'lib';
use SendMail;
use DateTime;
use IPC::Run qw(run timeout);
use Cwd;
use Readonly;
use Log::Log4perl qw(:easy);

Readonly::Scalar my $lynis_file  => '/home/dragos/lynis-report.dat';
Readonly::Scalar my $clamav_file => '/home/dragos/clamav.log';

Log::Log4perl->easy_init(
    {
        level => $DEBUG,
        file  => ">>test.log"
    }
);
my $logger = get_logger();

if ( DateTime->now()->is_last_day_of_month() || 1 == 1 ) {
    $logger->debug('It last day of the month! Preparing reports:');
    my $env = Dotenv->load('/home/dragos/projects/scripts/.mail_env');

    $logger->debug('Run lynis report');
    run_report(
        [
            '/home/dragos/bin/lynis', 'audit',
            'system',                 '--profile',
            '/home/dragos/custom.prf'
        ],
        $lynis_file
    );

    $logger->debug('Run clamscan report');
    run_report(
        [
            'clamscan',            '-r',
            '-i',                  '--exclude-dir=^/proc',
            '--exclude-dir=^/sys', '--exclude-dir=^/dev',
            '/home/dragos',        "--log=$clamav_file",
            '-v'
        ],
        $clamav_file
    );

    $logger->debug('Done with reports');
    my $to = [

        'dragos.trif@cloudprimero.com'
    ];

    my $log_message = sprintf "Sendig mail to: %s with this files attached %s",
      Dumper $to, Dumper [ $lynis_file, $clamav_file ];
    $logger->debug( $log_message );
    
    my $mailer = SendMail->new(
        {
            sasl_username => $env->{cron_mail},
            sasl_password => $env->{cron_password},
            from          => $env->{cron_mail},
            to            => $to,
            email_body    => 'lynis report!',
            atachments    => [ $lynis_file, $clamav_file ],
            subject       => 'lynis report',
            name          => 'test'
        }
    );

    $mailer->send_email();
}

sub _execute_cmd {
    my ( $cmd, $file ) = @_;

    my $cmd_str = join ' ', @{$cmd};
    if ( $file eq '/home/dragos/clamav.log' ) {

        # accept error
        system( @{$cmd} );
    }
    else {
        system( @{$cmd} ) == 0 or die "can not excute $cmd_str: $?";
    }
    return;
}

sub run_report {
    my ( $cmd, $file ) = @_;

    if ( -f $file ) {
        unlink $file;
    }

    _execute_cmd( $cmd, $file );
    return;
}

```
