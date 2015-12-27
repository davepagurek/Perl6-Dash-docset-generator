use v6;
use URI::Encode;
use HTML::Entity;

sub escape(Str $str) {
  $str.subst(/\"/, "\\" ~ '"', :g).subst(/\'/, "\\\'", :g);
}

shell 'sqlite3 Resources/docSet.dsidx "CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);"';
shell 'sqlite3 Resources/docSet.dsidx "CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);"';

my @stack = './Resources/Documents';
my $docs := gather while ( @stack.elems > 0 ) {
  my $current = @stack.pop;
  take $current if $current.IO.f && $current.IO.extension ne "ico";
  say "{$current.IO.basename}: {($current.IO.basename ~~ none('js', 'css', 'images')) ?? 'T' !! 'F' }" if $current.IO.d;
  @stack.push(|dir($current).map(*.IO.path)) if ($current.IO.d && $current.IO.basename ~~ none("js", "css", "images"));
}

for $docs.list -> $page {
  say "Running on $page";
  my $content = "";
  {
    $content = $page.IO.slurp;
    CATCH {
      default {
        say "Encoding error on $page";
        next;
      }
    }
  }
  my $title = "";
  my $docType = "";
  given $content {
    when /:r '<title>Perl 6 ' ~ '</title>' [$<category>=<-[\<]>+]/ {
      $docType = "Category";
      $title = ~$<category>;
    }
    when /:r '<title>' ~ '</title>' ['Documentation for '? [$<type>=\S+]' '[$<name>=[[\S\s\S|'!! ??'|'is '|<-[\s\<]>]+]]]/ {
      my $name = $<name>;
      my $type = $<type>;
      given ~$type.lc {
        when "class" { $docType = "Class"; }
        when "role" { $docType = "Interface"; }
        when "type" { $docType = "Type"; }
        when "enum" { $docType = "Enum"; }
        when "method" { $docType = "Method"; }
        when "routine" { $docType = "Function"; }
        when "sub" { $docType = "Function"; }
        when "declarator" { $docType = "Keyword"; }
        when "term" { $docType = "Term"; }
        when "listop" { $docType = "Operator"; }
        when /fix $$/ { $docType = "Operator"; }
        default {
          $docType = "Category";
          $title = "$type $name";
        }
      }
      $title = "$name" unless $title;
    }
    when /:r '<title>' ~ '</title>' [$<category>=<-[\<]>+]/ {
      if ~$<category> ~~ "Cool"|"Code"|"Duration"|/^^ "X::"/ {
        $docType = "Class";
        $title = ~$<category>;
      } else {
        $docType = "Guide";
        $title = ~$<category>;
      }
    }
  }
  $content.=subst(/"<title>".+?"<\/title>"/, "<title>{$title}</title>");

  while (shell("sqlite3 Resources/docSet.dsidx \"INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('{escape(decode-entities($title))}', '$docType', '{escape(uri_encode(~($page.IO.relative('Resources/Documents'))))}');\"").exitcode != 0) { sleep 1; }

  for ( $content ~~ m:g/:r '<li class="indexItem' <-[>]>+ '><a href="' <-["#]>* '#' $<id>=(<-["]>+) '">' ['<a' <-[>]>+ '>']? $<name>=(<-[<]>+) '</a>'/ ) -> $link {
    my $subType = "";
    my $subName = "";
    given $link<name> {
      when /'method ' (.+)/ {
        $subType = $0 ne "new" ?? "Method" !! "Constructor";
        $subName = $0;
      }
      when /'sub ' (.+)/ {
        $subType = "Function";
        $subName = $0;
      }
      when /'routine ' (.+)/ {
        $subType = "Function";
        $subName = $0;
      }
      when /'term ' (.+)/ {
        $subType = "Keyword";
        $subName = $0;
      }
      when /\w*?'fix ' (.+)/ {
        $subType = "Keyword";
        $subName = $0;
      }
      default {}
    }
    if $subName ne "" {
      $content.=subst(
        /"<h2 id=\"{~$link<id>}"/,
        "<a name=\"\/\/apple_ref\/cpp\/$subType\/$subName\" class=\"dashAnchor\"><\/a><h2 id=\"{~$link<id>}"
      );
    }
  }

  my $fh = $page.IO.open: :w;
  $fh.say($content);
  $fh.close;
}
