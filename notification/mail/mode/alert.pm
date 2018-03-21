#
# Copyright 2018 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package notification::mail::mode::alert;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::templating_notification;
use Email::Sender::Simple qw(sendmail);
use Email::MIME;
use MIME::Words qw(encode_mimewords);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
        "email:s"                 => { name => 'email' },
        "subject:s"               => { name => 'subject' },
        "macros:s"                => { name => 'macros' },
        "template:s"              => { name => 'template' },
        "from:s"                  => { name => 'from' }
        });

    $self->{template} = centreon::plugins::templating_notification->new(output => $self->{output});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{email}) || $self->{option_results}->{email} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --email option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{subject}) || $self->{option_results}->{subject} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --subject option.");
        $self->{output}->option_exit();
    }

    $self->{template}->check_options(%{$self->{option_results}});
    $self->{template}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;

    my $content = $self->{template}->render();

    my $email = Email::MIME->create(
      header_str => [
        From    => $self->{option_results}->{from},
        To      => $self->{option_results}->{email},
        Subject => encode_mimewords(
          $self->{option_results}->{subject},
          Charset => 'utf-8', Encoding => 'B'),
          'Content-Type' => 'text/html',
      ],
      attributes => {
        encoding => 'base64',
        charset  => 'UTF-8',
      },
      body_str => $content
    );
    sendmail($email);

    $self->{output}->output_add(short_msg => 'OK');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send mail alerts.

Example:
centreon_plugins.pl --plugin=notification::mail::plugin --mode=alert --email='user@domai.tld' --subject='[$SERVICESTATE$] - $SERVICEDESCRIPTION$' --from='monitoring@domain.tld' --macro '{"MYMACRO": "$MYMACRO$"}' --template /path/to/template.tpl

=over 8

=item B<--email>

The email to (Required).

=item B<--subject>

The email subject (Required).

=item B<--from>

The email from (Required).

=item B<--macro>

Set a JSON string for specify macros who will passed to template (Required).

Example :

'{"HOSTNAME":"$HOSTNAME$"}'

will pass the hostname to template.

=item B<--template>

Set the path to the template file (Required).

=back

=cut
