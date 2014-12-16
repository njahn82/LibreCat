package App::Catalogue::Route::person;

=head1 NAME

    App::Catalogue::Route::person - handles person settings

=cut

use Catmandu::Sane;
use Catmandu::Util qw(:array);
use Dancer ':syntax';
use App::Helper;
use App::Catalogue::Controller::Admin qw/:person/;
use Dancer::Plugin::Auth::Tiny;

=head1 PREFIX /myPUB/person

    All person settings are handled within the prefix '/person'.

=cut
prefix '/myPUB/person' => sub {

=head2 GET /preference

    User edits the preferred citation style and sorting
    for his own publication list.

=cut
    get '/preference' => needs login => sub {
        my $person = h->getPerson( session('personNumber') );
        my $tmp = h->get_sort_style(params->{sort} || '', params->{style} || '');
        $person->{sort} = $tmp->{sort};
        $person->{style} = $tmp->{style};

        h->authority_user->add($person);

        redirect '/myPUB';
    };

=head2 POST /author_id

    User adds author identifiers to db (e.g. ORCID). These will
    be displayed on author's profile page.

=cut
    post '/author_id' => needs login => sub {

        my $id = params->{_id};
        my $person = h->authority_user->get( $id ) || {_id => $id};
        my @identifier = keys %{h->config->{lists}->{author_id}};

        map { $person->{$_} = params->{$_} ? params->{$_} : "" } @identifier;
        redirect '/myPUB' if keys %{$person} > 1;

        my $bag = h->authority_user->add($person);

        redirect '/myPUB';

    };

=head2 POST /edit_mode

    User can choose default edit mode for editing publications.
    "normal" -> edit form with tabs
    "expert" -> one long edit form

=cut
    post '/edit_mode' => sub {

        my $person     = h->authority_user->get( session('personNumber') );
        my $type = params->{edit_mode};
        if($type eq "normal" or $type eq "expert"){
        	$person->{edit_mode} = $type;
        	my $bag = h->authority_user->add($person);
        }

        redirect '/myPUB';

    };

=head1 POST /affiliation

    User edits his affiliation. Will be displayed if you opens
    new publication form.

=cut
    post '/affiliation' => needs login => sub {

        my $p = params;
        $p = h->nested_params($p);
        my $person = edit_person( session('personNumber') );
        $person->{department} = $p->{department};
        update_person($person);

        redirect '/myPUB';

    };

};

1;