package SendMail;

use Moo;

use Email::Stuffer;

use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use Email::MIME;
use Try::Tiny;
use Types::Standard qw(Str ArrayRef Object);
use IO::All;

has sasl_username => ( is => 'ro', required => 1, isa => Str );
has sasl_password => ( is => 'ro', required => 1, isa => Str );
has from          => ( is => 'ro', required => 1, isa => Str );
has to            => ( is => 'ro', required => 1, isa => ArrayRef );
has email_body    => ( is => 'ro', required => 1, isa => Str );
has atachments    => ( is => 'ro', required => 1, isa => ArrayRef );
has name          => ( is => 'ro', required => 1, isa => Str );
has subject       => ( is => 'ro', required => 1, isa => Str );

has message =>
  ( is => 'ro', lazy => 1, isa => Object, builder => '_build_message' );
has transport =>
  ( is => 'ro', lazy => 1, isa => Object, builder => '_build_transport' );

sub _build_message {
    my $self = shift;

    my $files     = $self->atachments();
    my @file_list = ();
    foreach my $file ( @{$files} ) {
        my @file_parts = split /\//, $file;
        my $mime       = Email::MIME->create(
            attributes => {
                filename     => $file_parts[-1],
                content_type => "text/plain",
                encoding     => "quoted-printable",
                name         => $file_parts[-1],
            },
            body => io($file)->binary->all,
        );
        push @file_list, $mime;
    }

    my @parts = (
        @file_list,
        Email::MIME->create(
            attributes => {
                content_type => "text/plain",
                disposition  => "attachment",
                encoding     => "quoted-printable",
                charset      => "US-ASCII",
            },
            body_str => "Automatic reports!",
        ),
    );
    my $email = Email::MIME->create(
        header_str => [
            From    => $self->from,
            To      => $self->to,
            Subject => $self->subject
        ],
        parts => [@parts],
    );

    return $email;
}

sub _build_transport {
    my $self = shift;

    my $transport = Email::Sender::Transport::SMTP->new(
        {
            host          => 'smtp.gmail.com',
            port          => 465,                      # or 587 with STARTTLS
            ssl           => 1,                        # or 0 for STARTTLS
            sasl_username => $self->sasl_username(),
            sasl_password => $self->sasl_password(),
        }
    );

    return $transport;
}

sub send_email {
    my $self = shift;

    try {
        sendmail( $self->message, { transport => $self->transport } );
    }
    catch {
        print "|$_|";
    };

    return 1;
}

1;