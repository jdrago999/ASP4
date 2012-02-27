<!doctype html>
<%
  use Data::Dumper;
  
  $Response->SetCookie(
    name  => "foo-cookie",
    value => "Hello, world!"
  ) unless $Request->Cookies("foo-cookie");
%>
<html>
<head>
  <meta charset="utf-8" />
  <title>ASP4 Test</title>
</head>
<body>

<h2>Include:</h2>

<h2>Session:</h2>
<pre><%= Dumper($Session) %></pre>

<h2>Form:</h2>
<pre><%= Dumper($Form) %></pre>

<h2>Stash:</h2>
<pre><%= Dumper($Stash) %></pre>

<h2>Server:</h2>
<pre>MapPath: <%= Dumper($Server->MapPath("/foo.asp")) %></pre>
<pre>URLEncode: <%= Dumper($Server->URLEncode("hello world")) %></pre>
<pre>URLDecode: <%= Dumper($Server->URLDecode("hello%20world")) %></pre>
<pre>HTMLEncode: <%= Dumper($Server->HTMLEncode("<a href='foo'>Hello</a>")) %></pre>
<pre>HTMLDecode: <%= Dumper($Server->HTMLDecode("&lt;a href='foo'&gt;Hello&lt;/a&gt;")) %></pre>


<h2>Request:</h2>
<pre>Cookies('session-id'): <%= Dumper($Request->Cookies("session-id")) %></pre>
<pre>Header: <%= Dumper($Request->Header("cookie")) %></pre>


<form action="/handlers/dev.post" method="post">
  <fieldset>
    <legend>POST Form</legend>
    <input type="text" placeholder="field1" name="field1" /><br/>
    <input type="text" placeholder="field2" name="field2" /><br/>
    <input type="text" placeholder="field3" name="field3" /><br/>
    <input type="text" placeholder="field3-again" name="field3" /><br/>
    <input type="submit" value="Submit" />
  </fieldset>
</form>
<hr />

<form action="/handlers/dev.post" method="post" enctype="multipart/form-data">
  <fieldset>
    <legend>UPLOAD Form</legend>
    <input type="text" placeholder="field1" name="field1" /><br/>
    <input type="text" placeholder="field2" name="field2" /><br/>
    <input type="text" placeholder="field3" name="field3" /><br/>
    <input type="text" placeholder="field3-again" name="field3" /><br/>
    <input type="file" name="filename" /><br/>
    <input type="submit" value="Submit" />
  </fieldset>
</form>


</body>
</html>

