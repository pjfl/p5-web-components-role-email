package Web::Components::Role::Email;

use 5.010001;
use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.3.%d', q$Rev: 4 $ =~ /\d+/gmx );

use File::DataClass::Constants qw( EXCEPTION_CLASS TRUE );
use Encode                     qw( encode );
use File::DataClass::Functions qw( ensure_class_loaded );
use Ref::Util                  qw( is_hashref );
use Scalar::Util               qw( blessed weaken );
use Unexpected::Functions      qw( Unspecified throw );
use Email::MIME;
use File::DataClass::IO;
use MIME::Types;
use Try::Tiny;
use Moo::Role;

requires qw( config log );

with 'Web::Components::Role::TT';

# Public methods
sub send_email {
   my ($self, @args) = @_;

   throw Unspecified, ['email args'] unless defined $args[0];

   my $args = (is_hashref $args[0]) ? $args[0] : { @args };

   $args->{email} = $self->_create_email($args);

   my $res     = $self->_transport_email($args);
   my $id      = 'unknown';
   my $message = "OK id=${id}";

   if ($res->can('message')) {
      $message = $res->message if $res->message;
      ($id) = $message =~ m{ ^ OK \s+ id= (.+) $ }msx;
      chomp $id;
   }

   return wantarray ? ($id, $message) : $message;
}

sub try_to_send_email {
   my ($self, @args) = @_;

   my $wantarray = wantarray;
   my (@res, $res);

   try {
      if ($wantarray) { @res = $self->send_email(@args) }
      else { $res = $self->send_email(@args) }
   }
   catch { $self->log->error($res = $_) };

   return $wantarray ? @res : $res;
}

