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

package notification::slack::mode::alert2;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::templating_notification;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
        "slack-url:s"           => { name => 'slack_url' },
        "macros:s"                => { name => 'macros' },
        "template:s"              => { name => 'template' },

        "credentials"           => { name => 'credentials' },
        "ntlm"                  => { name => 'ntlm' },
        "username:s"            => { name => 'username' },
        "password:s"            => { name => 'password' },
        "proxyurl:s"            => { name => 'proxyurl' },
        "proxypac:s"            => { name => 'proxypac' },
        "timeout:s"             => { name => 'timeout' },
        });

    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    $self->{template} = centreon::plugins::templating_notification->new(output => $self->{output});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{slack_url}) || $self->{option_results}->{slack_url} eq '') {
        $self->{output}->add_option_msg(short_msg => "You need to specify --slack-url option.");
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}}, hostname => 'dummy');
    $self->{template}->check_options(%{$self->{option_results}});
    $self->{template}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;

    my $content = $self->{template}->render();

    my $response = $self->{http}->request(
        full_url => $self->{option_results}->{slack_url},
        method => 'POST',
        post_param => ['payload=' . $content]
    );
    $self->{output}->output_add(short_msg => 'slack response: ' . $response);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send slack alerts.

Example:
centreon_plugins.pl --plugin=notification::slack::plugin --mode=alert2 --slack-url='https://hooks.slack.com/services/T0A754E2V/B0E0CEL4B/81V8kCJusL7kafDSdsd' --slack-channel='#testchannel' --macro '{"MYMACRO": "$MYMACRO$"}' --template /path/to/template.tpl

=over 8

=item B<--slack-url>

Specify slack url (Required).

=item B<--slack-channel>

Specify slack channel (Required).

=item B<--macro>

Set a JSON string for specify macros who will passed to template (Required).

Example :

'{"HOSTNAME":"$HOSTNAME$"}'

will pass the hostname to template.

=item B<--template>

Set the path to the template file (Required).

=back

=cut
