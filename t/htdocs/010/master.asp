<%@ MasterPage %><!doctype html>
<%
  # Sticky forms:
  if( my $args = $Session->{__lastArgs} )
  {
    $Form->{$_} = $args->{$_} for keys %$args;
  }# end if()
  
  # Ability to display errors next to the fields they occurred within:
  $::errors = $Session->{validation_errors} ||= { };
  $::err = sub {
    my $err = $::errors->{ $_[0] } or return;
    %><div class="field-error"><%= $err %></div><%
  };
%>
<asp:ContentPlaceHolder id="init"></asp:ContentPlaceHolder>
<html>
<head>
  <meta charset="utf-8" />
  <title><asp:ContentPlaceHolder id="meta_title">default title</asp:ContentPlaceHolder></title>
  <meta name="keywords" content="<asp:ContentPlaceHolder id="meta_keywords">default keywords</asp:ContentPlaceHolder>" />
  <meta name="description" content="<asp:ContentPlaceHolder id="meta_description">default description</asp:ContentPlaceHolder>" />
</head>
<body>

<h1 id="headline"><asp:ContentPlaceHolder id="headline"><%= $__self->meta_title($__context) %></asp:ContentPlaceHolder></h1>

<asp:ContentPlaceHolder id="breadcrumbs_outer">
  <div id="breadcrumbs">
    Home &raquo; <asp:ContentPlaceHolder id="breadcrumbs">default breadcrumb</asp:ContentPlaceHolder>
  </div><!-- /#breadcrumbs -->
</asp:ContentPlaceHolder>

<div id="main_content">
  <asp:ContentPlaceHolder id="main_content">default content</asp:ContentPlaceHolder>
</div><!-- /#main_content -->

</body>
</html>
<%
  map {
    delete $Session->{$_}
  } qw(
    msg
    validation_errors
    __lastArgs
  );
%>