# Private methods
sub _create_email {
   my ($self, $args) = @_;

   return $args->{email} if $args->{email};

   my $conf     = $self->config;
   my $attr     = $conf->can('email_attr') ? $conf->email_attr : {};
   my $email    = { attributes => { %{$attr}, %{$args->{attributes} // {}} } };
   my $from     = $args->{from} or throw Unspecified, ['from'];
   my $to       = $args->{to  } or throw Unspecified, ['to'];
   my $encoding = $email->{attributes}->{charset};
   my $subject  = $args->{subject} // 'No subject';

   try   { $subject = encode('MIME-Header', $subject, TRUE) }
   catch { throw 'Cannot encode subject as MIME-Header: [_1]', [$_] };

   $email->{header} = [ From => $from, To => $to, Subject => $subject ];
   $email->{body  } = $self->_get_email_body($args);

   try   {
      $email->{body} = encode($encoding, $email->{body}, TRUE) if $encoding;
   }
   catch { throw 'Cannot encode body as [_1]: [_2]', [$encoding, $_] };

   _add_attachments($args, $email) if exists $args->{attachments};

   return Email::MIME->create(%{$email});
}

sub _get_email_body {
   my ($self, $args) = @_;

   my $obj = delete $args->{subprovider};

   return $args->{body} if exists $args->{body} and defined $args->{body};

   throw Unspecified, ['template'] unless $args->{template};

   my $stash = $args->{stash} //= {};

   $stash->{page} //= {};
   $stash->{page}->{layout} //= $args->{template};
   $self->_stash_functions($obj, $stash, $args->{functions});

   return $self->render_template($stash);
}

sub _stash_functions {
   my ($self, $obj, $stash, $funcs) = @_;

   return unless defined $obj;

   $funcs //= [];

   push @{$funcs}, 'loc' unless $funcs->[0];

   for my $f (@{$funcs}) { $stash->{$f} = _make_f($obj, $f) }

   return;
}

sub _transport_email {
   my ($self, $args) = @_;

   throw Unspecified, ['email'] unless $args->{email};

   my $attr = {};
   my $conf = $self->config;

   $attr = { %{$conf->transport_attr} } if $conf->can('transport_attr');

   $attr = { %{$attr}, %{$args->{transport_attr}} }
      if exists $args->{transport_attr};

   $attr->{host} = $args->{host} if exists $args->{host};

   $attr->{host} //= 'localhost';

   my $class = delete $attr->{class};

   $class = $args->{mailer} // $class // 'SMTP';

   if ('+' eq substr $class, 0, 1) { $class = substr $class, 1 }
   else { $class = "Email::Sender::Transport::${class}" }

   ensure_class_loaded $class;

   my $mailer    = $class->new($attr);
   my $send_args = { from => $args->{from}, to => $args->{to} };
   my $response;

   try   { $response = $mailer->send($args->{email}, $send_args) }
   catch { throw $_ };

   throw $response->message if $response->can('failure');

   throw 'Send failed: [_1]', [$response]
      unless blessed $response and $response->isa('Email::Sender::Success');

   return $response;
}

# Private functions
sub _add_attachments {
   my ($args, $email) = @_;

   my $types = MIME::Types->new( only_complete => TRUE );
   my $part  = Email::MIME->create(
      attributes => $email->{attributes}, body => delete $email->{body}
   );

   $email->{parts} = [$part];

   for my $name (sort keys %{$args->{attachments}}) {
      my $path = io($args->{attachments}->{$name})->binary->lock;
      my $mime = $types->mimeTypeOf(my $file = $path->basename);
      my $attr = {
         content_type => $mime->type,
         encoding     => $mime->encoding,
         filename     => $file,
         name         => $name,
      };

      $part = Email::MIME->create(attributes => $attr, body => $path->all);
      push @{$email->{parts}}, $part;
   }

   return;
}

sub _make_f {
   my ($obj, $f) = @_; weaken $obj; return sub { $obj->$f(@_) };
}

1;

__END__

=pod

=encoding utf-8

=begin html

<a href="https://travis-ci.org/pjfl/p5-web-components-role-email"><img src="https://travis-ci.org/pjfl/p5-web-components-role-email.svg?branch=master" alt="Travis CI Badge"></a>
<a href="https://roxsoft.co.uk/coverage/report/web-components-role-email/latest"><img src="https://roxsoft.co.uk/coverage/badge/web-components-role-email/latest" alt="Coverage Badge"></a>
<a href="http://badge.fury.io/pl/Web-Components-Role-Email"><img src="https://badge.fury.io/pl/Web-Components-Role-Email.svg" alt="CPAN Badge"></a>
<a href="http://cpants.cpanauthors.org/dist/Web-Components-Role-Email"><img src="http://cpants.cpanauthors.org/dist/Web-Components-Role-Email.png" alt="Kwalitee Badge"></a>

=end html

=head1 Name

Web::Components::Role::Email - Role for sending emails

=head1 Synopsis

   use Moo;

   with 'Web::Components::Role::Email';

   my $post = { attributes      => {
                   charset      => 'UTF-8',
                   content_type => 'text/html' },
                body            => 'Message body text',
                from            => 'Senders email address',
                host            => 'localhost',
                mailer          => 'SMTP',
                subject         => 'Email subject string',
                to              => 'Recipients email address' };

   $message = $self->send_email( $post );

   # or

   ($id, $message) = $self->send_email( $post );

=head1 Description

Supports multiple transports, attachments and multilingual templates for
message bodies

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

=head2 send_email

   $response_message = $self->send_email( @args );
   ($id, $response_message) = $self->send_email( @args );

Sends emails. Returns the response message in a scalar context, throws on
error. In a list context returns the id of the sent message and the response
message. The id is parsed from the response message using a simple regular
expression . The C<@args> can be a list of keys and values or a hash
reference. The attributes defined are;

=over 3

=item C<attachments>

A hash reference whose key / value pairs are the attachment name and path
name. Encoding and content type are derived from the file name
extension

=item C<attributes>

A hash reference that is applied to the email when it is created. Typical keys
are; C<content_type> and C<charset>. See L<Email::MIME>. This is merged onto
the C<email_attr> configuration hash reference if it exists

=item C<body>

Text for the body of the email message

=item C<from>

Email address of the sender

=item C<host>

Which host should send the email. Defaults to C<localhost>

=item C<mailer>

Which mailer should be used to send the email. Defaults to C<SMTP>

=item C<stash>

Hash reference used by the template rendering to supply values for variable
replacement

=item C<subject>

Subject string. Defaults to I<No Subject>

=item C<subprovider>

If this object reference exists and an email is generated from a template then
it is expected to provide a C<loc> function which will be make callable from
the template

=item C<functions>

A list of functions provided by the L</subprovider> object. This list of
functions will be bound into the stash instead of the default C<loc> function

=item C<template>

If it exists then the template is rendered and used as the body contents.
See the L<layout|Web::Components::Role::TT/templates> attribute

=item C<to>

Email address of the recipient

=item C<transport_attr>

A hash reference passed to the transport constructor. This is merged in
with the C<transport_attr> configuration hash reference if it exists

=back

=head2 C<try_to_send_email>

Just like L</send_email> but logs at the error level instead of throwing

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Email::MIME>

=item L<Email::Sender>

=item L<Encode>

=item L<MIME::Types>

=item L<Moo>

=item L<Unexpected>

=item L<Web::Components::Role::TT>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-Components-Role-Email.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
