<div>
    <a href="https://travis-ci.org/pjfl/p5-web-components-role-email"><img src="https://travis-ci.org/pjfl/p5-web-components-role-email.svg?branch=master" alt="Travis CI Badge"></a>
    <a href="https://roxsoft.co.uk/coverage/report/web-components-role-email/latest"><img src="https://roxsoft.co.uk/coverage/badge/web-components-role-email/latest" alt="Coverage Badge"></a>
    <a href="http://badge.fury.io/pl/Web-Components-Role-Email"><img src="https://badge.fury.io/pl/Web-Components-Role-Email.svg" alt="CPAN Badge"></a>
    <a href="http://cpants.cpanauthors.org/dist/Web-Components-Role-Email"><img src="http://cpants.cpanauthors.org/dist/Web-Components-Role-Email.png" alt="Kwalitee Badge"></a>
</div>

# Name

Web::Components::Role::Email - Role for sending emails

# Synopsis

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

    $recipient = $self->send_email( $post );

# Description

Supports multiple transports, attachments and multilingual templates for
message bodies

# Configuration and Environment

Defines no attributes

# Subroutines/Methods

## send\_email

    $result_message = $self->send_email( @args );

Sends emails. Returns the recipient address, throws on error. The
`@args` can be a list of keys and values or a hash reference. The attributes
defined are;

- `attachments`

    A hash reference whose key / value pairs are the attachment name and path
    name. Encoding and content type are derived from the file name
    extension

- `attributes`

    A hash reference that is applied to the email when it is created. Typical keys
    are; `content_type` and `charset`. See [Email::MIME](https://metacpan.org/pod/Email::MIME). This is merged onto
    the `email_attr` configuration hash reference if it exists

- `body`

    Text for the body of the email message

- `from`

    Email address of the sender

- `host`

    Which host should send the email. Defaults to `localhost`

- `mailer`

    Which mailer should be used to send the email. Defaults to `SMTP`

- `stash`

    Hash reference used by the template rendering to supply values for variable
    replacement

- `subject`

    Subject string. Defaults to _No Subject_

- `subprovider`

    If this object reference exists and an email is generated from a template then
    it is expected to provide a `loc` function which will be make callable from
    the template

- `functions`

    A list of functions provided by the ["subprovider"](#subprovider) object. This list of
    functions will be bound into the stash instead of the default `loc` function

- `template`

    If it exists then the template is rendered and used as the body contents.
    See the [layout](https://metacpan.org/pod/Web::Components::Role::TT#templates) attribute

- `to`

    Email address of the recipient

- `transport_attr`

    A hash reference passed to the transport constructor. This is merged in
    with the `transport_attr` configuration hash reference if it exists

## `try_to_send_email`

Just like ["send\_email"](#send_email) but logs at the error level instead of throwing

# Diagnostics

None

# Dependencies

- [Email::MIME](https://metacpan.org/pod/Email::MIME)
- [Email::Sender](https://metacpan.org/pod/Email::Sender)
- [Encode](https://metacpan.org/pod/Encode)
- [MIME::Types](https://metacpan.org/pod/MIME::Types)
- [Moo](https://metacpan.org/pod/Moo)
- [Unexpected](https://metacpan.org/pod/Unexpected)
- [Web::Components::Role::TT](https://metacpan.org/pod/Web::Components::Role::TT)

# Incompatibilities

There are no known incompatibilities in this module

# Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-Components-Role-Email.
Patches are welcome

# Acknowledgements

Larry Wall - For the Perl programming language

# Author

Peter Flanigan, `<pjfl@cpan.org>`

# License and Copyright

Copyright (c) 2016 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic)

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
