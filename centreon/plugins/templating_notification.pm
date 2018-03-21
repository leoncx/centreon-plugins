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

package centreon::plugins::templating_notification;

use strict;
use warnings;
use Template;
use JSON;
use File::Basename;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    $self->{output} = $options{output};
    $self->{options} = {
        macros => undef,
        template => undef,
    };
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{options} = { %{$self->{options}} };
    foreach (keys %options) {
        $self->{options}->{$_} = $options{$_} if (defined($options{$_}));
    }
}

sub check_options {
    my ($self, %options) = @_;

    if (!defined($options{template})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify --template option.");
        $self->{output}->option_exit();
    }

    if (!defined($options{macros})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify --macros option.");
        $self->{output}->option_exit();
    }

    # Validate : the template must be readable
    if (! -r $options{template}) {
        $self->{output}->add_option_msg(short_msg => "The template name must be exists and be readable.");
        $self->{output}->option_exit();
    }
}

# Convert custom macros
# * Convert the COLORSERVICESTATE and COLORHOSTTATE / SERVICESTATEID or HOSTSTATEID
sub convert_macros {
    my ($self) = @_;

    # Convert macros color
    my $vars = decode_json($self->{options}->{macros});
    my $colorString;
    my $target;
    if ($self->{options}->{macros} =~ /\$COLORSERVICESTATE\$/) {
        $target = "COLORSERVICESTATE";
        if ($vars->{SERVICESTATEID} eq 2) {
            $colorString = $vars->{COLORCRITICAL};
        } elsif ($vars->{SERVICESTATEID} eq 1) {
            $colorString = $vars->{COLORWARNING};
        } elsif ($vars->{SERVICESTATEID} eq 0) {
            $colorString = $vars->{COLOROK};
        } else {
            $colorString = $vars->{COLORUNKNOWN};
        }
    }
    if ($self->{options}->{macros} =~ /\$COLORHOSTTATE\$/) {
        $target = "COLORHOSTTATE";
        if ($vars->{HOSTSTATEID} eq 1) {
            $colorString = $vars->{COLORCRITICAL};
        } elsif ($vars->{HOSTSTATEID} eq 0) {
            $colorString = $vars->{COLOROK};
        } else {
            $colorString = $vars->{COLORUNKNOWN};
        }
    }

    if ($target) {
        $self->{options}->{macros} =~ s/\$$target\$/$colorString/g
    }
}

sub render {
    my ($self) = @_;
    # Convert custom macros
    $self->convert_macros();
    my $vars = decode_json($self->{options}->{macros});
    my $tplDir = dirname($self->{options}->{template});
    my $tpl = Template->new({
        INCLUDE_PATH => $tplDir
    });

    my $output = "";
    # Process templating
    $tpl->process(basename($self->{options}->{template}), $vars, \$output);

    return $output;
}

1;
