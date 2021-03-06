package LibreCat::App::Catalogue::Route::audit;

=head1 NAME

LibreCat::App::Catalogue::Route::audit - controller for handling audit messages

=cut

use Catmandu::Sane;
use Catmandu::Util;
use Dancer ':syntax';
use Dancer::Plugin::Auth::Tiny;
use Dancer::Serializer::Mutable qw(template_or_serialize);
use LibreCat::App::Helper;
use POSIX qw(strftime);
use URL::Encode qw(url_decode);

Dancer::Plugin::Auth::Tiny->extend(
   role => sub {
       my ($role, $coderef) = @_;
       return sub {
           if (session->{role} && $role eq session->{role}) {
               goto $coderef;
           }
           else {
               redirect '/access_denied';
           }
       }
   }
);

=head2 PREFIX /librecat/audit

All publication searches are handled within the prefix search.

=cut

prefix '/librecat' => sub {

=head2 GET /audit/:bag/:id

List all audit messages for an :id in the store :bag

=cut
        get '/audit/*/*' => needs role => 'super_admin' => sub {
            my ($bag,$id) = splat;

            my $it = h->backup_audit()
                      ->select( id => $id )
                      ->select( bag => $bag )
                      ->sorted(sub {
                          $_[0]->{time} cmp $_[1]->{time}
                        })
                      ->map(sub {
                          $_[0]->{date} = strftime("%Y-%m-%dT%H:%M:%S",localtime($_[0]->{time} // 0));
                          $_[0];
                      });

            my $array = $it->to_array;

            template_or_serialize 'backend/audit' ,  { audit => $array };
        };

        post '/audit/*/*' => needs role => 'super_admin' => sub {
            my ($bag,$id) = splat;

            my $user_id = session->{personNumber};
            my $message = params->{message};

            unless ($message) {
                content_type 'json';
                status '406';
                return to_json {error => "Parameter message is missing."};
            }

            my $job_id = h->queue->add_job('audit',{
                id      => $id ,
                bag     => $bag ,
                process => 'LibreCat::App::Catalogue::Route::audit' ,
                action  => "post /librecat/audit/$bag/$id" ,
                message => "$user_id says '$message'" ,
            });

            return to_json({ job => $job_id });
        };
};

1;
