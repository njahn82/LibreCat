package App::Catalog::Controller::Permission;

use Catmandu::Sane;
use Catmandu;
use App::Catalog::Helper;
use Carp;
use Exporter qw/import/;

our @EXPORT_OK = qw/can_edit can_delete can_delete_file can_download/;
our %EXPORT_TAGS = (
  can => [qw/can_edit can_delete can_delete_file can_download/],
);

sub can_edit {
    my ($id, $login, $user_role) = @_;

    my $user = h->getAccount($login);
    my $hits;
    if ($user_role eq 'admin') {
        return 1;
    } elsif ($user_role eq 'reviewer') {
        my @deps = map {"department=$_->{id}"} @{$user->{reviewer}};
        $hits = h->quick_search(cql_query => "(" . join(@deps, ' OR ') . ")" . " AND id=$id");
    } elsif ($user_role eq 'dataManager') {
        my @deps = map {"department=$_->{id}"} @{$user->{dataManager}};
        $hits = h->quick_search(cql_query => "(" . join(@deps, ' OR ') . ")" . " AND id=$id");
    } elsif ($user_role eq 'user') {
        $hits = h->quick_search(cql_query => "(person=$user->{_id} OR creator=$user->{_id}) AND id=$id");
        if ($user->{delegate}) {
            my @delegate = map {"person=$_->{id}"} @{$user->{delegate}};
            $hits = h->quick_search(cql_query => "(" . join(@delegate, ' OR ') . ")" . "AND id=$id")
        }
    }

    $hits ? return 1 : return 0;
}

sub can_delete {
    my ($id, $role) = @_;

    ($role eq 'admin') ? return 1 : return 0;
}

sub can_delete_file {
    my ($id, $user) = @_;
}

sub can_download {
    my ($id, $file_id, $login, $role, $ip) = @_;

    my $pub = h->publication->get($id);
    my $access;
    my $file_name;
    map {
        if ($_->{id} == $file_id) {
            $access = $_->{access_level};
            $file_name = $_->{file_name};
        }
    } @{$pub->{file}};

    if ($access eq 'oa') {
        return (1, $file_name);
    } elsif ($access eq 'local' && $ip =~ /^h->{config}->{ip_range}/) {
        return (1, $file_name);
    } elsif ($access eq 'closed') {
        # closed documents can be downloaded by user if user
        # can edit the record
        return (can_edit($id, $login, $role), $file_name);
    } else {
        return (0, '');
    }

}

1;