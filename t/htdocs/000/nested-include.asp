<ul>
<%
  for( 1..10 )
  {
%>
  <li>This is included too: <%= $_ %></li>
<%
  }# end for()
%>
</ul>

